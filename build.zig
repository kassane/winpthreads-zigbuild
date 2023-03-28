const std = @import("std");

pub fn build(b: *std.Build) void {
    if (comptime !checkVersion())
        @compileError("Please! Update zig toolchain >= 0.11!");
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "winpthreads",
        .optimize = optimize,
        .target = target,
    });
    lib.want_lto = false;
    lib.disable_sanitize_c = true;
    if (optimize == .Debug or optimize == .ReleaseSafe)
        lib.bundle_compiler_rt = true
    else
        lib.strip = true;
    lib.addCSourceFiles(src, &.{
        "-Wall",
        "-Wextra",
    });
    lib.defineCMacro("__USE_MINGW_ANSI_STDIO", "1");
    lib.addIncludePath("include");
    lib.addIncludePath("src");
    lib.linkLibC();
    lib.install();
    lib.installHeadersDirectory("include", "");

    const exe = b.addExecutable(.{
        .name = "nanosleep",
        .target = target,
        .optimize = optimize,
    });
    exe.addCSourceFile("tests/t_clock_getres.c", &.{"-Wall"});
    exe.linkLibrary(lib);
    exe.linkLibC();
    exe.install();
}

fn checkVersion() bool {
    const builtin = @import("builtin");
    if (!@hasDecl(builtin, "zig_version")) {
        return false;
    }

    const needed_version = std.SemanticVersion.parse("0.11.0-dev.2191") catch unreachable;
    const version = builtin.zig_version;
    const order = version.order(needed_version);
    return order != .lt;
}

const src: []const []const u8 = &.{
    "src/nanosleep.c",
    "src/cond.c",
    "src/barrier.c",
    "src/misc.c",
    "src/clock.c",
    "src/libgcc/dll_math.c",
    "src/spinlock.c",
    "src/thread.c",
    "src/mutex.c",
    "src/sem.c",
    "src/sched.c",
    "src/ref.c",
    "src/rwlock.c",
};
