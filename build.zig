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

    /// Installs the compiled game.pdx to the prefix directory
    pub fn install(game: Game, b: *Build) void {
        b.getInstallStep().dependOn(&game.addInstall(b, .prefix).step);
    }

    /// Installs the compiled game.pdx to the `install_dir`
    pub fn addInstall(game: Game, b: *Build, install_dir: Build.InstallDir) *Build.Step.InstallDir {
        return b.addInstallDirectory(.{
            .source_dir = game.pdx_output,
            .install_dir = install_dir,
            .install_subdir = b.fmt("{s}.pdx", .{game.name}),
        });
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
    };

    // Add device pdex
    {
        const playdate_target = b.resolveTargetQuery(
            std.zig.CrossTarget.parse(.{
                .arch_os_abi = "thumb-freestanding-eabihf",
                .cpu_features = "cortex_m7+vfp4d16sp",
                .object_format = "elf",
            }) catch unreachable,
        );

        const pdex = b.addExecutable(.{
            .name = "pdex",
            .root_source_file = options.root_source_file,
            .target = playdate_target,
            .optimize = options.optimize,
            .pic = true,
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
        const pdex = b.addSharedLibrary(.{
            .name = "pdex",
            .root_source_file = options.root_source_file,
            .target = b.host,
            .optimize = options.optimize,
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
        if (b.host.result.os.tag == .windows) "pdc.exe" else "pdc",
    });

    const run_pdc = b.addSystemCommand(&.{ pdc_path, "-sdkpath", options.sdk_path });
    run_pdc.addDirectoryArg(game.pdx_source.getDirectory());
    game.pdx_output = run_pdc.addOutputFileArg(pdx_basename);

    return game;
}

pub fn addRunSimulator(b: *Build, game: *Game) *Step.Run {
    const simulator_path = switch (b.host.result.os.tag) {
        .linux => b.pathJoin(&.{ game.sdk_path, "bin", "PlaydateSimulator" }),
        .macos => "open", // `open` focuses the window, while running the simulator directly doesn't.
        .windows => b.pathJoin(&.{ game.sdk_path, "bin", "PlaydateSimulator.exe" }),
        else => @panic("Unsupported OS"),
    };

    // It seems fine to just copy the simulator pdex after running the pdc.
    // Yucky, but I'm not sure how else to build and include the pdex depending
    // on whether the simulator step is run.
    const copy_step = CopyFileStep.create(b, game.simulator.getEmittedBin(), game.pdx_output);

    const run_sim = b.addSystemCommand(&.{simulator_path});
    run_sim.addDirectoryArg(game.pdx_output);
    run_sim.step.dependOn(&copy_step.step);
    return run_sim;
}

const CopyFileStep = struct {
    step: Step,
    file: LazyPath,
    dest_dir: LazyPath,

    pub fn create(owner: *Build, file: LazyPath, dest_dir: LazyPath) *CopyFileStep {
        const copy = owner.allocator.create(CopyFileStep) catch @panic("OOM");
        copy.* = .{
            .step = Step.init(.{
                .id = .custom,
                .name = owner.dupe("CopyFile"),
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

    pub fn make(step: *Step, _: std.Progress.Node) !void {
        const copy: *CopyFileStep = @fieldParentPtr("step", step);

        const file_path = copy.file.getPath(step.owner);
        var dest_dir = try std.fs.cwd().openDir(copy.dest_dir.getPath(step.owner), .{});
        defer dest_dir.close();

        try std.fs.cwd().copyFile(
            file_path,
            dest_dir,
            step.owner.fmt(
                "pdex{s}",
                .{step.owner.host.result.dynamicLibSuffix()},
            ),
            .{},
        );
    }
};
