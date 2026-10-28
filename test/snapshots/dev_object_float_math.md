# META
~~~ini
description=F32/F64 arithmetic, comparisons, and F64 to I64 conversion in host-called functions
type=dev_object
~~~
# SOURCE
## app.roc
~~~roc
app [main] { pf: platform "./platform.roc" }

main : F64, F32, I64 -> I64
main = |x, y, n| {
    scaled = x * 2.5 - I64.to_f64(n) / 3.0
    narrowed = F32.to_f64(y * 1.5 + 0.25)
    total = if scaled > narrowed { scaled - narrowed } else { narrowed + scaled }
    F64.to_i64_wrap(total)
}
~~~
## platform.roc
~~~roc
platform ""
    requires {} { main : F64, F32, I64 -> I64 }
    exposes []
    packages {}
    provides { "roc_main": main_for_host }
    targets: {
        inputs_dir: "targets/",
        x64glibc: { inputs: [app] },
    }

main_for_host : F64, F32, I64 -> I64
main_for_host = main
~~~
# MONO
~~~roc
# platform
main_for_host = <required>

# app
main = |x, y, n| {
	scaled = x * 2.5 - to_f64(n) / 3
	narrowed = to_f64(y * 1.5 + 0.25)
	total = if (scaled > narrowed) {
		scaled - narrowed
	} else {
		narrowed + scaled
	}
	to_i64_wrap(total)
}

~~~
# DEV OUTPUT
~~~ini
x64mac=7037e064f6dfc0ed2c857aea3d02a7b324c15cce13c2bc27cd64ed15ec550c02
x64win=1370f2891a2ec77c06a4b7d5cb068470434e6c21e5e5f4058ca2e4d62d80de99
x64mingw=1370f2891a2ec77c06a4b7d5cb068470434e6c21e5e5f4058ca2e4d62d80de99
x64freebsd=a39b380f89508c1166ecf4a4e50e842f2a5dbdc3adfe7257cb7f62b328523602
x64openbsd=ffd3871ecbc33b3225fc91e527f3a88f856c5900610adac4f0063526afc77936
x64netbsd=d0900c9d7d5380e566002f040bc2c8865143670134c4b0819a00b4aac52dfc40
x64musl=d0900c9d7d5380e566002f040bc2c8865143670134c4b0819a00b4aac52dfc40
x64glibc=d0900c9d7d5380e566002f040bc2c8865143670134c4b0819a00b4aac52dfc40
x64linux=d0900c9d7d5380e566002f040bc2c8865143670134c4b0819a00b4aac52dfc40
x64elf=d0900c9d7d5380e566002f040bc2c8865143670134c4b0819a00b4aac52dfc40
x64v1mac=7037e064f6dfc0ed2c857aea3d02a7b324c15cce13c2bc27cd64ed15ec550c02
x64v1win=1370f2891a2ec77c06a4b7d5cb068470434e6c21e5e5f4058ca2e4d62d80de99
x64v1mingw=1370f2891a2ec77c06a4b7d5cb068470434e6c21e5e5f4058ca2e4d62d80de99
x64v1freebsd=a39b380f89508c1166ecf4a4e50e842f2a5dbdc3adfe7257cb7f62b328523602
x64v1openbsd=ffd3871ecbc33b3225fc91e527f3a88f856c5900610adac4f0063526afc77936
x64v1netbsd=d0900c9d7d5380e566002f040bc2c8865143670134c4b0819a00b4aac52dfc40
x64v1musl=d0900c9d7d5380e566002f040bc2c8865143670134c4b0819a00b4aac52dfc40
x64v1glibc=d0900c9d7d5380e566002f040bc2c8865143670134c4b0819a00b4aac52dfc40
x64v1linux=d0900c9d7d5380e566002f040bc2c8865143670134c4b0819a00b4aac52dfc40
x64v1elf=d0900c9d7d5380e566002f040bc2c8865143670134c4b0819a00b4aac52dfc40
arm64mac=eb844cfdd6e27e513f0bfe5b68024a87e1a2227359eb4154eb979842eba5c7f0
arm64win=7a5d89503b4c1c7bb8498e397a2955683d148e43685ab87b61ffe1a10f643eb4
arm64mingw=7a5d89503b4c1c7bb8498e397a2955683d148e43685ab87b61ffe1a10f643eb4
arm64linux=2c554961c3db92883463ec596354bba08fb5a202fc88a0bce7ff28fbdbafe32d
arm64musl=2c554961c3db92883463ec596354bba08fb5a202fc88a0bce7ff28fbdbafe32d
arm64glibc=2c554961c3db92883463ec596354bba08fb5a202fc88a0bce7ff28fbdbafe32d
arm64v1win=7a5d89503b4c1c7bb8498e397a2955683d148e43685ab87b61ffe1a10f643eb4
arm64v1mingw=7a5d89503b4c1c7bb8498e397a2955683d148e43685ab87b61ffe1a10f643eb4
arm64v1linux=2c554961c3db92883463ec596354bba08fb5a202fc88a0bce7ff28fbdbafe32d
arm64v1musl=2c554961c3db92883463ec596354bba08fb5a202fc88a0bce7ff28fbdbafe32d
arm64v1glibc=2c554961c3db92883463ec596354bba08fb5a202fc88a0bce7ff28fbdbafe32d
arm32linux=NOT_IMPLEMENTED
arm32musl=NOT_IMPLEMENTED
wasm32=NOT_IMPLEMENTED
wasm32v1=NOT_IMPLEMENTED
~~~
