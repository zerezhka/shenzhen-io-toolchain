const std = @import("std");

const version = "0.0.1";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const options = b.addOptions();
    options.addOption([]const u8, "version", version);

    const exe = b.addExecutable(.{
        .name = "sio",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "options", .module = options.createModule() }},
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    b.step("run", "Run sio").dependOn(&run_cmd.step);

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "options", .module = options.createModule() }},
        }),
    });
    b.step("test", "Run tests").dependOn(&b.addRunArtifact(tests).step);

    const bench = b.addExecutable(.{
        .name = "bench",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/bench.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_bench = b.addRunArtifact(bench);
    b.step("bench", "Run raw parse→emit benchmark (synthetic sample)").dependOn(&run_bench.step);

    const bench_fs = b.addExecutable(.{
        .name = "bench_fs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/bench_fs.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_bench_fs = b.addRunArtifact(bench_fs);
    b.step("bench-fs", "Run filesystem benchmark (real .asm files)").dependOn(&run_bench_fs.step);
}
