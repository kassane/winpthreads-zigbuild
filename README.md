The Winpthreads Library for Zig
-----------------------

[![build](https://github.com/kassane/winpthreads-zigbuild/actions/workflows/build.yml/badge.svg)](https://github.com/kassane/winpthreads-zigbuild/actions/workflows/build.yml)

Based on: https://github.com/ziglang/zig/issues/10989

Zig toolchain/MinGW don't includes `winpthreads`.

This library provides POSIX threading APIs for mingw-w64.

For maximum compatibility, winpthreads headers expose APIs without the
`dllimport` attribute by default. If your program is linked against the
DLL, you may define the `WINPTHREADS_USE_DLLIMPORT` macro to add the
`dllimport` attribute to all APIs, which makes function calls to them a
bit more efficient.
