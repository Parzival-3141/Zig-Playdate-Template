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
        .name = "hello-zig",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .sdk_path = sdk_path,
    });

    // You have access to the artifact and pdx writefile for more custom build logic.
    // Unfortunately due to how build steps work you have to apply your compile logic
    // twice; once for the device and once for the simulator. You can easily wrap this
    // inside a function though.
    _ = game.pdx_source.addCopyDirectory(b.path("assets/"), "assets", .{});
    _ = game.pdx_source.addCopyFile(b.path("pdxinfo"), "pdxinfo");
    // game.device.addModule(...)
    // game.simulator.addModule(...)

    // Installs the compiled hello-zig.pdx to the prefix directory as part of the
    // top-level Install step.
    game.install(b);

    // This *creates* a Run step in the build graph, that will launch the game
    // in the simulator. Calling this function ensures the game will be compiled
    // for the simulator as well.
    const run_sim = playdate.addRunSimulator(b, game);

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the game in the Simulator");
    run_step.dependOn(&run_sim.step);

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
