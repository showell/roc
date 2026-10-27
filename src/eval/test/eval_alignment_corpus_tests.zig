//! Alignment corpus: 16-byte values (`Dec`, `I128`, `U128`) placed where their
//! alignment matters. Optimized LLVM is the backend that turns a misaligned
//! 16-byte value into a crash, through aligned vector loads, and `run-test-eval`
//! leaves LLVM out; `run-test-eval-llvm-alignment` runs this corpus with LLVM on
//! every pull request. Every case name starts with "alignment corpus:", which is
//! the step's filter.

const TestCase = @import("parallel_runner.zig").TestCase;

/// Cheap cases that each put a 16-byte value somewhere alignment matters.
pub const tests = [_]TestCase{
    .{
        .name = "alignment corpus: Dec and I128 lists built at runtime",
        .source =
        \\{
        \\    var $decs = []
        \\    var $wides = []
        \\    for n in [1.5.Dec, 2.5, 3.5] {
        \\        $decs = List.append($decs, n)
        \\    }
        \\    for n in [11.I128, 22, 33] {
        \\        $wides = List.append($wides, n * 3)
        \\    }
        \\    List.fold($decs, 0.5, |acc, n| acc + n) == 8.0
        \\        and List.fold($wides, 0, |acc, n| acc + n) == 198
        \\}
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: unannotated top-level numeral list defaults to Dec",
        .source_kind = .module,
        .source =
        \\big = [1.5, 2.5, 3.5]
        \\
        \\main = {
        \\    var $d = 0.5
        \\    for n in big {
        \\        $d = $d + n
        \\    }
        \\    $d == 8.0
        \\}
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: annotated top-level Dec, I128 and U128 lists",
        .source_kind = .module,
        .source =
        \\decs : List(Dec)
        \\decs = [1.5, 2.5, 3.5]
        \\wides = [11.I128, 22.I128, 33.I128]
        \\huge = [18446744073709551617.U128, 18446744073709551618.U128]
        \\
        \\main =
        \\    List.fold(decs, 0.5, |acc, n| acc + n) == 8.0
        \\        and List.fold(wides, 0, |acc, n| acc + n) == 66
        \\        and List.fold(huge, 0, |acc, n| acc + n) == 36893488147419103235
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: top-level list of records holding a U8 and a Dec",
        .source_kind = .module,
        .source =
        \\rows = [{ tag: 1.U8, amount: 1.25.Dec }, { tag: 2.U8, amount: 2.5.Dec }, { tag: 3.U8, amount: 3.75.Dec }]
        \\
        \\main = List.fold(rows, 0.0, |acc, row| acc + row.amount * U8.to_dec(row.tag)) == 17.5
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: Dec and I128 in a Box",
        .source =
        \\{
        \\    boxed_dec = Box.box(1.25.Dec)
        \\    boxed_wide = Box.box(-18446744073709551617.I128)
        \\    Box.unbox(boxed_dec) * 2 == 2.5
        \\        and Box.unbox(boxed_wide) + 1 == -18446744073709551616
        \\}
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: Dec in a record next to a U8",
        .source =
        \\{
        \\    make = |tag, amount| { tag, amount }
        \\    rec = make(7.U8, 3.75.Dec)
        \\    wide = { flag: 1.U8, value: 18446744073709551617.U128 }
        \\    rec.tag == 7 and rec.amount + 1 == 4.75 and wide.value - 1 == 18446744073709551616
        \\}
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: Dec and I128 as tag union payloads",
        .source =
        \\{
        \\    items = [Amount(1.5.Dec), Nothing, Count(-18446744073709551617.I128), Amount(0.25)]
        \\    decs = List.fold(items, 0.0, |acc, item|
        \\        match item {
        \\            Amount(d) => acc + d
        \\            _ => acc
        \\        })
        \\    wides = List.fold(items, 0.I128, |acc, item|
        \\        match item {
        \\            Count(n) => acc + n
        \\            _ => acc
        \\        })
        \\    decs == 1.75 and wides == -18446744073709551617
        \\}
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: Dec and I128 captured by a closure next to a U8",
        .source =
        \\{
        \\    small = 3.U8
        \\    rate = 2.5.Dec
        \\    offset = 18446744073709551617.I128
        \\    scale = |x| x * rate + U8.to_dec(small)
        \\    shift = |n| n + offset + U8.to_i128(small)
        \\    List.map([1.0.Dec, 2.0], scale) == [5.5, 8.0]
        \\        and shift(-18446744073709551620) == 0
        \\}
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: runtime list of records holding a Dec",
        .source =
        \\{
        \\    var $rows = []
        \\    for i in [1.U8, 2, 3, 4] {
        \\        $rows = List.append($rows, { tag: i, amount: U8.to_dec(i) * 0.5 })
        \\    }
        \\    List.fold($rows, 0.0, |acc, row| acc + row.amount) == 5.0
        \\}
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: Dec seamless slices from sublist and drop_first, summed",
        .source =
        \\{
        \\    var $decs = []
        \\    for n in [1.5.Dec, 2.5, 3.5, 4.5, 5.5] {
        \\        $decs = List.append($decs, n)
        \\    }
        \\    middle = List.sublist($decs, { start: 1, len: 3 })
        \\    tail = List.drop_first($decs, 1)
        \\    List.fold(middle, 0.0, |acc, n| acc + n) == 10.5
        \\        and List.fold(tail, 0.0, |acc, n| acc + n) == 16.0
        \\}
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: slices of a top-level I128 constant, summed",
        .source_kind = .module,
        .source =
        \\wides = [11.I128, 22.I128, 33.I128, 44.I128]
        \\big = [1.5, 2.5, 3.5]
        \\
        \\main =
        \\    List.fold(List.drop_first(wides, 1), 0, |acc, n| acc + n) == 99
        \\        and List.fold(List.sublist(wides, { start: 1, len: 2 }), 0, |acc, n| acc + n) == 55
        \\        and List.fold(List.drop_first(big, 2), 0.0, |acc, n| acc + n) == 3.5
        ,
        .expected = .{ .inspect_str = "True" },
    },
    .{
        .name = "alignment corpus: top-level record constant with a U8 beside a Dec",
        .source_kind = .module,
        .source =
        \\config = { tag: 9.U8, rate: 1.75.Dec, limit: 18446744073709551617.U128 }
        \\
        \\main = config.tag == 9 and config.rate * 2 == 3.5 and config.limit - 1 == 18446744073709551616
        ,
        .expected = .{ .inspect_str = "True" },
    },
};
