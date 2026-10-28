//! Eval coverage for the ASCII methods on U8, over every byte.
//!
//! Each predicate case applies the Roc method to every byte from 0 to 255 and
//! compares the 256 answers with Zig's `std.ascii`, an implementation written
//! apart from Builtin.roc's. The case-mapping cases do the same with the 256
//! mapped bytes. Two more cases hold the U8 methods to the Str builtins that
//! already apply the same rules: `Str.trim` for whitespace, and
//! `Str.with_ascii_lowercased`/`Str.with_ascii_uppercased` for case.

const std = @import("std");
const ascii = std.ascii;
const TestCase = @import("parallel_runner.zig").TestCase;

/// The Roc block that applies `U8.<method>` to every byte, giving a 256-byte
/// `Str` with `1` where it holds and `.` where it does not.
fn rowSource(comptime method: []const u8) []const u8 {
    return "{\n" ++
        "var $row = List.with_capacity(256)\n" ++
        "for byte in U8.to(0, 255) {\n" ++
        "    $row = $row.append(if byte." ++ method ++ "() '1' else '.')\n" ++
        "}\n" ++
        "match Str.from_utf8($row) {\n" ++
        "    Ok(text) => text\n" ++
        "    Err(_) => \"not UTF-8\"\n" ++
        "}\n" ++
        "}";
}

/// `Str.inspect` of the row `rowSource` builds, with `holds` deciding each byte.
fn rowInspect(comptime holds: fn (u8) bool) []const u8 {
    @setEvalBranchQuota(10_000);

    var row: [256]u8 = undefined;
    for (&row, 0..) |*slot, index| {
        slot.* = if (holds(@intCast(index))) '1' else '.';
    }
    const final = row;
    return std.fmt.comptimePrint("\"{s}\"", .{&final});
}

/// The Roc block that maps every byte from 0 to 255 through `U8.<method>`.
fn mapSource(comptime method: []const u8) []const u8 {
    return "{\n" ++
        "var $mapped = List.with_capacity(256)\n" ++
        "for byte in U8.to(0, 255) {\n" ++
        "    $mapped = $mapped.append(byte." ++ method ++ "())\n" ++
        "}\n" ++
        "$mapped\n" ++
        "}";
}

/// `Str.inspect` of the 256 bytes `mapSource` builds, with `map` giving each.
fn mapInspect(comptime map: fn (u8) u8) []const u8 {
    @setEvalBranchQuota(100_000);

    comptime var text: []const u8 = "[";
    inline for (0..256) |index| {
        if (index != 0) {
            text = text ++ ", ";
        }
        text = text ++ std.fmt.comptimePrint("{d}", .{map(index)});
    }
    return text ++ "]";
}

/// `Str.inspect` of a row of 128 `=`, one for each ASCII byte that agrees.
fn allAgreeInspect() []const u8 {
    const row: [128]u8 = @splat('=');
    return std.fmt.comptimePrint("\"{s}\"", .{&row});
}

/// ASCII method eval cases consumed by the parallel eval runner.
pub const tests = [_]TestCase{
    .{
        .name = "U8 ascii: is_ascii_digit over every byte matches std.ascii.isDigit",
        .source = rowSource("is_ascii_digit"),
        .expected = .{ .inspect_str = rowInspect(ascii.isDigit) },
    },
    .{
        .name = "U8 ascii: is_ascii_hex_digit over every byte matches std.ascii.isHex",
        .source = rowSource("is_ascii_hex_digit"),
        .expected = .{ .inspect_str = rowInspect(ascii.isHex) },
    },
    .{
        .name = "U8 ascii: is_ascii_alphabetic over every byte matches std.ascii.isAlphabetic",
        .source = rowSource("is_ascii_alphabetic"),
        .expected = .{ .inspect_str = rowInspect(ascii.isAlphabetic) },
    },
    .{
        .name = "U8 ascii: is_ascii_alphanumeric over every byte matches std.ascii.isAlphanumeric",
        .source = rowSource("is_ascii_alphanumeric"),
        .expected = .{ .inspect_str = rowInspect(ascii.isAlphanumeric) },
    },
    .{
        .name = "U8 ascii: is_ascii_whitespace over every byte matches std.ascii.isWhitespace",
        .source = rowSource("is_ascii_whitespace"),
        .expected = .{ .inspect_str = rowInspect(ascii.isWhitespace) },
    },
    .{
        .name = "U8 ascii: is_ascii_punctuation over every byte matches std.ascii.isPunctuation",
        .source = rowSource("is_ascii_punctuation"),
        .expected = .{ .inspect_str = rowInspect(ascii.isPunctuation) },
    },
    .{
        .name = "U8 ascii: is_ascii_control over every byte matches std.ascii.isControl",
        .source = rowSource("is_ascii_control"),
        .expected = .{ .inspect_str = rowInspect(ascii.isControl) },
    },
    .{
        .name = "U8 ascii: with_ascii_lowercased over every byte matches std.ascii.toLower",
        .source = mapSource("with_ascii_lowercased"),
        .expected = .{ .inspect_str = mapInspect(ascii.toLower) },
    },
    .{
        .name = "U8 ascii: with_ascii_uppercased over every byte matches std.ascii.toUpper",
        .source = mapSource("with_ascii_uppercased"),
        .expected = .{ .inspect_str = mapInspect(ascii.toUpper) },
    },
    .{
        .name = "U8 ascii: is_ascii_whitespace holds for exactly the ASCII bytes Str.trim removes",
        .source =
        \\{
        \\var $row = List.with_capacity(128)
        \\for byte in U8.to(0, 127) {
        \\    trimmed = match Str.from_utf8([byte]) {
        \\        Ok(text) => Str.trim(text).is_empty()
        \\        Err(_) => False
        \\    }
        \\    $row = $row.append(if trimmed == byte.is_ascii_whitespace() '=' else 'x')
        \\}
        \\match Str.from_utf8($row) {
        \\    Ok(text) => text
        \\    Err(_) => "not UTF-8"
        \\}
        \\}
        ,
        .expected = .{ .inspect_str = allAgreeInspect() },
    },
    .{
        .name = "U8 ascii: the case methods agree with the Str ones on every ASCII byte",
        .source =
        \\{
        \\var $row = List.with_capacity(128)
        \\for byte in U8.to(0, 127) {
        \\    agrees = match Str.from_utf8([byte]) {
        \\        Ok(text) => (Str.with_ascii_lowercased(text).to_utf8() == [byte.with_ascii_lowercased()]) and (Str.with_ascii_uppercased(text).to_utf8() == [byte.with_ascii_uppercased()])
        \\        Err(_) => False
        \\    }
        \\    $row = $row.append(if agrees '=' else 'x')
        \\}
        \\match Str.from_utf8($row) {
        \\    Ok(text) => text
        \\    Err(_) => "not UTF-8"
        \\}
        \\}
        ,
        .expected = .{ .inspect_str = allAgreeInspect() },
    },
};
