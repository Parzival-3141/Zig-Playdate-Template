const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const playdate = @import("playdate");
    const playdate_dep = b.dependency("playdate", .{});

    const sdk_path = std.process.getEnvVarOwned(b.allocator, "PLAYDATE_SDK_PATH") catch |err| switch (err) {
        error.EnvironmentVariableNotFound => @panic("PLAYDATE_SDK_PATH environment variable not found"),
        else => return err,
    };

    const game = playdate.addGame(b, playdate_dep, .{
        .name = "example",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .sdk_path = sdk_path,
        // .build_for_simulator = true, // TODO: would be set by addRunSimulator as well?
    });

    // This copies the given directory into the pdx source tree.
    // NOTE: I think this is redundant. The user can access the pdx_source field directly instead.
    // game.addIncludePath(b.path("assets"));

    // You have access to the artifact and pdx writefile for more custom build logic
    _ = game.pdx_source.addCopyDirectory(b.path("assets/"), "assets", .{});
    // game.artifact.addModule(...)

    // there should be a simple and custom api for installing.
    // simple just installs to prefix (i.e. b.installArtifact).
    // custom would control where? should return install step too.
    game.install(b);

    // TODO:
    // // This *creates* a Run step in the build graph, that will launch the game
    // // in the simulator. This ensures the game will be compiled for the
    // // simulator as well.
    // const run_sim = playdate.addRunSimulator(game);

    // // By making the run step depend on the install step, it will be run from the
    // // installation directory rather than directly from within the cache directory.
    // // This is not necessary, however, if the application depends on other installed
    // // files, this ensures they will be present and in the expected location.
    // run_sim.step.dependOn(b.getInstallStep());

    // // This creates a build step. It will be visible in the `zig build --help` menu,
    // // and can be selected like this: `zig build run`
    // // This will evaluate the `run` step rather than the default, which is "install".
    // const run_step = b.step("run", "Run the game in the Simulator");
    // run_step.dependOn(&run_sim.step);

    // TODO:
    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = b.host,
    //     .optimize = optimize,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // // Similar to creating the run step earlier, this exposes a `test` step to
    // // the `zig build --help` menu, providing a way for the user to request
    // // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_exe_unit_tests.step);
}
