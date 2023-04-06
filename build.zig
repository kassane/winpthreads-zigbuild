const std = @import("std");

pub fn build(b: *std.Build) void {
    if (comptime !checkVersion())
        @compileError("Please! Update zig toolchain >= 0.11!");
    const target: std.zig.CrossTarget = .{
        .os_tag = .windows,
        .abi = .gnu,
    };
    const optimize = b.standardOptimizeOption(.{});

    const shared = b.option(bool, "Shared", "Build Winpthreads Shared Library [default: false]") orelse false;
    const tests = b.option(bool, "Tests", "Build Tests [default: false]") orelse false;

    const lib = if (shared)
        b.addSharedLibrary(.{
            .name = "winpthreads",
            .optimize = optimize,
            .target = target,
            .version = .{
                .major = 10,
                .minor = 0,
                .patch = 0,
            },
        })
    else
        b.addStaticLibrary(.{
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

    if (tests) {
        buildExe(b, lib, .{
            .name = "test_nanosleep",
            .file = "tests/t_nanosleep.c",
        });
        buildExe(b, lib, .{
            .name = "test_clock_gettime",
            .file = "tests/t_clock_gettime.c",
        });
        buildExe(b, lib, .{
            .name = "test_clock_getres",
            .file = "tests/t_clock_getres.c",
        });
    }
}

fn buildExe(b: *std.Build, pthread: *std.Build.CompileStep, binfo: BuildInfo) void {
    const exe = b.addExecutable(.{
        .name = binfo.name,
        .target = pthread.target,
        .optimize = pthread.optimize,
    });
    if (pthread.optimize != .Debug)
        exe.strip = true
    else
        exe.sanitize_thread = true;
    if (exe.target.isWindows())
        exe.want_lto = false;
    exe.addIncludePath("include");
    exe.addIncludePath("src");
    exe.linkLibrary(pthread);
    exe.addCSourceFile(
        binfo.file,
        &.{
            "-Wall",
            "-Wextra",
        },
    );
    exe.linkLibC();

    if (!std.mem.startsWith(u8, binfo.name, "test"))
        exe.install();
    const run_cmd = exe.run();

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(binfo.name, b.fmt("Run the {s}", .{binfo.name}));
    run_step.dependOn(&run_cmd.step);
}

const BuildInfo = struct {
    name: []const u8,
    file: []const u8,
};

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
