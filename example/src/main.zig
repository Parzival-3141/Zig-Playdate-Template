const std = @import("std");
const pdapi = @import("playdate");

pub const panic = pdapi.panic_handler.panic;

const ExampleGlobalState = struct {
    playdate: *pdapi.PlaydateAPI,
    zig_image: *pdapi.LCDBitmap,
    font: *pdapi.LCDFont,
    image_width: c_int,
    image_height: c_int,
};

pub export fn eventHandler(playdate: *pdapi.PlaydateAPI, event: pdapi.PDSystemEvent, arg: u32) callconv(.C) c_int {
    //TODO: replace with your own code!

    _ = arg;
    switch (event) {
        .init => {
            //NOTE: Initalizing the panic handler should be the first thing that is done.
            //      If a panic happens before calling this, the simulator or hardware will
            //      just crash with no message.
            pdapi.panic_handler.init(playdate);

            const zig_image = playdate.graphics.loadBitmap("assets/images/zig-playdate", null).?;
            var image_width: c_int = undefined;
            var image_height: c_int = undefined;
            playdate.graphics.getBitmapData(zig_image, &image_width, &image_height, null, null, null);

            const font = playdate.graphics.loadFont("/System/Fonts/Roobert-20-Medium.pft", null).?;
            playdate.graphics.setFont(font);

            const global_state: *ExampleGlobalState =
                @ptrCast(
                @alignCast(
                    playdate.system.realloc(
                        null,
                        @sizeOf(ExampleGlobalState),
                    ),
                ),
            );
            global_state.* = .{
                .playdate = playdate,
                .font = font,
                .zig_image = zig_image,
                .image_width = image_width,
                .image_height = image_height,
            };

            playdate.system.setUpdateCallback(update_and_render, global_state);
        },
        else => {},
    }
    return 0;
}

fn update_and_render(userdata: ?*anyopaque) callconv(.C) c_int {
    //TODO: replace with your own code!

    const global_state: *ExampleGlobalState = @ptrCast(@alignCast(userdata.?));
    const playdate = global_state.playdate;
    const zig_image = global_state.zig_image;

    const to_draw = "Hold Ⓐ";
    const text_width = playdate.graphics.getTextWidth(
        global_state.font,
        to_draw,
        to_draw.len,
        .utf8,
        0,
    );

    var draw_mode: pdapi.LCDBitmapDrawMode = .copy;
    var clear_color: pdapi.LCDSolidColor = .white;

    var buttons: pdapi.PDButtons = .{};
    playdate.system.getButtonState(&buttons, null, null);
    if (buttons.a) {
        draw_mode = .inverted;
        clear_color = .black;
    }

    playdate.graphics.setDrawMode(draw_mode);
    playdate.graphics.clear(.{ .solid = clear_color });

    playdate.graphics.drawBitmap(zig_image, 0, 0, .unflipped);
    const pixel_width = playdate.graphics.drawText(
        to_draw,
        to_draw.len,
        .utf8,
        @divTrunc(pdapi.LCD_COLUMNS - text_width, 2),
        pdapi.LCD_ROWS - playdate.graphics.getFontHeight(global_state.font) - 20,
    );
    _ = pixel_width;

    //returning 1 signals to the OS to draw the frame.
    //we always want this frame drawn
    return 1;
}
