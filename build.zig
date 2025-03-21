const std = @import("std");

pub fn build(b: *std.Build) void {
    if (comptime !checkVersion())
        @compileError("Please! Update zig toolchain >= 0.11!");
    const target = b.standardTargetOptions(.{
        .whitelist = permissive_targets,
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
            .abi = .gnu,
        },
    });
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
    lib.root_module.sanitize_c = false;
    if (optimize == .Debug or optimize == .ReleaseSafe)
        lib.bundle_compiler_rt = true
    else
        lib.root_module.strip = true;
    lib.addCSourceFiles(.{ .files = src, .flags = &.{
        "-Wall",
        "-Wextra",
    } });
    lib.root_module.addCMacro("__USE_MINGW_ANSI_STDIO", "1");
    lib.addIncludePath(b.path("include"));
    lib.addIncludePath(b.path("src"));
    lib.linkLibC();
    b.installArtifact(lib);
    lib.installHeadersDirectory(b.path("include"), "", .{});

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

fn buildExe(b: *std.Build, pthread: *std.Build.Step.Compile, binfo: BuildInfo) void {
    const target = pthread.root_module.resolved_target.?;
    const optimize = pthread.root_module.optimize.?;
    const exe = b.addExecutable(.{
        .name = binfo.name,
        .target = target,
        .optimize = optimize,
    });
    if (optimize != .Debug)
        exe.root_module.strip = true;
    if (target.result.os.tag == .windows)
        exe.want_lto = false;
    exe.addIncludePath(b.path("include"));
    exe.addIncludePath(b.path("src"));
    exe.linkLibrary(pthread);
    exe.addCSourceFile(.{
        .file = b.path(binfo.file),
        .flags = &.{
            "-Wall",
            "-Wextra",
            "-Wpedantic",
        },
    });
    exe.linkLibC();

    if (!std.mem.startsWith(u8, binfo.name, "test"))
        b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);

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

    const needed_version = std.SemanticVersion.parse("0.11.0") catch unreachable;
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

const permissive_targets: []const std.Target.Query = &.{
    .{}, // native
    .{
        .cpu_arch = .aarch64,
        .cpu_model = .baseline,
        .os_tag = .windows,
        .abi = .gnu,
    },
    .{
        .cpu_arch = .x86,
        .cpu_model = .baseline,
        .os_tag = .windows,
        .abi = .gnu,
    },
    .{
        .cpu_arch = .x86_64,
        .cpu_model = .baseline,
        .os_tag = .windows,
        .abi = .gnu,
    },
};
