const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zsti",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .error_tracing = true,
    });
    b.installArtifact(exe);

    const serial = b.dependency("serial", .{ .target = target, .optimize = optimize }).module("serial");
    exe.root_module.addImport("serial", serial);
}
