const std = @import("std");
const pdapi = @import("playdate_api_definitions.zig");
const builtin = @import("builtin");

var global_playate: *pdapi.PlaydateAPI = undefined;
pub fn init(playdate: *pdapi.PlaydateAPI) void {
    global_playate = playdate;
}

// @Todo threading?
var panic_stage: u8 = 0;

pub fn panic(
    msg: []const u8,
    error_return_trace: ?*std.builtin.StackTrace,
    return_address: ?usize,
) noreturn {
    @setCold(true);
    // _ = error_return_trace;
    _ = return_address;

    switch (panic_stage) {
        0 => panic_stage = 1,
        1 => {
            // a panic happened while trying to print the previous panic message
            panic_stage = 2;
            global_playate.system.@"error"("Panicked during a panic. Aborting.");
            while (true) @breakpoint();
        },
        else => {
            // Panicked while printing "Panicked during a panic."
            while (true) @breakpoint();
        },
    }

    switch (comptime builtin.os.tag) {
        .freestanding => {
            //Playdate hardware

            //TODO: The Zig std library does not yet support stacktraces on Playdate hardware.
            //We will need to do this manually. Some notes on trying to get it working:
            //Frame pointer is R7
            //Next Frame pointer is *R7
            //Return address is *(R7+4)
            //To print out the trace correctly,
            //We need to know the load address and it doesn't seem to be exactly
            //0x6000_0000 as originally thought

            global_playate.system.@"error"("PANIC: %s", msg.ptr);
        },
        else => {
            //playdate simulator
            var stack_trace_buffer = [_]u8{0} ** 4096;
            var buffer = [_]u8{0} ** 4096;
            var stream = std.io.fixedBufferStream(&stack_trace_buffer);

            const stack_trace_string = stack_trace_string: {
                if (builtin.strip_debug_info) {
                    break :stack_trace_string "Unable to dump stack trace: Debug info stripped";
                }
                global_playate.system.logToConsole("getting debug info");
                const debug_info = std.debug.getSelfDebugInfo() catch |err| {
                    const to_print = std.fmt.bufPrintZ(
                        &buffer,
                        "Unable to dump stack trace: Unable to open debug info: {s}\n",
                        .{@errorName(err)},
                    ) catch |print_err| switch (print_err) {
                        error.NoSpaceLeft => unreachable, // You'd have to intentionally create a ridiculously long error name to break this
                    };
                    break :stack_trace_string to_print;
                };
                // TODO:
                // writeCurrentStackTrace winds up hitting an unreachable on linux in dl_iterate_phdr() (std/posix:5499).
                // I think this is either due to malformed ELF headers loaded by the simulator at runtime,
                // or faulty parsing logic in the stdlib for this target. It also seems like error_return_trace is always
                // null. Either way I'm just going to disable it for now.
                if (false) {
                    global_playate.system.logToConsole("writing stack trace");
                    if (error_return_trace) |err_trace| {
                        std.debug.writeStackTrace(
                            err_trace.*,
                            stream.writer(),
                            void_allocator,
                            debug_info,
                            .no_color,
                        ) catch |err| switch (err) {
                            error.NoSpaceLeft => {
                                const trunc_msg = "... stack trace truncated.";
                                @memcpy(buffer[buffer.len - trunc_msg.len ..], trunc_msg);
                            },
                            else => break :stack_trace_string "Unable to print stack trace: Unknown error while writing stack trace",
                        };
                    }
                    std.debug.writeCurrentStackTrace(
                        stream.writer(),
                        debug_info,
                        .no_color,
                        null,
                    ) catch |err| switch (err) {
                        error.NoSpaceLeft => {
                            const trunc_msg = "... stack trace truncated.";
                            @memcpy(buffer[buffer.len - trunc_msg.len ..], trunc_msg);
                        },
                        else => break :stack_trace_string "Unable to dump stack trace: Unknown error while writing stack trace",
                    };
                }

                //NOTE: playdate.system.error (and all Playdate APIs that deal with strings) require a null termination
                const null_char_index = @min(stream.pos, stack_trace_buffer.len - 1);
                stack_trace_buffer[null_char_index] = 0;

                break :stack_trace_string &stack_trace_buffer;
            };
            global_playate.system.logToConsole("calling error");
            global_playate.system.@"error"(
                "PANIC: %s\n%s",
                msg.ptr,
                stack_trace_string.ptr,
            );
        },
    }

    while (true) {
        @breakpoint();
    }
}

const void_allocator: std.mem.Allocator = .{
    .ptr = undefined,
    .vtable = &.{
        .alloc = &voidAlloc,
        .resize = &voidResize,
        .free = &voidFree,
    },
};

fn voidAlloc(_: *anyopaque, _: usize, _: u8, _: usize) ?[*]u8 {
    return null;
}

fn voidResize(_: *anyopaque, _: []u8, _: u8, _: usize, _: usize) bool {
    return false;
}

fn voidFree(_: *anyopaque, _: []u8, _: u8, _: usize) void {}
