const std = @import("std");

const project_name = "surreptitious-radiator";
const root = "src/main.zig";

pub fn build(builder: *std.Build) void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    const compile_step = builder.addExecutable(.{
        .name = project_name,
        .root_source_file = .{ .path = root },
        .target = target,
        .optimize = optimize,
    });

    builder.installArtifact(compile_step);

    const run_step = builder.addRunArtifact(compile_step);
    run_step.step.dependOn(builder.getInstallStep());
    // `.step` means "top-level named step".
    builder.step("run", "Run the app").dependOn(&run_step.step);

    const compile_unit_tests_step = builder.addTest(.{
        .root_source_file = .{ .path = root },
        .target = target,
        .optimize = optimize,
    });
    const run_tests_step = builder.addRunArtifact(compile_unit_tests_step);
    builder.step("test", "Run unit tests").dependOn(&run_tests_step.step);
}
