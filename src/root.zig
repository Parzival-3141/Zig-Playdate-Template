const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;

pub const panic_handler = @import("panic_handler.zig");

pub const PlaydateAPI = extern struct {
    system: *const PlaydateSys,
    file: *const PlaydateFile,
    graphics: *const PlaydateGraphics,
    sprite: *const PlaydateSprite,
    display: *const PlaydateDisplay,
    sound: *const PlaydateSound,
    lua: *const PlaydateLua,
    json: *const PlaydateJSON,
    scoreboards: *const PlaydateScoreboards,

    pub const version = "2.6.2";
};

/////////Zig Utility Functions///////////
pub fn is_compiling_for_playdate_hardware() bool {
    return builtin.os.tag == .freestanding and builtin.cpu.arch.isThumb();
}

////////Buttons//////////////
pub const PDButtons = packed struct(c_int) {
    left: bool,
    right: bool,
    up: bool,
    down: bool,
    b: bool,
    a: bool,
    _padding: u26,
};

///////////////System/////////////////////////
pub const PDMenuItem = opaque {};
/// return 0 when done
pub const PDCallbackFunction = *const fn (userdata: ?*anyopaque) callconv(.C) c_int;
pub const PDMenuItemCallbackFunction = *const fn (userdata: ?*anyopaque) callconv(.C) void;
pub const PDButtonCallbackFunction = *const fn (
    button: PDButtons,
    down: c_int,
    when: u32,
    userdata: ?*anyopaque,
) callconv(.C) c_int;
pub const PDSystemEvent = enum(c_int) {
    init,
    init_lua,
    lock,
    unlock,
    pause,
    @"resume",
    terminate,
    /// arg is keycode
    key_pressed,
    /// arg is keycode
    key_released,
    low_power,
};
pub const PDLanguage = enum(c_int) {
    english,
    japanese,
    unknown,
};

pub const PDPeripherals = packed struct(c_int) {
    accelerometer: bool,
    _padding: u31 = 0,

    pub const none: PDPeripherals = @bitCast(@as(c_int, 0));
    pub const all: PDPeripherals = @bitCast(@as(c_int, 0xFFFF));
};

pub const PDStringEncoding = enum(c_int) {
    ascii,
    utf8,
    @"16BitLE",
};

pub const PDDateTime = extern struct {
    year: u16,
    /// 1-12
    month: u8,
    /// 1-31
    day: u8,
    /// 1=monday-7=sunday
    weekday: u8,
    /// 0-23
    hour: u8,
    minute: u8,
    second: u8,
};

pub const PlaydateSys = extern struct {
    /// Acts as malloc when ptr == NULL. Acts as free when size == 0.
    realloc: *const fn (ptr: ?*anyopaque, size: usize) callconv(.C) ?*anyopaque,
    /// Returns the length of out_string. Caller owns the memory returned by out_string.
    formatString: *const fn (out_string: *[*:0]u8, fmt: [*:0]const u8, ...) callconv(.C) c_int,
    logToConsole: *const fn (fmt: [*:0]const u8, ...) callconv(.C) void,
    /// Calls the log function, outputting an error in red to the console, then pauses execution.
    @"error": *const fn (fmt: [*:0]const u8, ...) callconv(.C) void,
    getLanguage: *const fn () callconv(.C) PDLanguage,
    getCurrentTimeMilliseconds: *const fn () callconv(.C) c_uint,
    getSecondsSinceEpoch: *const fn (milliseconds: ?*c_uint) callconv(.C) c_uint,
    drawFPS: *const fn (x: c_int, y: c_int) callconv(.C) void,

    setUpdateCallback: *const fn (update: PDCallbackFunction, userdata: ?*anyopaque) callconv(.C) void,
    getButtonState: *const fn (
        current: ?*PDButtons,
        pushed: ?*PDButtons,
        released: ?*PDButtons,
    ) callconv(.C) void,
    setPeripheralsEnabled: *const fn (mask: PDPeripherals) callconv(.C) void,
    getAccelerometer: *const fn (outx: ?*f32, outy: ?*f32, outz: ?*f32) callconv(.C) void,
    getCrankChange: *const fn () callconv(.C) f32,
    getCrankAngle: *const fn () callconv(.C) f32,
    isCrankDocked: *const fn () callconv(.C) c_int,
    /// Returns previous setting
    setCrankSoundsDisabled: *const fn (flag: c_int) callconv(.C) c_int,

    getFlipped: *const fn () callconv(.C) c_int,
    setAutoLockDisabled: *const fn (disable: c_int) callconv(.C) void,

    setMenuImage: *const fn (bitmap: *LCDBitmap, xOffset: c_int) callconv(.C) void,
    /// The returned menu item is freed when removed from the menu; it does not need to be freed manually.
    addMenuItem: *const fn (
        title: [*:0]const u8,
        callback: PDMenuItemCallbackFunction,
        userdata: ?*anyopaque,
    ) callconv(.C) ?*PDMenuItem,
    /// The returned menu item is freed when removed from the menu; it does not need to be freed manually.
    addCheckmarkMenuItem: *const fn (
        title: [*:0]const u8,
        value: c_int,
        callback: PDMenuItemCallbackFunction,
        userdata: ?*anyopaque,
    ) callconv(.C) ?*PDMenuItem,
    /// The returned menu item is freed when removed from the menu; it does not need to be freed manually.
    addOptionsMenuItem: *const fn (
        title: [*:0]const u8,
        optionTitles: [*][*:0]const u8,
        optionsCount: c_int,
        callback: PDMenuItemCallbackFunction,
        userdata: ?*anyopaque,
    ) callconv(.C) ?*PDMenuItem,
    removeAllMenuItems: *const fn () callconv(.C) void,
    removeMenuItem: *const fn (menuItem: *PDMenuItem) callconv(.C) void,
    getMenuItemValue: *const fn (menuItem: *PDMenuItem) callconv(.C) c_int,
    setMenuItemValue: *const fn (menuItem: *PDMenuItem, value: c_int) callconv(.C) void,
    getMenuItemTitle: *const fn (menuItem: *PDMenuItem) callconv(.C) [*:0]const u8,
    setMenuItemTitle: *const fn (menuItem: *PDMenuItem, title: [*:0]const u8) callconv(.C) void,
    getMenuItemUserdata: *const fn (menuItem: *PDMenuItem) callconv(.C) ?*anyopaque,
    setMenuItemUserdata: *const fn (menuItem: *PDMenuItem, ud: ?*anyopaque) callconv(.C) void,

    getReduceFlashing: *const fn () callconv(.C) c_int,

    // 1.1
    getElapsedTime: *const fn () callconv(.C) f32,
    resetElapsedTime: *const fn () callconv(.C) void,

    // 1.4
    getBatteryPercentage: *const fn () callconv(.C) f32,
    getBatteryVoltage: *const fn () callconv(.C) f32,

    // 1.13
    getTimezoneOffset: *const fn () callconv(.C) i32,
    shouldDisplay24HourTime: *const fn () callconv(.C) c_int,
    convertEpochToDateTime: *const fn (epoch: u32, datetime: *PDDateTime) callconv(.C) void,
    convertDateTimeToEpoch: *const fn (datetime: *PDDateTime) callconv(.C) u32,

    //2.0
    clearICache: *const fn () callconv(.C) void,

    // 2.4
    setButtonCallback: *const fn (
        cb: PDButtonCallbackFunction,
        user_data: ?*anyopaque,
        queue_size: c_int,
    ) callconv(.C) void,
    setSerialMessageCallback: *const fn (
        callback: *const fn (data: [*]const u8) callconv(.C) void,
    ) callconv(.C) void,
    vaFormatString: *const fn (
        out_str: *[*:0]u8,
        fmt: [*:0]const u8,
        args: VaList,
    ) callconv(.C) c_int,
    parseString: *const fn (
        str: [*:0]const u8,
        format: [*:0]const u8,
        ...,
    ) callconv(.C) c_int,

    //NOTE(Daniel Bokser): std.builtin.VaList is not available when targeting Playdate hardware,
    //      so we need to directly include it
    const VaList = if (is_compiling_for_playdate_hardware() or builtin.os.tag == .windows)
        @cImport({
            @cInclude("stdarg.h");
        }).va_list
    else
        //NOTE(Daniel Bokser):
        //  We must use std.builtin.VaList when building for the Linux simulator.
        //  Using stdarg.h results in a compiler error otherwise.
        std.builtin.VaList;
};

////////LCD and Graphics///////////////////////
pub const LCD_COLUMNS = 400;
pub const LCD_ROWS = 240;
pub const LCD_ROWSIZE = 52;
pub const LCD_SCREEN_RECT = LCDRect.make(0, 0, LCD_COLUMNS, LCD_ROWS);

pub const LCDBitmap = opaque {};
pub const LCDVideoPlayer = opaque {};
pub const PlaydateVideo = extern struct {
    loadVideo: *const fn (path: [*:0]const u8) callconv(.C) ?*LCDVideoPlayer,
    freePlayer: *const fn (p: *LCDVideoPlayer) callconv(.C) void,
    setContext: *const fn (p: *LCDVideoPlayer, context: *LCDBitmap) callconv(.C) c_int,
    useScreenContext: *const fn (p: *LCDVideoPlayer) callconv(.C) void,
    renderFrame: *const fn (p: *LCDVideoPlayer, n: c_int) callconv(.C) c_int,
    getError: *const fn (p: *LCDVideoPlayer) callconv(.C) [*:0]const u8,
    getInfo: *const fn (
        p: *LCDVideoPlayer,
        width: ?*c_int,
        height: ?*c_int,
        frame_rate: ?*f32,
        frame_count: ?*c_int,
        current_frame: ?*c_int,
    ) callconv(.C) void,
    getContext: *const fn (p: *LCDVideoPlayer) callconv(.C) ?*LCDBitmap,
};

/// 8x8 pattern: 8 rows image data, 8 rows mask
pub const LCDPattern = [16]u8;
pub const LCDSolidColor = enum(c_int) {
    black,
    white,
    clear,
    xor,
};
pub const LCDColor = packed union {
    solid: LCDSolidColor,
    pattern: *LCDPattern,

    comptime {
        assert(@sizeOf(LCDColor) == @sizeOf(usize));
    }
};
pub const LCDBitmapDrawMode = enum(c_int) {
    copy,
    white_transparent,
    black_transparent,
    fill_white,
    fill_black,
    xor,
    neg_xor,
    inverted,
};
pub const LCDLineCapStyle = enum(c_int) {
    butt,
    square,
    round,
};

pub const LCDFontLanguage = PDLanguage;

pub const LCDBitmapFlip = enum(c_int) {
    unflipped,
    flipped_x,
    flipped_y,
    flipped_xy,
};

pub const LCDPolygonFillRule = enum(c_int) {
    non_zero,
    even_odd,
};

pub const PDTextWrappingMode = enum(c_int) {
    clip,
    character,
    word,
};

pub const PDTextAlignment = enum(c_int) {
    left,
    center,
    right,
};

pub const LCDBitmapTable = opaque {};
pub const LCDFont = opaque {};
pub const LCDFontPage = opaque {};
pub const LCDFontGlyph = opaque {};
pub const LCDFontData = opaque {};
pub const LCDRect = extern struct {
    left: c_int,
    /// exclusive
    right: c_int,
    top: c_int,
    /// exclusive
    bottom: c_int,

    pub inline fn make(x: c_int, y: c_int, width: c_int, height: c_int) LCDRect {
        assert(width >= 0);
        assert(height >= 0);
        return .{
            .left = x,
            .right = x + width,
            .top = y,
            .bottom = y + height,
        };
    }

    pub inline fn translate(r: LCDRect, dx: c_int, dy: c_int) LCDRect {
        return .{
            .left = r.left + dx,
            .right = r.right + dx,
            .top = r.top + dy,
            .bottom = r.bottom + dy,
        };
    }
};

pub const PlaydateGraphics = extern struct {
    video: *const PlaydateVideo,
    // Drawing Functions
    clear: *const fn (color: LCDColor) callconv(.C) void,
    setBackgroundColor: *const fn (color: LCDSolidColor) callconv(.C) void,
    /// Deprecated in favor of setStencilImage, which adds a "tile" flag.
    /// Pass NULL to clear the stencil.
    setStencil: *const fn (stencil: ?*LCDBitmap) callconv(.C) void,
    setDrawMode: *const fn (mode: LCDBitmapDrawMode) callconv(.C) void,
    setDrawOffset: *const fn (dx: c_int, dy: c_int) callconv(.C) void,
    setClipRect: *const fn (x: c_int, y: c_int, width: c_int, height: c_int) callconv(.C) void,
    clearClipRect: *const fn () callconv(.C) void,
    setLineCapStyle: *const fn (endCapStyle: LCDLineCapStyle) callconv(.C) void,
    setFont: *const fn (font: *LCDFont) callconv(.C) void,
    setTextTracking: *const fn (tracking: c_int) callconv(.C) void,
    /// If target is NULL, drawing functions will use the display framebuffer.
    pushContext: *const fn (target: ?*LCDBitmap) callconv(.C) void,
    popContext: *const fn () callconv(.C) void,

    drawBitmap: *const fn (
        bitmap: *LCDBitmap,
        x: c_int,
        y: c_int,
        flip: LCDBitmapFlip,
    ) callconv(.C) void,
    tileBitmap: *const fn (
        bitmap: *LCDBitmap,
        x: c_int,
        y: c_int,
        width: c_int,
        height: c_int,
        flip: LCDBitmapFlip,
    ) callconv(.C) void,
    drawLine: *const fn (
        x1: c_int,
        y1: c_int,
        x2: c_int,
        y2: c_int,
        width: c_int,
        color: LCDColor,
    ) callconv(.C) void,
    fillTriangle: *const fn (
        x1: c_int,
        y1: c_int,
        x2: c_int,
        y2: c_int,
        x3: c_int,
        y3: c_int,
        color: LCDColor,
    ) callconv(.C) void,
    drawRect: *const fn (
        x: c_int,
        y: c_int,
        width: c_int,
        height: c_int,
        color: LCDColor,
    ) callconv(.C) void,
    fillRect: *const fn (
        x: c_int,
        y: c_int,
        width: c_int,
        height: c_int,
        color: LCDColor,
    ) callconv(.C) void,
    drawEllipse: *const fn (
        x: c_int,
        y: c_int,
        width: c_int,
        height: c_int,
        lineWidth: c_int,
        startAngle: f32,
        endAngle: f32,
        color: LCDColor,
    ) callconv(.C) void,
    fillEllipse: *const fn (
        x: c_int,
        y: c_int,
        width: c_int,
        height: c_int,
        startAngle: f32,
        endAngle: f32,
        color: LCDColor,
    ) callconv(.C) void,
    drawScaledBitmap: *const fn (
        bitmap: *LCDBitmap,
        x: c_int,
        y: c_int,
        xscale: f32,
        yscale: f32,
    ) callconv(.C) void,
    drawText: *const fn (
        text: *const anyopaque,
        len: usize,
        encoding: PDStringEncoding,
        x: c_int,
        y: c_int,
    ) callconv(.C) c_int,

    // LCDBitmap
    newBitmap: *const fn (width: c_int, height: c_int, color: LCDColor) callconv(.C) ?*LCDBitmap,
    freeBitmap: *const fn (bitmap: *LCDBitmap) callconv(.C) void,
    loadBitmap: *const fn (path: [*:0]const u8, outerr: ?*[*:0]const u8) callconv(.C) ?*LCDBitmap,
    copyBitmap: *const fn (bitmap: ?*LCDBitmap) callconv(.C) ?*LCDBitmap,
    loadIntoBitmap: *const fn (
        path: [*:0]const u8,
        bitmap: *LCDBitmap,
        outerr: ?*[*:0]const u8,
    ) callconv(.C) void,
    getBitmapData: *const fn (
        bitmap: *LCDBitmap,
        width: ?*c_int,
        height: ?*c_int,
        rowbytes: ?*c_int,
        mask: ?*?[*]u8,
        data: ?*[*]u8,
    ) callconv(.C) void,
    clearBitmap: *const fn (bitmap: *LCDBitmap, bgcolor: LCDColor) callconv(.C) void,
    rotatedBitmap: *const fn (
        bitmap: *LCDBitmap,
        rotation: f32,
        xscale: f32,
        yscale: f32,
        allocated_size: ?*c_int,
    ) callconv(.C) ?*LCDBitmap,

    // LCDBitmapTable
    newBitmapTable: *const fn (count: c_int, width: c_int, height: c_int) callconv(.C) ?*LCDBitmapTable,
    freeBitmapTable: *const fn (table: *LCDBitmapTable) callconv(.C) void,
    loadBitmapTable: *const fn (
        path: [*:0]const u8,
        outerr: ?*[*:0]const u8,
    ) callconv(.C) ?*LCDBitmapTable,
    loadIntoBitmapTable: *const fn (
        path: [*:0]const u8,
        table: *LCDBitmapTable,
        outerr: ?*[*:0]const u8,
    ) callconv(.C) void,
    /// Returns NULL if idx is out of bounds.
    getTableBitmap: *const fn (table: *LCDBitmapTable, idx: c_int) callconv(.C) ?*LCDBitmap,

    // LCDFont
    loadFont: *const fn (path: [*:0]const u8, outErr: ?*[*:0]const u8) callconv(.C) ?*LCDFont,
    getFontPage: *const fn (font: *LCDFont, c: u32) callconv(.C) ?*LCDFontPage,
    getPageGlyph: *const fn (
        page: *LCDFontPage,
        c: u32,
        bitmap: ?**LCDBitmap,
        advance: ?*c_int,
    ) callconv(.C) ?*LCDFontGlyph,
    getGlyphKerning: *const fn (glyph: *LCDFontGlyph, glyphcode: u32, nextcode: u32) callconv(.C) c_int,
    getTextWidth: *const fn (
        font: *LCDFont,
        text: *const anyopaque,
        len: usize,
        encoding: PDStringEncoding,
        tracking: c_int,
    ) callconv(.C) c_int,

    // raw framebuffer access
    /// row stride == LCD_ROWSIZE
    getFrame: *const fn () callconv(.C) [*]u8,
    /// row stride == LCD_ROWSIZE
    getDisplayFrame: *const fn () callconv(.C) [*]u8,
    /// valid in simulator only, function is null on device
    getDebugBitmap: ?*const fn () callconv(.C) ?*LCDBitmap,
    copyFrameBufferBitmap: *const fn () callconv(.C) ?*LCDBitmap,
    markUpdatedRows: *const fn (start: c_int, end: c_int) callconv(.C) void,
    display: *const fn () callconv(.C) void,

    // misc util.
    setColorToPattern: *const fn (
        color: *LCDColor,
        bitmap: *LCDBitmap,
        x: c_int,
        y: c_int,
    ) callconv(.C) void,
    checkMaskCollision: *const fn (
        bitmap1: *LCDBitmap,
        x1: c_int,
        y1: c_int,
        flip1: LCDBitmapFlip,
        bitmap2: *LCDBitmap,
        x2: c_int,
        y2: c_int,
        flip2: LCDBitmapFlip,
        rect: LCDRect,
    ) callconv(.C) c_int,

    // 1.1
    setScreenClipRect: *const fn (x: c_int, y: c_int, width: c_int, height: c_int) callconv(.C) void,

    // 1.1.1
    fillPolygon: *const fn (
        nPoints: c_int,
        /// Array of 2*nPoints ints containing alternating x and y values
        coords: [*]c_int,
        color: LCDColor,
        fillRule: LCDPolygonFillRule,
    ) callconv(.C) void,
    getFontHeight: *const fn (font: *LCDFont) callconv(.C) u8,

    // 1.7
    /// The display owns this bitmap - do not free it!
    getDisplayBufferBitmap: *const fn () callconv(.C) *LCDBitmap,
    drawRotatedBitmap: *const fn (
        bitmap: *LCDBitmap,
        x: c_int,
        y: c_int,
        rotation: f32,
        centerx: f32,
        centery: f32,
        xscale: f32,
        yscale: f32,
    ) callconv(.C) void,
    setTextLeading: *const fn (lineHeightAdustment: c_int) callconv(.C) void,

    // 1.8
    setBitmapMask: *const fn (bitmap: *LCDBitmap, mask: *LCDBitmap) callconv(.C) c_int,
    /// Returns NULL if the bitmap does not have a mask layer. Caller owns the returned bitmap.
    getBitmapMask: *const fn (bitmap: *LCDBitmap) callconv(.C) ?*LCDBitmap,

    // 1.10
    /// To clear the stencil, call `setStencil(null)`
    setStencilImage: *const fn (stencil: *LCDBitmap, tile: c_int) callconv(.C) void,

    // 1.12
    makeFontFromData: *const fn (data: *LCDFontData, wide: c_int) callconv(.C) ?*LCDFont,

    // 2.1
    getTextTracking: *const fn () callconv(.C) c_int,

    // 2.5
    setPixel: *const fn (x: c_int, y: c_int, c: LCDColor) callconv(.C) void,
    getBitmapPixel: *const fn (bitmap: *LCDBitmap, x: c_int, y: c_int) callconv(.C) LCDSolidColor,
    getBitmapTableInfo: *const fn (
        table: *LCDBitmapTable,
        count: ?*c_int,
        width: ?*c_int,
    ) callconv(.C) void,

    // 2.6
    drawTextInRect: *const fn (
        text: *const anyopaque,
        len: usize,
        encoding: PDStringEncoding,
        x: c_int,
        y: c_int,
        width: c_int,
        height: c_int,
        wrap: PDTextWrappingMode,
        @"align": PDTextAlignment,
    ) callconv(.C) void,
};
pub const PlaydateDisplay = struct {
    getWidth: *const fn () callconv(.C) c_int,
    getHeight: *const fn () callconv(.C) c_int,

    setRefreshRate: *const fn (rate: f32) callconv(.C) void,

    setInverted: *const fn (flag: c_int) callconv(.C) void,
    setScale: *const fn (s: c_uint) callconv(.C) void,
    setMosaic: *const fn (x: c_uint, y: c_uint) callconv(.C) void,
    setFlipped: *const fn (x: c_uint, y: c_uint) callconv(.C) void,
    setOffset: *const fn (x: c_uint, y: c_uint) callconv(.C) void,
};

//////File System/////
pub const SDFile = opaque {};

pub const FileOptions = packed struct(c_int) {
    read: bool,
    read_data: bool,
    modify: enum(u2) { write, append }, // silly implementation leakage
    _padding: u28,
};

pub const FileWhence = enum(c_int) {
    set = 0,
    current = 1,
    end = 2,
};

const FileStat = extern struct {
    isdir: c_int,
    size: c_uint,
    m_year: c_int,
    m_month: c_int,
    m_day: c_int,
    m_hour: c_int,
    m_minute: c_int,
    m_second: c_int,
};

const PlaydateFile = extern struct {
    geterr: *const fn () callconv(.C) [*:0]const u8,

    listfiles: *const fn (
        path: [*:0]const u8,
        callback: *const fn (path: [*:0]const u8, userdata: ?*anyopaque) callconv(.C) void,
        userdata: ?*anyopaque,
        showhidden: c_int,
    ) callconv(.C) c_int,
    stat: *const fn (path: [*:0]const u8, stat: ?*FileStat) callconv(.C) c_int,
    mkdir: *const fn (path: [*:0]const u8) callconv(.C) c_int,
    unlink: *const fn (name: [*:0]const u8, recursive: c_int) callconv(.C) c_int,
    rename: *const fn (from: [*:0]const u8, to: [*:0]const u8) callconv(.C) c_int,

    /// The returned file handle should be closed when no longer in use.
    open: *const fn (name: [*:0]const u8, mode: FileOptions) callconv(.C) ?*SDFile,
    close: *const fn (file: *SDFile) callconv(.C) c_int,
    read: *const fn (file: *SDFile, buf: *anyopaque, len: c_uint) callconv(.C) c_int,
    write: *const fn (file: *SDFile, buf: *const anyopaque, len: c_uint) callconv(.C) c_int,
    flush: *const fn (file: *SDFile) callconv(.C) c_int,
    tell: *const fn (file: *SDFile) callconv(.C) c_int,
    seek: *const fn (file: *SDFile, pos: c_int, whence: FileWhence) callconv(.C) c_int,
};

/////////Audio//////////////
const MicSource = enum(c_int) {
    auto_detect = 0,
    internal = 1,
    headset = 2,
};
pub const PlaydateSound = extern struct {
    channel: *const PlaydateSoundChannel,
    fileplayer: *const PlaydateSoundFileplayer,
    sample: *const PlaydateSoundSample,
    sampleplayer: *const PlaydateSoundSampleplayer,
    synth: *const PlaydateSoundSynth,
    sequence: *const PlaydateSoundSequence,
    effect: *const PlaydateSoundEffect,
    lfo: *const PlaydateSoundLFO,
    envelope: *const PlaydateSoundEnvelope,
    source: *const PlaydateSoundSource,
    controlsignal: *const PlaydateControlSignal,
    track: *const PlaydateSoundTrack,
    instrument: *const PlaydateSoundInstrument,

    getCurrentTime: *const fn () callconv(.C) u32,
    addSource: *const fn (
        callback: AudioSourceFunction,
        context: ?*anyopaque,
        stereo: c_int,
    ) callconv(.C) ?*SoundSource,

    getDefaultChannel: *const fn () callconv(.C) *SoundChannel,

    addChannel: *const fn (channel: *SoundChannel) callconv(.C) void,
    removeChannel: *const fn (channel: *SoundChannel) callconv(.C) void,

    setMicCallback: *const fn (
        callback: RecordCallback,
        context: ?*anyopaque,
        source: MicSource,
    ) callconv(.C) void,
    getHeadphoneState: *const fn (
        headphone: ?*c_int,
        headsetmic: ?*c_int,
        changeCallback: ?*const fn (headphone: c_int, mic: c_int) callconv(.C) void,
    ) callconv(.C) void,
    setOutputsActive: *const fn (headphone: c_int, mic: c_int) callconv(.C) void,

    // 1.5
    removeSource: *const fn (*SoundSource) callconv(.C) void,

    // 1.12
    signal: *const PlaydateSoundSignal,

    // 2.2
    getError: *const fn () callconv(.C) [*:0]const u8,
};

/// buffer will be filled with recorded mono data.
/// The function should return 1 to continue recording, 0 to stop recording.
pub const RecordCallback = *const fn (
    context: ?*anyopaque,
    buffer: [*]i16,
    length: c_int,
) callconv(.C) c_int;
/// len is # of samples in each buffer, function should return 1 if it produced output
pub const AudioSourceFunction = *const fn (
    context: ?*anyopaque,
    left: [*]i16,
    right: [*]i16,
    len: c_int,
) callconv(.C) c_int;
pub const SndCallbackProc = *const fn (
    c: *SoundSource,
    userdata: ?*anyopaque,
) callconv(.C) void;

/// Contains SoundSources and SoundEffects
pub const SoundChannel = opaque {};
/// SoundSource is the "parent type" for FilePlayer, SamplePlayer, PDSynth, and DelayLineTap.
/// You can safely cast those types to a *SoundSource.
pub const SoundSource = opaque {};

/// SoundEffect is the "parent type" of the sound effect types TwoPoleFilter, OnePoleFilter, BitCrusher, RingModulator, Overdrive, and DelayLine.
/// You can safely cast those types to a *SoundEffect.
pub const SoundEffect = opaque {};
/// a PDSynthSignalValue represents a signal that can be used as an input to a modulator.
pub const PDSynthSignalValue = opaque {};

pub const PlaydateSoundChannel = extern struct {
    newChannel: *const fn () callconv(.C) ?*SoundChannel,
    freeChannel: *const fn (channel: *SoundChannel) callconv(.C) void,
    addSource: *const fn (channel: *SoundChannel, source: *SoundSource) callconv(.C) c_int,
    removeSource: *const fn (channel: *SoundChannel, source: *SoundSource) callconv(.C) c_int,
    /// Caller owns the returned SoundSource and should free it with `realloc` when no longer in use.
    addCallbackSource: *const fn (
        channel: *SoundChannel,
        callback: AudioSourceFunction,
        context: ?*anyopaque,
        stereo: c_int,
    ) callconv(.C) ?*SoundSource,
    addEffect: *const fn (channel: *SoundChannel, effect: *SoundEffect) callconv(.C) void,
    removeEffect: *const fn (channel: *SoundChannel, effect: *SoundEffect) callconv(.C) void,
    setVolume: *const fn (channel: *SoundChannel, volume: f32) callconv(.C) void,
    getVolume: *const fn (channel: *SoundChannel) callconv(.C) f32,
    setVolumeModulator: *const fn (
        channel: *SoundChannel,
        mod: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getVolumeModulator: *const fn (channel: *SoundChannel) callconv(.C) ?*PDSynthSignalValue,
    setPan: *const fn (channel: *SoundChannel, pan: f32) callconv(.C) void,
    setPanModulator: *const fn (
        channel: *SoundChannel,
        mod: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getPanModulator: *const fn (channel: *SoundChannel) callconv(.C) ?*PDSynthSignalValue,
    getDryLevelSignal: *const fn (channe: *SoundChannel) callconv(.C) ?*PDSynthSignalValue,
    getWetLevelSignal: *const fn (channel: *SoundChannel) callconv(.C) ?*PDSynthSignalValue,
};

pub const FilePlayer = SoundSource;
pub const PlaydateSoundFileplayer = extern struct {
    newPlayer: *const fn () callconv(.C) ?*FilePlayer,
    freePlayer: *const fn (player: *FilePlayer) callconv(.C) void,
    loadIntoPlayer: *const fn (player: *FilePlayer, path: [*:0]const u8) callconv(.C) c_int,
    setBufferLength: *const fn (player: *FilePlayer, bufferLen: f32) callconv(.C) void,
    play: *const fn (player: *FilePlayer, repeat: c_int) callconv(.C) c_int,
    isPlaying: *const fn (player: *FilePlayer) callconv(.C) c_int,
    pause: *const fn (player: *FilePlayer) callconv(.C) void,
    stop: *const fn (player: *FilePlayer) callconv(.C) void,
    setVolume: *const fn (player: *FilePlayer, left: f32, right: f32) callconv(.C) void,
    getVolume: *const fn (player: *FilePlayer, left: ?*f32, right: ?*f32) callconv(.C) void,
    getLength: *const fn (player: *FilePlayer) callconv(.C) f32,
    setOffset: *const fn (player: *FilePlayer, offset: f32) callconv(.C) void,
    setRate: *const fn (player: *FilePlayer, rate: f32) callconv(.C) void,
    setLoopRange: *const fn (player: *FilePlayer, start: f32, end: f32) callconv(.C) void,
    didUnderrun: *const fn (player: *FilePlayer) callconv(.C) c_int,
    setFinishCallback: *const fn (
        player: *FilePlayer,
        callback: ?SndCallbackProc,
        userdata: ?*anyopaque,
    ) callconv(.C) void,
    setLoopCallback: *const fn (
        player: *FilePlayer,
        callback: ?SndCallbackProc,
        userdata: ?*anyopaque,
    ) callconv(.C) void,
    getOffset: *const fn (player: *FilePlayer) callconv(.C) f32,
    getRate: *const fn (player: *FilePlayer) callconv(.C) f32,
    setStopOnUnderrun: *const fn (player: *FilePlayer, flag: c_int) callconv(.C) void,
    fadeVolume: *const fn (
        player: *FilePlayer,
        left: f32,
        right: f32,
        len: i32,
        finishCallback: ?SndCallbackProc,
        userdata: ?*anyopaque,
    ) callconv(.C) void,
    setMP3StreamSource: *const fn (
        player: *FilePlayer,
        dataSource: *const fn (data: [*]u8, bytes: c_int, userdata: ?*anyopaque) callconv(.C) c_int,
        userdata: ?*anyopaque,
        bufferLen: f32,
    ) callconv(.C) void,
};

pub const AudioSample = opaque {};
pub const SamplePlayer = SoundSource;

pub const SoundFormat = enum(c_uint) {
    @"8bit_mono" = 0,
    @"8bit_stereo" = 1,
    @"16bit_mono" = 2,
    @"16bit_stereo" = 3,
    adpcm_mono = 4,
    adpcm_stereo = 5,

    pub inline fn isStereo(f: SoundFormat) bool {
        return @intFromEnum(f) & 1;
    }
    pub inline fn is16bit(f: SoundFormat) bool {
        return switch (f) {
            .@"16bit_mono",
            .@"16bit_stereo",
            .adpcm_mono,
            .adpcm_stereo,
            => true,
            else => false,
        };
    }
    pub inline fn bytesPerFrame(fmt: SoundFormat) u32 {
        return (if (fmt.isStereo()) 2 else 1) * (if (fmt.is16bit()) 2 else 1);
    }
};

pub const PlaydateSoundSample = extern struct {
    newSampleBuffer: *const fn (byteCount: c_int) callconv(.C) ?*AudioSample,
    loadIntoSample: *const fn (sample: *AudioSample, path: [*:0]const u8) callconv(.C) c_int,
    load: *const fn (path: [*:0]const u8) callconv(.C) ?*AudioSample,
    newSampleFromData: *const fn (
        data: [*]u8,
        format: SoundFormat,
        sampleRate: u32,
        byteCount: c_int,
        shouldFreeData: c_int,
    ) callconv(.C) ?*AudioSample,
    getData: *const fn (
        sample: *AudioSample,
        data: ?*[*]u8,
        format: ?*SoundFormat,
        sampleRate: ?*u32,
        byteLength: ?*u32,
    ) callconv(.C) void,
    freeSample: *const fn (sample: *AudioSample) callconv(.C) void,
    getLength: *const fn (sample: *AudioSample) callconv(.C) f32,

    // 2.4
    decompress: *const fn (sample: *AudioSample) callconv(.C) c_int,
};

pub const PlaydateSoundSampleplayer = extern struct {
    newPlayer: *const fn () callconv(.C) ?*SamplePlayer,
    freePlayer: *const fn (*SamplePlayer) callconv(.C) void,
    setSample: *const fn (player: *SamplePlayer, sample: ?*AudioSample) callconv(.C) void,
    play: *const fn (player: *SamplePlayer, repeat: c_int, rate: f32) callconv(.C) c_int,
    isPlaying: *const fn (player: *SamplePlayer) callconv(.C) c_int,
    stop: *const fn (player: *SamplePlayer) callconv(.C) void,
    setVolume: *const fn (player: *SamplePlayer, left: f32, right: f32) callconv(.C) void,
    getVolume: *const fn (player: *SamplePlayer, left: ?*f32, right: ?*f32) callconv(.C) void,
    getLength: *const fn (player: *SamplePlayer) callconv(.C) f32,
    setOffset: *const fn (player: *SamplePlayer, offset: f32) callconv(.C) void,
    setRate: *const fn (player: *SamplePlayer, rate: f32) callconv(.C) void,
    setPlayRange: *const fn (
        player: *SamplePlayer,
        start: c_int,
        end: c_int,
    ) callconv(.C) void,
    setFinishCallback: *const fn (
        player: *SamplePlayer,
        callback: ?SndCallbackProc,
        userdata: ?*anyopaque,
    ) callconv(.C) void,
    setLoopCallback: *const fn (
        player: *SamplePlayer,
        callback: ?SndCallbackProc,
        userdata: ?*anyopaque,
    ) callconv(.C) void,
    getOffset: *const fn (player: *SamplePlayer) callconv(.C) f32,
    getRate: *const fn (player: *SamplePlayer) callconv(.C) f32,
    setPaused: *const fn (player: *SamplePlayer, flag: c_int) callconv(.C) void,
};

pub const PDSynth = SoundSource;
pub const SoundWaveform = enum(c_uint) {
    square = 0,
    triangle = 1,
    sine = 2,
    noise = 3,
    sawtooth = 4,
    po_phase = 5,
    po_digital = 6,
    po_vosim = 7,
};
pub const NOTE_C4 = 60.0;
pub const MIDINote = f32;
pub inline fn pd_noteToFrequency(n: MIDINote) f32 {
    return 440 * std.math.pow(f32, 2, (n - 69) / 12.0);
}
pub inline fn pd_frequencyToNote(f: f32) MIDINote {
    return 12 * std.math.log(f32, 2, f) - 36.376316562;
}

/// Generator render callback
/// Samples are in Q8.24 format. left is either the left channel or the single mono channel,
/// right is non-NULL only if the stereo flag was set in the setGenerator() call.
/// nsamples is at most 256 but may be shorter.
/// rate is Q0.32 per-frame phase step, drate is per-frame rate step (i.e., do rate += drate every frame).
/// return value is the number of sample frames rendered.
pub const SynthRenderFunc = *const fn (
    userdata: ?*anyopaque,
    left: [*]i32,
    right: [*]i32,
    nsamples: c_int,
    rate: u32,
    drate: i32,
) callconv(.C) c_int;

// generator event callbacks

/// len == -1 if indefinite
pub const SynthNoteOnFunc = *const fn (
    userdata: ?*anyopaque,
    note: MIDINote,
    velocity: f32,
    len: f32,
) callconv(.C) void;

pub const SynthReleaseFunc = *const fn (
    userdata: ?*anyopaque,
    stop: c_int,
) callconv(.C) void;
pub const SynthSetParameterFunc = *const fn (
    userdata: ?*anyopaque,
    parameter: c_int,
    value: f32,
) callconv(.C) c_int;
pub const SynthDeallocFunc = *const fn (userdata: ?*anyopaque) callconv(.C) void;
pub const SynthCopyUserdata = *const fn (userdata: ?*anyopaque) callconv(.C) ?*anyopaque;

pub const PlaydateSoundSynth = extern struct {
    newSynth: *const fn () callconv(.C) ?*PDSynth,
    freeSynth: *const fn (synth: *PDSynth) callconv(.C) void,

    setWaveform: *const fn (synth: *PDSynth, wave: SoundWaveform) callconv(.C) void,
    setGenerator_deprecated: *const fn (
        synth: *PDSynth,
        stereo: c_int,
        render: SynthRenderFunc,
        note_on: ?SynthNoteOnFunc,
        release: ?SynthReleaseFunc,
        set_param: ?SynthSetParameterFunc,
        dealloc: ?SynthDeallocFunc,
        userdata: ?*anyopaque,
    ) callconv(.C) void,
    setSample: *const fn (
        synth: *PDSynth,
        sample: *AudioSample,
        sustain_start: u32,
        sustain_end: u32,
    ) callconv(.C) void,

    setAttackTime: *const fn (synth: *PDSynth, attack: f32) callconv(.C) void,
    setDecayTime: *const fn (synth: *PDSynth, decay: f32) callconv(.C) void,
    setSustainLevel: *const fn (synth: *PDSynth, sustain: f32) callconv(.C) void,
    setReleaseTime: *const fn (synth: *PDSynth, release: f32) callconv(.C) void,

    setTranspose: *const fn (synth: *PDSynth, half_steps: f32) callconv(.C) void,

    setFrequencyModulator: *const fn (
        synth: *PDSynth,
        mod: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getFrequencyModulator: *const fn (synth: *PDSynth) callconv(.C) ?*PDSynthSignalValue,
    setAmplitudeModulator: *const fn (
        synth: *PDSynth,
        mod: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getAmplitudeModulator: *const fn (synth: *PDSynth) callconv(.C) ?*PDSynthSignalValue,

    getParameterCount: *const fn (synth: *PDSynth) callconv(.C) c_int,
    setParameter: *const fn (synth: *PDSynth, parameter: c_int, value: f32) callconv(.C) c_int,
    setParameterModulator: *const fn (
        synth: *PDSynth,
        parameter: c_int,
        mod: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getParameterModulator: *const fn (
        synth: *PDSynth,
        parameter: c_int,
    ) callconv(.C) ?*PDSynthSignalValue,

    playNote: *const fn (
        synth: *PDSynth,
        freq: f32,
        vel: f32,
        len: f32,
        when: u32,
    ) callconv(.C) void,
    playMIDINote: *const fn (
        synth: *PDSynth,
        note: MIDINote,
        vel: f32,
        len: f32,
        when: u32,
    ) callconv(.C) void,
    noteOff: *const fn (synth: *PDSynth, when: u32) callconv(.C) void,
    stop: *const fn (synth: *PDSynth) callconv(.C) void,

    setVolume: *const fn (synth: *PDSynth, left: f32, right: f32) callconv(.C) void,
    getVolume: *const fn (synth: *PDSynth, left: ?*f32, right: ?*f32) callconv(.C) void,

    isPlaying: *const fn (synth: *PDSynth) callconv(.C) c_int,

    // 1.13
    /// synth keeps ownership - don't free this!
    getEnvelope: *const fn (synth: *PDSynth) callconv(.C) *PDSynthEnvelope,

    // 2.2
    setWavetable: *const fn (
        synth: *PDSynth,
        sample: *AudioSample,
        log2size: c_int,
        columns: c_int,
        rows: c_int,
    ) callconv(.C) c_int,

    // 2.4
    setGenerator: *const fn (
        synth: *PDSynth,
        stereo: c_int,
        render: SynthRenderFunc,
        noteOn: SynthNoteOnFunc,
        release: SynthReleaseFunc,
        setparam: SynthSetParameterFunc,
        dealloc: SynthDeallocFunc,
        copyUserdata: SynthCopyUserdata,
        userdata: ?*anyopaque,
    ) callconv(.C) void,
    copy: *const fn (synth: *PDSynth) callconv(.C) ?*PDSynth,

    // 2.6
    clearEnvelope: *const fn (synth: *PDSynth) callconv(.C) void,
};

/// a SequenceTrack contains notes for an instrument to play
pub const SequenceTrack = opaque {};
/// a SoundSequence is a collection of tracks, along with control info like tempo and loops
pub const SoundSequence = opaque {};
pub const SequenceFinishedCallback = *const fn (
    seq: *SoundSequence,
    userdata: ?*anyopaque,
) callconv(.C) void;

pub const PlaydateSoundSequence = extern struct {
    newSequence: *const fn () callconv(.C) ?*SoundSequence,
    freeSequence: *const fn (sequence: *SoundSequence) callconv(.C) void,

    loadMidiFile: *const fn (seq: *SoundSequence, path: [*:0]const u8) callconv(.C) c_int,
    getTime: *const fn (seq: *SoundSequence) callconv(.C) u32,
    setTime: *const fn (seq: *SoundSequence, time: u32) callconv(.C) void,
    setLoops: *const fn (
        seq: *SoundSequence,
        loop_start: c_int,
        loop_end: c_int,
        loops: c_int,
    ) callconv(.C) void,
    getTempo_deprecated: *const fn (seq: *SoundSequence) callconv(.C) c_int,
    setTempo: *const fn (seq: *SoundSequence, stepsPerSecond: c_int) callconv(.C) void,
    getTrackCount: *const fn (seq: *SoundSequence) callconv(.C) c_int,
    addTrack: *const fn (seq: *SoundSequence) callconv(.C) ?*SequenceTrack,
    getTrackAtIndex: *const fn (
        seq: *SoundSequence,
        track: c_uint,
    ) callconv(.C) ?*SequenceTrack,
    setTrackAtIndex: *const fn (
        seq: *SoundSequence,
        track: ?*SequenceTrack,
        idx: c_uint,
    ) callconv(.C) void,
    allNotesOff: *const fn (seq: *SoundSequence) callconv(.C) void,

    // 1.1
    isPlaying: *const fn (seq: *SoundSequence) callconv(.C) c_int,
    getLength: *const fn (seq: *SoundSequence) callconv(.C) u32,
    play: *const fn (
        seq: *SoundSequence,
        finishCallback: ?SequenceFinishedCallback,
        userdata: ?*anyopaque,
    ) callconv(.C) void,
    stop: *const fn (seq: *SoundSequence) callconv(.C) void,
    getCurrentStep: *const fn (seq: *SoundSequence, timeOffset: ?*c_int) callconv(.C) c_int,
    setCurrentStep: *const fn (seq: *SoundSequence, step: c_int, timeOffset: c_int, playNotes: c_int) callconv(.C) void,

    // 2.5
    getTempo: *const fn (seq: *SoundSequence) callconv(.C) f32,
};

/// samples are in signed q8.24 format
pub const EffectProc = *const fn (
    e: *SoundEffect,
    left: [*]i32,
    right: [*]i32,
    nsamples: c_int,
    buf_active: c_int,
) callconv(.C) c_int;

pub const PlaydateSoundEffect = extern struct {
    newEffect: *const fn (
        proc: *const EffectProc,
        userdata: ?*anyopaque,
    ) callconv(.C) ?*SoundEffect,
    freeEffect: *const fn (effect: *SoundEffect) callconv(.C) void,

    setMix: *const fn (effect: *SoundEffect, level: f32) callconv(.C) void,
    setMixModulator: *const fn (
        effect: *SoundEffect,
        signal: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getMixModulator: *const fn (effect: *SoundEffect) callconv(.C) ?*PDSynthSignalValue,

    setUserdata: *const fn (effect: *SoundEffect, userdata: ?*anyopaque) callconv(.C) void,
    getUserdata: *const fn (effect: *SoundEffect) callconv(.C) ?*anyopaque,

    twopolefilter: *const PlaydateSoundEffectTwopolefilter,
    onepolefilter: *const PlaydateSoundEffectOnepolefilter,
    bitcrusher: *const PlaydateSoundEffectBitcrusher,
    ringmodulator: *const PlaydateSoundEffectRingmodulator,
    delayline: *const PlaydateSoundEffectDelayline,
    overdrive: *const PlaydateSoundEffectOverdrive,
};
pub const LFOType = enum(c_uint) {
    square = 0,
    triangle = 1,
    sine = 2,
    sample_and_hold = 3,
    sawtooth_up = 4,
    sawtooth_down = 5,
    arpeggiator = 6,
    function = 7,
};
pub const PDSynthLFO = opaque {};
pub const PlaydateSoundLFO = extern struct {
    newLFO: *const fn (LFOType) callconv(.C) ?*PDSynthLFO,
    freeLFO: *const fn (lfo: *PDSynthLFO) callconv(.C) void,

    setType: *const fn (lfo: *PDSynthLFO, type: LFOType) callconv(.C) void,
    setRate: *const fn (lfo: *PDSynthLFO, rate: f32) callconv(.C) void,
    setPhase: *const fn (lfo: *PDSynthLFO, phase: f32) callconv(.C) void,
    setCenter: *const fn (lfo: *PDSynthLFO, center: f32) callconv(.C) void,
    setDepth: *const fn (lfo: *PDSynthLFO, depth: f32) callconv(.C) void,
    setArpeggiation: *const fn (
        lfo: *PDSynthLFO,
        nSteps: c_int,
        steps: [*]f32,
    ) callconv(.C) void,
    setFunction: *const fn (
        lfo: *PDSynthLFO,
        lfoFunc: *const fn (lfo: *PDSynthLFO, userdata: ?*anyopaque) callconv(.C) f32,
        userdata: ?*anyopaque,
        interpolate: c_int,
    ) callconv(.C) void,
    setDelay: *const fn (lfo: *PDSynthLFO, holdoff: f32, ramptime: f32) callconv(.C) void,
    setRetrigger: *const fn (lfo: *PDSynthLFO, flag: c_int) callconv(.C) void,

    getValue: *const fn (lfo: *PDSynthLFO) callconv(.C) f32,

    // 1.10
    setGlobal: *const fn (lfo: *PDSynthLFO, global: c_int) callconv(.C) void,
};

pub const PDSynthEnvelope = opaque {};
pub const PlaydateSoundEnvelope = extern struct {
    newEnvelope: *const fn (
        attack: f32,
        decay: f32,
        sustain: f32,
        release: f32,
    ) callconv(.C) ?*PDSynthEnvelope,
    freeEnvelope: *const fn (env: *PDSynthEnvelope) callconv(.C) void,

    setAttack: *const fn (env: *PDSynthEnvelope, attack: f32) callconv(.C) void,
    setDecay: *const fn (env: *PDSynthEnvelope, decay: f32) callconv(.C) void,
    setSustain: *const fn (env: *PDSynthEnvelope, sustain: f32) callconv(.C) void,
    setRelease: *const fn (env: *PDSynthEnvelope, release: f32) callconv(.C) void,

    setLegato: *const fn (env: *PDSynthEnvelope, flag: c_int) callconv(.C) void,
    setRetrigger: *const fn (env: *PDSynthEnvelope, flag: c_int) callconv(.C) void,

    getValue: *const fn (env: *PDSynthEnvelope) callconv(.C) f32,

    // 1.13
    setCurvature: *const fn (env: *PDSynthEnvelope, amount: f32) callconv(.C) void,
    setVelocitySensitivity: *const fn (env: *PDSynthEnvelope, velsens: f32) callconv(.C) void,
    setRateScaling: *const fn (
        env: *PDSynthEnvelope,
        scaling: f32,
        start: MIDINote,
        end: MIDINote,
    ) callconv(.C) void,
};

pub const PlaydateSoundSource = extern struct {
    setVolume: *const fn (c: ?*SoundSource, lvol: f32, rvol: f32) callconv(.C) void,
    getVolume: *const fn (c: ?*SoundSource, outl: ?*f32, outr: ?*f32) callconv(.C) void,
    isPlaying: *const fn (c: ?*SoundSource) callconv(.C) c_int,
    setFinishCallback: *const fn (
        c: ?*SoundSource,
        callback: SndCallbackProc,
        userdata: ?*anyopaque,
    ) callconv(.C) void,
};

/// A ControlSignal is a PDSynthSignal with values specified on a timeline
pub const ControlSignal = opaque {};
pub const PlaydateControlSignal = extern struct {
    newSignal: *const fn () callconv(.C) ?*ControlSignal,
    freeSignal: *const fn (signal: *ControlSignal) callconv(.C) void,
    clearEvents: *const fn (control: *ControlSignal) callconv(.C) void,
    addEvent: *const fn (
        control: *ControlSignal,
        step: c_int,
        value: f32,
        c_int,
    ) callconv(.C) void,
    removeEvent: *const fn (control: *ControlSignal, step: c_int) callconv(.C) void,
    getMIDIControllerNumber: *const fn (control: *ControlSignal) callconv(.C) c_int,
};

pub const PlaydateSoundTrack = extern struct {
    newTrack: *const fn () callconv(.C) ?*SequenceTrack,
    freeTrack: *const fn (track: *SequenceTrack) callconv(.C) void,

    setInstrument: *const fn (
        track: *SequenceTrack,
        inst: ?*PDSynthInstrument,
    ) callconv(.C) void,
    getInstrument: *const fn (track: *SequenceTrack) callconv(.C) ?*PDSynthInstrument,

    addNoteEvent: *const fn (
        track: *SequenceTrack,
        step: u32,
        len: u32,
        note: MIDINote,
        velocity: f32,
    ) callconv(.C) void,
    removeNoteEvent: *const fn (
        track: *SequenceTrack,
        step: u32,
        note: MIDINote,
    ) callconv(.C) void,
    clearNotes: *const fn (track: *SequenceTrack) callconv(.C) void,

    getControlSignalCount: *const fn (track: *SequenceTrack) callconv(.C) c_int,
    getControlSignal: *const fn (
        track: *SequenceTrack,
        idx: c_int,
    ) callconv(.C) ?*ControlSignal,
    clearControlEvents: *const fn (track: *SequenceTrack) callconv(.C) void,

    getPolyphony: *const fn (track: *SequenceTrack) callconv(.C) c_int,
    activeVoiceCount: *const fn (track: *SequenceTrack) callconv(.C) c_int,

    setMuted: *const fn (track: *SequenceTrack, mute: c_int) callconv(.C) void,

    // 1.1
    /// in steps, includes full last note
    getLength: *const fn (track: *SequenceTrack) callconv(.C) u32,
    getIndexForStep: *const fn (track: *SequenceTrack, step: u32) callconv(.C) c_int,
    getNoteAtIndex: *const fn (
        track: *SequenceTrack,
        index: c_int,
        outStep: ?*u32,
        outLen: ?*u32,
        outeNote: ?*MIDINote,
        outVelocity: ?*f32,
    ) callconv(.C) c_int,

    //1.10
    getSignalForController: *const fn (
        track: *SequenceTrack,
        controller: c_int,
        create: c_int,
    ) callconv(.C) ?*ControlSignal,
};

/// a PDSynthInstrument is a bank of voices for playing a sequence track
pub const PDSynthInstrument = SoundSource;
pub const PlaydateSoundInstrument = extern struct {
    newInstrument: *const fn () callconv(.C) ?*PDSynthInstrument,
    freeInstrument: *const fn (inst: *PDSynthInstrument) callconv(.C) void,
    addVoice: *const fn (
        inst: *PDSynthInstrument,
        synth: *PDSynth,
        rangeStart: MIDINote,
        rangeEnd: MIDINote,
        transpose: f32,
    ) callconv(.C) c_int,
    playNote: *const fn (
        inst: *PDSynthInstrument,
        frequency: f32,
        vel: f32,
        len: f32,
        when: u32,
    ) callconv(.C) ?*PDSynth,
    playMIDINote: *const fn (
        inst: *PDSynthInstrument,
        note: MIDINote,
        vel: f32,
        len: f32,
        when: u32,
    ) callconv(.C) ?*PDSynth,
    setPitchBend: *const fn (inst: *PDSynthInstrument, bend: f32) callconv(.C) void,
    setPitchBendRange: *const fn (inst: *PDSynthInstrument, halfSteps: f32) callconv(.C) void,
    setTranspose: *const fn (inst: *PDSynthInstrument, halfSteps: f32) callconv(.C) void,
    noteOff: *const fn (inst: *PDSynthInstrument, note: MIDINote, when: u32) callconv(.C) void,
    allNotesOff: *const fn (inst: *PDSynthInstrument, when: u32) callconv(.C) void,
    setVolume: *const fn (inst: *PDSynthInstrument, left: f32, right: f32) callconv(.C) void,
    getVolume: *const fn (
        inst: *PDSynthInstrument,
        left: ?*f32,
        right: ?*f32,
    ) callconv(.C) void,
    activeVoiceCount: *const fn (inst: *PDSynthInstrument) callconv(.C) c_int,
};

/// Used for "active" signals that change their values automatically. PDSynthLFO and PDSynthEnvelope are subclasses of PDSynthSignal.
pub const PDSynthSignal = opaque {};
pub const SignalStepFunc = *const fn (
    userdata: ?*anyopaque,
    ioframes: *c_int,
    ifval: *f32,
) callconv(.C) f32;
/// len = -1 for indefinite
pub const SignalNoteOnFunc = *const fn (
    userdata: ?*anyopaque,
    note: MIDINote,
    vel: f32,
    len: f32,
) callconv(.C) void;
/// stopped == 0 on note release, and == 1 when note actually stops playing;
/// offset is # of frames into the current cycle.
pub const SignalNoteOffFunc = *const fn (
    userdata: ?*anyopaque,
    stopped: c_int,
    offset: c_int,
) callconv(.C) void;
pub const SignalDeallocFunc = *const fn (userdata: ?*anyopaque) callconv(.C) void;
pub const PlaydateSoundSignal = struct {
    newSignal: *const fn (
        step: SignalStepFunc,
        noteOn: ?SignalNoteOnFunc,
        noteOff: ?SignalNoteOffFunc,
        dealloc: ?SignalDeallocFunc,
        userdata: ?*anyopaque,
    ) callconv(.C) ?*PDSynthSignal,
    freeSignal: *const fn (signal: *PDSynthSignal) callconv(.C) void,
    getValue: *const fn (signal: *PDSynthSignal) callconv(.C) f32,
    setValueScale: *const fn (signal: *PDSynthSignal, scale: f32) callconv(.C) void,
    setValueOffset: *const fn (signal: *PDSynthSignal, offset: f32) callconv(.C) void,

    // 2.6
    newSignalForValue: *const fn (value: *PDSynthSignalValue) *PDSynthSignal,
};

// EFFECTS

// A SoundEffect processes the output of a channel's SoundSources

const TwoPoleFilter = SoundEffect;
const TwoPoleFilterType = enum(c_int) {
    low_pass,
    high_pass,
    band_pass,
    notch,
    peq,
    low_shelf,
    high_shelf,
};
const PlaydateSoundEffectTwopolefilter = extern struct {
    newFilter: *const fn () callconv(.C) ?*TwoPoleFilter,
    freeFilter: *const fn (filter: *TwoPoleFilter) callconv(.C) void,
    setType: *const fn (filter: *TwoPoleFilter, type: TwoPoleFilterType) callconv(.C) void,
    setFrequency: *const fn (filter: *TwoPoleFilter, frequency: f32) callconv(.C) void,
    setFrequencyModulator: *const fn (
        filter: *TwoPoleFilter,
        signal: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getFrequencyModulator: *const fn (filter: *TwoPoleFilter) callconv(.C) ?*PDSynthSignalValue,
    setGain: *const fn (filter: *TwoPoleFilter, f32) callconv(.C) void,
    setResonance: *const fn (filter: *TwoPoleFilter, f32) callconv(.C) void,
    setResonanceModulator: *const fn (
        filter: *TwoPoleFilter,
        signal: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getResonanceModulator: *const fn (filter: *TwoPoleFilter) callconv(.C) ?*PDSynthSignalValue,
};

pub const OnePoleFilter = SoundEffect;
pub const PlaydateSoundEffectOnepolefilter = extern struct {
    newFilter: *const fn () callconv(.C) ?*OnePoleFilter,
    freeFilter: *const fn (filter: *OnePoleFilter) callconv(.C) void,
    setParameter: *const fn (filter: *OnePoleFilter, parameter: f32) callconv(.C) void,
    setParameterModulator: *const fn (
        filter: *OnePoleFilter,
        signal: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getParameterModulator: *const fn (filter: *OnePoleFilter) callconv(.C) ?*PDSynthSignalValue,
};

pub const BitCrusher = SoundEffect;
pub const PlaydateSoundEffectBitcrusher = extern struct {
    newBitCrusher: *const fn () callconv(.C) ?*BitCrusher,
    freeBitCrusher: *const fn (filter: *BitCrusher) callconv(.C) void,
    setAmount: *const fn (filter: *BitCrusher, amount: f32) callconv(.C) void,
    setAmountModulator: *const fn (
        filter: *BitCrusher,
        signal: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getAmountModulator: *const fn (filter: *BitCrusher) callconv(.C) ?*PDSynthSignalValue,
    setUndersampling: *const fn (filter: *BitCrusher, undersampling: f32) callconv(.C) void,
    setUndersampleModulator: *const fn (
        filter: *BitCrusher,
        signal: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getUndersampleModulator: *const fn (filter: *BitCrusher) callconv(.C) ?*PDSynthSignalValue,
};

pub const RingModulator = SoundEffect;
pub const PlaydateSoundEffectRingmodulator = extern struct {
    newRingmod: *const fn () callconv(.C) ?*RingModulator,
    freeRingmod: *const fn (filter: *RingModulator) callconv(.C) void,
    setFrequency: *const fn (filter: *RingModulator, frequency: f32) callconv(.C) void,
    setFrequencyModulator: *const fn (
        filter: *RingModulator,
        signal: ?*PDSynthSignalValue,
    ) callconv(.C) void,
    getFrequencyModulator: *const fn (filter: *RingModulator) callconv(.C) ?*PDSynthSignalValue,
};

pub const DelayLine = SoundEffect;
pub const DelayLineTap = SoundSource;
pub const PlaydateSoundEffectDelayline = extern struct {
    newDelayLine: *const fn (length: c_int, stereo: c_int) callconv(.C) ?*DelayLine,
    freeDelayLine: *const fn (filter: *DelayLine) callconv(.C) void,
    setLength: *const fn (filter: *DelayLine, frames: c_int) callconv(.C) void,
    setFeedback: *const fn (filter: *DelayLine, fb: f32) callconv(.C) void,
    addTap: *const fn (filter: *DelayLine, delay: c_int) callconv(.C) ?*DelayLineTap,

    /// note that DelayLineTap is a SoundSource, not a SoundEffect
    freeTap: *const fn (tap: *DelayLineTap) callconv(.C) void,
    setTapDelay: *const fn (t: *DelayLineTap, frames: c_int) callconv(.C) void,
    setTapDelayModulator: *const fn (t: *DelayLineTap, mod: ?*PDSynthSignalValue) callconv(.C) void,
    getTapDelayModulator: *const fn (t: *DelayLineTap) callconv(.C) ?*PDSynthSignalValue,
    setTapChannelsFlipped: *const fn (t: *DelayLineTap, flip: c_int) callconv(.C) void,
};

pub const Overdrive = SoundEffect;
pub const PlaydateSoundEffectOverdrive = extern struct {
    newOverdrive: *const fn () callconv(.C) ?*Overdrive,
    freeOverdrive: *const fn (filter: *Overdrive) callconv(.C) void,
    setGain: *const fn (o: *Overdrive, gain: f32) callconv(.C) void,
    setLimit: *const fn (o: *Overdrive, limit: f32) callconv(.C) void,
    setLimitModulator: *const fn (o: *Overdrive, mod: ?*PDSynthSignalValue) callconv(.C) void,
    getLimitModulator: *const fn (o: *Overdrive) callconv(.C) ?*PDSynthSignalValue,
    setOffset: *const fn (o: *Overdrive, offset: f32) callconv(.C) void,
    setOffsetModulator: *const fn (o: *Overdrive, mod: ?*PDSynthSignalValue) callconv(.C) void,
    getOffsetModulator: *const fn (o: *Overdrive) callconv(.C) ?*PDSynthSignalValue,
};

//////Sprite/////
pub const SpriteCollisionResponseType = enum(c_int) {
    slide,
    freeze,
    overlap,
    bounce,
};
pub const PDRect = extern struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

pub const CollisionPoint = extern struct {
    x: f32,
    y: f32,
};
pub const CollisionVector = extern struct {
    x: c_int,
    y: c_int,
};

pub const SpriteCollisionInfo = extern struct {
    /// The sprite being moved
    sprite: *LCDSprite,
    /// The sprite being moved
    other: *LCDSprite,
    /// The result of collisionResponse
    responseType: SpriteCollisionResponseType,
    /// True if the sprite was overlapping other when the collision started. False if it didn’t overlap but tunneled through other.
    overlaps: bool,
    /// A number between 0 and 1 indicating how far along the movement to the goal the collision occurred
    ti: f32,
    /// The difference between the original coordinates and the actual ones when the collision happened
    move: CollisionPoint,
    /// The collision normal; usually -1, 0, or 1 in x and y. Use this value to determine things like if your character is touching the ground.
    normal: CollisionVector,
    /// The coordinates where the sprite started touching other
    touch: CollisionPoint,
    /// The rectangle the sprite occupied when the touch happened
    spriteRect: PDRect,
    /// The rectangle the sprite being collided with occupied when the touch happened
    otherRect: PDRect,
};

pub const SpriteQueryInfo = extern struct {
    /// The sprite being intersected by the segment
    sprite: ?*LCDSprite,
    // ti1 and ti2 are numbers between 0 and 1 which indicate how far from the starting point of the line segment the collision happened.
    /// entry point
    ti1: f32,
    /// exit point
    ti2: f32,
    /// The coordinates of the first intersection between sprite and the line segment
    entryPoint: CollisionPoint,
    /// The coordinates of the second intersection between sprite and the line segment
    exitPoint: CollisionPoint,
};

pub const LCDSprite = opaque {};
pub const CWCollisionInfo = opaque {};
pub const CWItemInfo = opaque {};

pub const LCDSpriteDrawFunction = *const fn (
    sprite: *LCDSprite,
    bounds: PDRect,
    drawrect: PDRect,
) callconv(.C) void;
pub const LCDSpriteUpdateFunction = *const fn (sprite: *LCDSprite) callconv(.C) void;
pub const LCDSpriteCollisionFilterProc = *const fn (
    sprite: *LCDSprite,
    other: *LCDSprite,
) callconv(.C) SpriteCollisionResponseType;

pub const PlaydateSprite = extern struct {
    setAlwaysRedraw: *const fn (flag: c_int) callconv(.C) void,
    addDirtyRect: *const fn (dirtyRect: LCDRect) callconv(.C) void,
    drawSprites: *const fn () callconv(.C) void,
    updateAndDrawSprites: *const fn () callconv(.C) void,

    newSprite: *const fn () callconv(.C) ?*LCDSprite,
    freeSprite: *const fn (sprite: *LCDSprite) callconv(.C) void,
    copy: *const fn (sprite: *LCDSprite) callconv(.C) ?*LCDSprite,

    addSprite: *const fn (sprite: *LCDSprite) callconv(.C) void,
    removeSprite: *const fn (sprite: *LCDSprite) callconv(.C) void,
    removeSprites: *const fn (sprite: [*]*LCDSprite, count: c_int) callconv(.C) void,
    removeAllSprites: *const fn () callconv(.C) void,
    getSpriteCount: *const fn () callconv(.C) c_int,

    setBounds: *const fn (sprite: *LCDSprite, bounds: PDRect) callconv(.C) void,
    getBounds: *const fn (sprite: *LCDSprite) callconv(.C) PDRect,
    moveTo: *const fn (sprite: *LCDSprite, x: f32, y: f32) callconv(.C) void,
    moveBy: *const fn (sprite: *LCDSprite, dx: f32, dy: f32) callconv(.C) void,

    setImage: *const fn (
        sprite: *LCDSprite,
        image: ?*LCDBitmap,
        flip: LCDBitmapFlip,
    ) callconv(.C) void,
    getImage: *const fn (sprite: *LCDSprite) callconv(.C) ?*LCDBitmap,
    setSize: *const fn (s: *LCDSprite, width: f32, height: f32) callconv(.C) void,
    setZIndex: *const fn (s: *LCDSprite, zIndex: i16) callconv(.C) void,
    getZIndex: *const fn (sprite: *LCDSprite) callconv(.C) i16,

    setDrawMode: *const fn (
        sprite: *LCDSprite,
        mode: LCDBitmapDrawMode,
    ) callconv(.C) LCDBitmapDrawMode,
    setImageFlip: *const fn (sprite: *LCDSprite, flip: LCDBitmapFlip) callconv(.C) void,
    getImageFlip: *const fn (sprite: *LCDSprite) callconv(.C) LCDBitmapFlip,
    /// deprecated in favor of setStencilImage()
    setStencil: *const fn (sprite: *LCDSprite, mode: ?*LCDBitmap) callconv(.C) void,

    setClipRect: *const fn (sprite: *LCDSprite, clipRect: LCDRect) callconv(.C) void,
    clearClipRect: *const fn (sprite: *LCDSprite) callconv(.C) void,
    setClipRectsInRange: *const fn (clipRect: LCDRect, startZ: c_int, endZ: c_int) callconv(.C) void,
    clearClipRectsInRange: *const fn (startZ: c_int, endZ: c_int) callconv(.C) void,

    setUpdatesEnabled: *const fn (sprite: *LCDSprite, flag: c_int) callconv(.C) void,
    updatesEnabled: *const fn (sprite: *LCDSprite) callconv(.C) c_int,
    setCollisionsEnabled: *const fn (sprite: *LCDSprite, flag: c_int) callconv(.C) void,
    collisionsEnabled: *const fn (sprite: *LCDSprite) callconv(.C) c_int,
    setVisible: *const fn (sprite: *LCDSprite, flag: c_int) callconv(.C) void,
    isVisible: *const fn (sprite: *LCDSprite) callconv(.C) c_int,
    setOpaque: *const fn (sprite: *LCDSprite, flag: c_int) callconv(.C) void,
    markDirty: *const fn (sprite: *LCDSprite) callconv(.C) void,

    setTag: *const fn (sprite: *LCDSprite, tag: u8) callconv(.C) void,
    getTag: *const fn (sprite: *LCDSprite) callconv(.C) u8,

    setIgnoresDrawOffset: *const fn (sprite: *LCDSprite, flag: c_int) callconv(.C) void,

    setUpdateFunction: *const fn (
        sprite: *LCDSprite,
        func: ?LCDSpriteUpdateFunction,
    ) callconv(.C) void,
    setDrawFunction: *const fn (sprite: *LCDSprite, func: ?LCDSpriteDrawFunction) callconv(.C) void,

    getPosition: *const fn (s: *LCDSprite, x: ?*f32, y: ?*f32) callconv(.C) void,

    // Collisions
    resetCollisionWorld: *const fn () callconv(.C) void,

    setCollideRect: *const fn (sprite: *LCDSprite, collideRect: PDRect) callconv(.C) void,
    getCollideRect: *const fn (sprite: *LCDSprite) callconv(.C) PDRect,
    clearCollideRect: *const fn (sprite: *LCDSprite) callconv(.C) void,

    setCollisionResponseFunction: *const fn (
        sprite: *LCDSprite,
        func: ?LCDSpriteCollisionFilterProc,
    ) callconv(.C) void,
    /// Caller is responsible for freeing the returned array.
    /// Access results using const info = &results[i];
    checkCollisions: *const fn (
        sprite: *LCDSprite,
        goalX: f32,
        goalY: f32,
        actualX: ?*f32,
        actualY: ?*f32,
        len: *c_int,
    ) callconv(.C) ?[*]SpriteCollisionInfo,
    /// Caller is responsible for freeing the returned array.
    moveWithCollisions: *const fn (
        sprite: *LCDSprite,
        goalX: f32,
        goalY: f32,
        actualX: ?*f32,
        actualY: ?*f32,
        len: *c_int,
    ) callconv(.C) ?[*]SpriteCollisionInfo,
    /// Caller is responsible for freeing the returned array.
    querySpritesAtPoint: *const fn (x: f32, y: f32, len: *c_int) callconv(.C) ?[*]*LCDSprite,
    /// Caller is responsible for freeing the returned array.
    querySpritesInRect: *const fn (
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        len: *c_int,
    ) callconv(.C) ?[*]*LCDSprite,
    /// Caller is responsible for freeing the returned array.
    querySpritesAlongLine: *const fn (
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
        len: *c_int,
    ) callconv(.C) ?[*]*LCDSprite,
    /// Caller is responsible for freeing the returned array.
    /// Access results using const info = &results[i];
    querySpriteInfoAlongLine: *const fn (
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
        len: *c_int,
    ) callconv(.C) ?[*]SpriteQueryInfo,
    /// Caller is responsible for freeing the returned array.
    overlappingSprites: *const fn (sprite: *LCDSprite, len: c_int) callconv(.C) ?[*]*LCDSprite,
    /// Caller is responsible for freeing the returned array.
    allOverlappingSprites: *const fn (len: *c_int) callconv(.C) ?[*]*LCDSprite,

    // added in 1.7
    setStencilPattern: *const fn (sprite: *LCDSprite, pattern: *[8]u8) callconv(.C) void,
    clearStencil: *const fn (sprite: *LCDSprite) callconv(.C) void,

    setUserdata: *const fn (sprite: *LCDSprite, userdata: ?*anyopaque) callconv(.C) void,
    getUserdata: *const fn (sprite: *LCDSprite) callconv(.C) ?*anyopaque,

    // added in 1.10
    setStencilImage: *const fn (
        sprite: *LCDSprite,
        stencil: ?*LCDBitmap,
        tile: c_int,
    ) callconv(.C) void,

    // 2.1
    setCenter: *const fn (s: *LCDSprite, x: f32, y: f32) callconv(.C) void,
    getCenter: *const fn (s: *LCDSprite, x: ?*f32, y: ?*f32) callconv(.C) void,
};

////////Lua///////
pub const LuaState = *anyopaque;
pub const LuaCFunction = *const fn (state: *LuaState) callconv(.C) c_int;
pub const LuaUDObject = opaque {};

pub const LiteralType = enum(c_int) {
    int = 0,
    float = 1,
    string = 2,
};
pub const LuaReg = extern struct {
    name: [*:0]const u8,
    func: LuaCFunction,
};
pub const LuaType = enum(c_int) {
    nil = 0,
    bool = 1,
    int = 2,
    float = 3,
    string = 4,
    table = 5,
    function = 6,
    thread = 7,
    object = 8,
};
pub const LuaVal = extern struct {
    name: [*:0]const u8,
    type: LiteralType,
    value: extern union {
        int: c_uint,
        float: f32,
        string: [*:0]const u8,
    },
};
pub const PlaydateLua = extern struct {
    /// Returns 1 on success, else 0 with an error message in outErr
    addFunction: *const fn (
        f: LuaCFunction,
        name: [*:0]const u8,
        outErr: ?*[*:0]const u8,
    ) callconv(.C) c_int,
    /// Returns 1 on success, else 0 with an error message in outErr
    registerClass: *const fn (
        name: [*:0]const u8,
        reg: ?[*]const LuaReg,
        vals: ?[*]const LuaVal,
        isstatic: c_int,
        outErr: ?*[*:0]const u8,
    ) callconv(.C) c_int,

    pushFunction: *const fn (f: LuaCFunction) callconv(.C) void,
    indexMetatable: *const fn () callconv(.C) c_int,

    stop: *const fn () callconv(.C) void,
    start: *const fn () callconv(.C) void,

    // stack operations
    getArgCount: *const fn () callconv(.C) c_int,
    getArgType: *const fn (pos: c_int, outClass: ?*[*:0]const u8) callconv(.C) LuaType,

    argIsNil: *const fn (pos: c_int) callconv(.C) c_int,
    getArgBool: *const fn (pos: c_int) callconv(.C) c_int,
    getArgInt: *const fn (pos: c_int) callconv(.C) c_int,
    getArgFloat: *const fn (pos: c_int) callconv(.C) f32,
    getArgString: *const fn (pos: c_int) callconv(.C) [*:0]const u8,
    getArgBytes: *const fn (pos: c_int, outlen: ?*usize) callconv(.C) [*:0]const u8,
    getArgObject: *const fn (pos: c_int, type: [*:0]u8, ?**LuaUDObject) callconv(.C) ?*anyopaque,

    getBitmap: *const fn (c_int) callconv(.C) ?*LCDBitmap,
    getSprite: *const fn (c_int) callconv(.C) ?*LCDSprite,

    // for returning values back to Lua
    pushNil: *const fn () callconv(.C) void,
    pushBool: *const fn (val: c_int) callconv(.C) void,
    pushInt: *const fn (val: c_int) callconv(.C) void,
    pushFloat: *const fn (val: f32) callconv(.C) void,
    pushString: *const fn (str: [*:0]const u8) callconv(.C) void,
    pushBytes: *const fn (str: [*]const u8, len: usize) callconv(.C) void,
    pushBitmap: *const fn (bitmap: ?*LCDBitmap) callconv(.C) void,
    pushSprite: *const fn (sprite: ?*LCDSprite) callconv(.C) void,

    pushObject: *const fn (
        obj: *anyopaque,
        type: [*:0]u8,
        nValues: c_int,
    ) callconv(.C) ?*LuaUDObject,
    retainObject: *const fn (obj: *LuaUDObject) callconv(.C) *LuaUDObject,
    releaseObject: *const fn (obj: *LuaUDObject) callconv(.C) void,

    setUserValue: *const fn (obj: *LuaUDObject, slot: c_int) callconv(.C) void,
    getUserValue: *const fn (obj: *LuaUDObject, slot: c_int) callconv(.C) c_int,

    callFunction_deprecated: *const fn (name: [*:0]const u8, nargs: c_int) callconv(.C) void,
    /// Calling lua from C has some overhead and can be slow. Use sparingly!
    callFunction: *const fn (
        name: [*:0]const u8,
        nargs: c_int,
        outerr: ?*[*:0]const u8,
    ) callconv(.C) c_int,
};

///////JSON///////
pub const JSONValueType = enum(c_int) {
    null = 0,
    true = 1,
    false = 2,
    integer = 3,
    float = 4,
    string = 5,
    array = 6,
    table = 7,
};
pub const JSONValue = extern struct {
    type: u8,
    data: extern union {
        int: c_int,
        float: f32,
        string: [*:0]u8,
        array: *anyopaque,
        table: *anyopaque,
    },

    pub inline fn asInt(value: JSONValue) c_int {
        switch (@as(JSONValueType, @enumFromInt(value.type))) {
            .integer => return value.data.int,
            .float => return @intFromFloat(value.data.float),
            .string => return std.fmt.parseInt(c_int, std.mem.span(value.data.string), 10) catch 0,
            .true => return 1,
            else => return 0,
        }
    }
    pub inline fn asFloat(value: JSONValue) f32 {
        switch (@as(JSONValueType, @enumFromInt(value.type))) {
            .integer => return @floatFromInt(value.data.int),
            .float => return value.data.float,
            .string => return 0,
            .true => 1.0,
            else => return 0.0,
        }
    }
    pub inline fn asBool(value: JSONValue) c_int {
        return if (@as(JSONValueType, @enumFromInt(value.type)) == .string)
            @intFromBool(value.data.string[0] != 0)
        else
            value.asInt();
    }
    pub inline fn asString(value: JSONValue) ?[*:0]u8 {
        return if (@as(JSONValueType, @enumFromInt(value.type)) == .string)
            value.data.string
        else
            null;
    }
};

pub const JSONDecoder = extern struct {
    decodeError: *const fn (
        decoder: *JSONDecoder,
        @"error": [*:0]const u8,
        linenum: c_int,
    ) callconv(.C) void,

    // the following functions are optional
    willDecodeSublist: ?WillDecodeSublistFn,
    shouldDecodeTableValueForKey: ?*const fn (
        decoder: *JSONDecoder,
        key: [*:0]const u8,
    ) callconv(.C) c_int,
    didDecodeTableValue: ?DidDecodeTableValueFn,
    shouldDecodeArrayValueAtIndex: ?*const fn (
        decoder: *JSONDecoder,
        pos: c_int,
    ) callconv(.C) c_int,
    didDecodeArrayValue: ?DidDecodeArrayValueFn,
    didDecodeSublist: ?*DidDecodeSublistFn,

    userdata: ?*anyopaque,
    /// When set, the decoder skips parsing and returns the current subtree as a string
    returnString: c_int,
    /// updated during parsing, reflects current position in tree
    path: [*:0]const u8,

    pub const WillDecodeSublistFn = *const fn (
        decoder: *JSONDecoder,
        name: [*:0]const u8,
        type: JSONValueType,
    ) callconv(.C) void;

    pub const DidDecodeTableValueFn = *const fn (
        decoder: *JSONDecoder,
        key: [*:0]const u8,
        value: JSONValue,
    ) callconv(.C) void;

    /// If pos == 0, this was a bare value at the root of the file
    pub const DidDecodeArrayValueFn = *const fn (
        decoder: *JSONDecoder,
        pos: c_int,
        value: JSONValue,
    ) callconv(.C) void;

    pub const DidDecodeSublistFn = *const fn (
        decoder: *JSONDecoder,
        name: [*:0]const u8,
        type: JSONValueType,
    ) callconv(.C) ?*anyopaque;

    // convenience functions for setting up a table-only or array-only decoder
    pub inline fn setupTableOnlyDecode(
        decoder: *JSONDecoder,
        willDecodeSublist: ?WillDecodeSublistFn,
        didDecodeTableValue: ?DidDecodeTableValueFn,
        didDecodeSublist: ?DidDecodeSublistFn,
    ) void {
        decoder.didDecodeTableValue = didDecodeTableValue;
        decoder.didDecodeArrayValue = null;
        decoder.willDecodeSublist = willDecodeSublist;
        decoder.didDecodeSublist = didDecodeSublist;
    }

    pub inline fn setupArrayOnlyDecode(
        decoder: *JSONDecoder,
        willDecodeSublist: ?WillDecodeSublistFn,
        didDecodeArrayValue: ?DidDecodeArrayValueFn,
        didDecodeSublist: ?DidDecodeSublistFn,
    ) void {
        decoder.didDecodeTableValue = null;
        decoder.didDecodeArrayValue = didDecodeArrayValue;
        decoder.willDecodeSublist = willDecodeSublist;
        decoder.didDecodeSublist = didDecodeSublist;
    }
};

pub const JSONReader = extern struct {
    /// Fill buffer, return bytes written or -1 on end of data
    read: *const fn (userdata: ?*anyopaque, buf: [*]u8, bufsize: c_int) callconv(.C) c_int,
    /// Passed back to the read function above
    userdata: ?*anyopaque,
};
pub const JSONWriteFunc = *const fn (
    userdata: ?*anyopaque,
    str: [*]const u8,
    len: c_int,
) callconv(.C) void;

pub const JSONEncoder = extern struct {
    writeStringFunc: JSONWriteFunc,
    userdata: ?*anyopaque,

    state: packed struct(u32) {
        pretty: bool,
        started_table: bool,
        started_array: bool,
        depth: u29,
    },

    startArray: *const fn (encoder: *JSONEncoder) callconv(.C) void,
    addArrayMember: *const fn (encoder: *JSONEncoder) callconv(.C) void,
    endArray: *const fn (encoder: *JSONEncoder) callconv(.C) void,
    startTable: *const fn (encoder: *JSONEncoder) callconv(.C) void,
    addTableMember: *const fn (
        encoder: *JSONEncoder,
        name: [*]const u8,
        len: c_int,
    ) callconv(.C) void,
    endTable: *const fn (encoder: *JSONEncoder) callconv(.C) void,
    writeNull: *const fn (encoder: *JSONEncoder) callconv(.C) void,
    writeFalse: *const fn (encoder: *JSONEncoder) callconv(.C) void,
    writeTrue: *const fn (encoder: *JSONEncoder) callconv(.C) void,
    writeInt: *const fn (encoder: *JSONEncoder, num: c_int) callconv(.C) void,
    writeDouble: *const fn (encoder: *JSONEncoder, num: f64) callconv(.C) void,
    writeString: *const fn (encoder: *JSONEncoder, str: [*]const u8, len: c_int) callconv(.C) void,
};

pub const PlaydateJSON = extern struct {
    initEncoder: *const fn (
        encoder: *JSONEncoder,
        write: JSONWriteFunc,
        userdata: ?*anyopaque,
        pretty: c_int,
    ) callconv(.C) void,

    decode: *const fn (
        functions: *JSONDecoder,
        reader: JSONReader,
        outval: ?*JSONValue,
    ) callconv(.C) c_int,
    decodeString: *const fn (
        functions: *JSONDecoder,
        jsonString: [*:0]const u8,
        outval: ?*JSONValue,
    ) callconv(.C) c_int,
};

///////Scoreboards///////////
pub const PDScore = extern struct {
    rank: u32,
    value: u32,
    player: [*:0]u8,
};
pub const PDScoresList = extern struct {
    boardID: [*:0]u8,
    count: c_uint,
    lastUpdated: u32,
    playerIncluded: c_int,
    limit: c_uint,
    scores: [*]PDScore,
};
pub const PDBoard = extern struct {
    boardID: [*:0]u8,
    name: [*:0]u8,
};
pub const PDBoardsList = extern struct {
    count: c_uint,
    lastUpdated: u32,
    boards: [*]PDBoard,
};
pub const AddScoreCallback = ?*const fn (
    score: ?*PDScore,
    errorMessage: [*:0]const u8,
) callconv(.C) void;
pub const PersonalBestCallback = ?*const fn (
    score: ?*PDScore,
    errorMessage: [*:0]const u8,
) callconv(.C) void;
pub const BoardsListCallback = ?*const fn (
    boards: ?*PDBoardsList,
    errorMessage: [*:0]const u8,
) callconv(.C) void;
pub const ScoresCallback = ?*const fn (
    scores: ?*PDScoresList,
    errorMessage: [*:0]const u8,
) callconv(.C) void;

pub const PlaydateScoreboards = extern struct {
    addScore: *const fn (
        boardId: [*:0]const u8,
        value: u32,
        callback: AddScoreCallback,
    ) callconv(.C) c_int,
    getPersonalBest: *const fn (
        boardId: [*:0]const u8,
        callback: PersonalBestCallback,
    ) callconv(.C) c_int,
    freeScore: *const fn (score: *PDScore) callconv(.C) void,

    getScoreboards: *const fn (callback: BoardsListCallback) callconv(.C) c_int,
    freeBoardsList: *const fn (boards: *PDBoardsList) callconv(.C) void,

    getScores: *const fn (boardId: [*:0]const u8, callback: ScoresCallback) callconv(.C) c_int,
    freeScoresList: *const fn (scores: *PDScoresList) callconv(.C) void,
};