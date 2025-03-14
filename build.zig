const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) !void {
    _ = b.addModule("playdate", .{
        .root_source_file = b.path("src/root.zig"),
    });
}

// TODO: expose pdex.elf for debugging

const Step = Build.Step;
const LazyPath = std.Build.LazyPath;

pub const GameOptions = struct {
    name: []const u8,
    sdk_path: []const u8,
    root_source_file: ?LazyPath = null,
    optimize: std.builtin.OptimizeMode = .Debug,
};

pub const Game = struct {
    name: []const u8,
    sdk_path: []const u8,
    device: *Step.Compile,
    simulator: *Step.Compile,
    pdx_source: *Step.WriteFile,
    pdx_output: LazyPath,
    install_step: ?*Step.InstallDir,

    /// Installs the compiled game.pdx to the prefix directory
    pub fn install(game: *Game, b: *Build) void {
        b.getInstallStep().dependOn(&game.addInstall(b, .prefix).step);
    }

    /// Installs the compiled game.pdx to the `install_dir`
    pub fn addInstall(game: *Game, b: *Build, install_dir: Build.InstallDir) *Step.InstallDir {
        const install_step = b.addInstallDirectory(.{
            .source_dir = game.pdx_output,
            .install_dir = install_dir,
            .install_subdir = b.fmt("{s}.pdx", .{game.name}),
        });
        game.install_step = install_step;
        return install_step;
    }
};

pub fn addGame(b: *Build, playdate_dep: *Build.Dependency, options: GameOptions) *Game {
    const game = b.allocator.create(Game) catch @panic("OOM");
    game.* = .{
        .name = options.name,
        .sdk_path = options.sdk_path,
        .device = undefined,
        .simulator = undefined,
        .pdx_source = b.addWriteFiles(),
        .pdx_output = undefined,
        .install_step = null,
    };

    // Add device pdex
    {
        const playdate_target = b.resolveTargetQuery(.{
            .cpu_arch = .thumb,
            .os_tag = .freestanding,
            .abi = .eabihf,
            .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m7 },
            .cpu_features_add = std.Target.arm.featureSet(&.{.vfp4d16sp}),
            .ofmt = .elf,
        });

        const pdex = b.addExecutable(.{
            .name = "pdex",
            .root_module = b.createModule(.{
                .root_source_file = options.root_source_file,
                .target = playdate_target,
                .optimize = options.optimize,
                .pic = true,
            }),
        });
        pdex.root_module.addImport("playdate", playdate_dep.module("playdate")); // TODO: should this be exposed to the user?

        // These arguments are included in the makefiles, though I'm not sure they're necessary.
        // pdex.link_function_sections = true;
        // pdex.link_data_sections = true;
        // pdex.link_gc_sections = true;

        pdex.link_emit_relocs = true;
        pdex.entry = .{ .symbol_name = "eventHandler" };

        pdex.setLinkerScript(playdate_dep.path("src/link_map.ld"));
        if (options.optimize == .ReleaseFast) {
            pdex.root_module.omit_frame_pointer = true;
        }

        game.device = pdex;
        _ = game.pdx_source.addCopyFile(pdex.getEmittedBin(), "pdex.elf");
    }

    // Add simulator pdex
    {
        const pdex = b.addLibrary(.{
            .name = "pdex",
            .linkage = .dynamic,
            .root_module = b.createModule(.{
                .root_source_file = options.root_source_file,
                .target = b.graph.host,
                .optimize = options.optimize,
            }),
        });
        pdex.root_module.addImport("playdate", playdate_dep.module("playdate")); // TODO: should this be exposed to the user?
        game.simulator = pdex;
    }

    const pdx_basename = b.fmt("{s}.pdx", .{options.name});
    game.pdx_source.step.name = b.fmt("WriteFile {s} source", .{pdx_basename});

    // Add run pdc
    const pdc_path = b.pathJoin(&.{
        options.sdk_path,
        "bin",
        if (b.graph.host.result.os.tag == .windows) "pdc.exe" else "pdc",
    });

    const run_pdc = b.addSystemCommand(&.{ pdc_path, "-sdkpath", options.sdk_path });
    run_pdc.addDirectoryArg(game.pdx_source.getDirectory());
    game.pdx_output = run_pdc.addOutputFileArg(pdx_basename);

    return game;
}

pub fn addRunSimulator(b: *Build, game: *Game) *Step.Run {
    const simulator_path = switch (b.graph.host.result.os.tag) {
        .linux => b.pathJoin(&.{ game.sdk_path, "bin", "PlaydateSimulator" }),
        .macos => "open", // `open` focuses the window, while running the simulator directly doesn't.
        .windows => b.pathJoin(&.{ game.sdk_path, "bin", "PlaydateSimulator.exe" }),
        else => @panic("Unsupported OS"),
    };

    const pdx_output: LazyPath = if (game.install_step) |install|
        .{ .cwd_relative = b.getInstallPath(
            install.options.install_dir,
            install.options.install_subdir,
        ) }
    else
        game.pdx_output;

    // It seems fine to just copy the simulator pdex after running the pdc.
    // Yucky, but I'm not sure how else to build and include the pdex depending
    // on whether the simulator step is run.
    const copy_step = CopyFileStep.create(b, game.simulator.getEmittedBin(), pdx_output);

    const run_sim = b.addSystemCommand(&.{simulator_path});
    run_sim.addDirectoryArg(pdx_output);
    run_sim.step.dependOn(&copy_step.step);
    if (game.install_step) |install| run_sim.step.dependOn(&install.step);
    return run_sim;
}

// Based on Step.InstallFile
const CopyFileStep = struct {
    step: Step,
    file: LazyPath,
    dest_dir: LazyPath,

    pub fn create(owner: *Build, file: LazyPath, dest_dir: LazyPath) *CopyFileStep {
        const copy = owner.allocator.create(CopyFileStep) catch @panic("OOM");
        copy.* = .{
            .step = Step.init(.{
                .id = .custom,
                .name = owner.fmt("copy {s} to {s}", .{
                    file.getDisplayName(),
                    dest_dir.getDisplayName(),
                }),
                .owner = owner,
                .makeFn = make,
            }),
            .file = file.dupe(owner),
            .dest_dir = dest_dir.dupe(owner),
        };
        file.addStepDependencies(&copy.step);
        dest_dir.addStepDependencies(&copy.step);
        return copy;
    }

    pub fn make(step: *Step, _: Step.MakeOptions) !void {
        const copy: *CopyFileStep = @fieldParentPtr("step", step);
        try step.singleUnchangingWatchInput(copy.file);
        const b = step.owner;

        const full_src_path = copy.file.getPath2(b, step);
        const full_dest_path = copy.dest_dir.path(b, b.fmt(
            "pdex{s}",
            .{b.graph.host.result.dynamicLibSuffix()},
        )).getPath2(b, step);
        const cwd = std.fs.cwd();
        const prev = std.fs.Dir.updateFile(cwd, full_src_path, cwd, full_dest_path, .{}) catch |err| {
            return step.fail("unable to update file from '{s}' to '{s}': {s}", .{
                full_src_path, full_dest_path, @errorName(err),
            });
        };
        step.result_cached = prev == .fresh;
    }
};
