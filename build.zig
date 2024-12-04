const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) !void {
    _ = b.addModule("playdate", .{
        .root_source_file = b.path("src/root.zig"),
    });
}

// TODO: simulator support
// TODO: expose pdex.elf for debugging

const Step = Build.Step;
const LazyPath = std.Build.LazyPath;

pub const GameOptions = struct {
    name: []const u8,
    sdk_path: []const u8,
    root_source_file: ?LazyPath = null,
    optimize: std.builtin.OptimizeMode = .Debug,
    build_for_simulator: bool = false,
};

pub const Game = struct {
    name: []const u8,
    artifact: *Step.Compile,
    pdx_source: *Step.WriteFile,
    pdx_output: LazyPath,

    /// Installs the compiled game.pdx to the prefix directory
    pub fn install(game: Game, b: *Build) void {
        b.installDirectory(.{
            .source_dir = game.pdx_output,
            .install_dir = .prefix,
            .install_subdir = b.fmt("{s}.pdx", .{game.name}),
        });
    }
};

pub fn addGame(b: *Build, playdate_dep: *Build.Dependency, options: GameOptions) *Game {
    const game = b.allocator.create(Game) catch @panic("OOM");
    game.* = .{
        .name = options.name,
        .artifact = undefined,
        .pdx_source = undefined,
        .pdx_output = undefined,
    };

    // Add exe pdex.elf

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

    game.artifact = pdex;

    // Add write pdx_source

    game.pdx_source = b.addWriteFiles();
    _ = game.pdx_source.addCopyFile(pdex.getEmittedBin(), "pdex.elf");

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
