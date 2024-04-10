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


How to use
---------

**Requires:** zig v0.12.0 or higher


* Make a project:

```bash
mkdir your-project-folder
cd your-project-folder 
# generate both (exe and lib template w/ build.zig & build.zig.zon)
zig init
# get latest version (commit-tag or branch)
zig fetch git+https://github.com/kassane/winpthreads-zigbuild#main
```

* Add on current project:

```bash
# (w/ build.zig & build.zig.zon)
cd your-project-folder
# get latest version
zig fetch git+https://github.com/kassane/winpthreads-zigbuild#main # or #commit-tag
```

**Warn:** `main` branch changes commit hashes.
