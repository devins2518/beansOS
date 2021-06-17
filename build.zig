const Builder = std.build.Builder;
const builtin = @import("builtin");
const std = @import("std");
const target = std.Target;

pub fn build(b: *Builder) void {
    // Use eabihf for freestanding thumb code with hardware float support
    const buildTarget = std.zig.CrossTarget{
        .cpu_arch = target.Cpu.Arch.thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
        .os_tag = target.Os.Tag.freestanding,
        .abi = target.Abi.eabihf,
    };

    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("beansOS.elf", "src/main.zig");
    exe.setBuildMode(mode);
    exe.setTarget(buildTarget);
    exe.setBuildMode(mode);

    const vector = b.addObject("vector", "src/vectors.zig");
    vector.setTarget(buildTarget);
    vector.setBuildMode(mode);
    exe.addObject(vector);

    // TODO: Make different linker scripts for different boards?
    exe.setLinkerScriptPath(.{ .path = "linkers/f303re.ld" });

    const bin = b.addInstallRaw(exe, "beansOS.bin");
    const bin_step = b.step("bin", "Generate binary file to be flashed");
    bin_step.dependOn(&bin.step);

    const flash_cmd = b.addSystemCommand(&[_][]const u8{
        "st-flash",
        "write",
        b.getInstallPath(bin.dest_dir, bin.dest_filename),
        "0x8000000",
    });
    flash_cmd.step.dependOn(&bin.step);
    const flash_step = b.step("flash", "Flash onto your STM32 board");
    flash_step.dependOn(&flash_cmd.step);

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
