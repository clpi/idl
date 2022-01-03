const std = @import("std");
const col = @import("./term/colors.zig");
const Color = col.Color;
const bfg = col.Spec.bright_fg;
const green = Color.green;
const red = Color.red;
const bold = Color.bold;
const log = std.log;
const math = std.math;
const mem = std.mem;
const bprint = std.fmt.BufPrint;
const reader = std.io.getStdIn().reader();
const writer = std.io.getStdIn().writer();

pub fn readUntil(alloc: mem.Allocator, comptime delim: u8) ![]const u8 {
    const max = math.maxInt(usize);
    return reader.readUntilDelimiterAlloc(alloc, delim, max);
}

pub fn writeToStdout(content: []const u8) ![]const u8 {
    return writer.writeAll(content);
}

pub fn intToStr(int: u8, buf: []u8) ![]const u8 {
    return try std.fmt.bufPrint(buf, "{}", .{int});
}
pub fn cwd() []const u8 {
    var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const pw = try std.os.getcwd(buf[0..]);
    return pw;
}

pub fn ilang() []const u8 {
    return comptime Color.blue.bold(null) ++ "[" ++ col.reset() ++
        Color.blue.bold(null) ++ " I" ++ col.reset() ++
        Color.green.finish(.bright_fg) ++ "lang " ++ col.reset() ++
        Color.blue.bold(null) ++ "]" ++ col.reset();
}
pub fn arrow_str(comptime color: Color) []const u8 {
    return comptime color.bold(null) ++ " -> " ++ col.reset();
}
pub fn resp_div(comptime color: Color) []const u8 {
    return comptime color.bold(null) ++ " :: " ++ col.reset();
}
pub fn ok_str() []const u8 {
    return comptime Color.green.bold(null) ++ " [" ++ col.reset() ++
        Color.green.bold(null) ++ "OK" ++ col.reset() ++
        Color.green.bold(.bright_fg) ++ "]  " ++ col.reset();
}
pub fn err_str() []const u8 {
    return comptime Color.green.bold(null) ++ " [" ++ col.reset() ++
        Color.red.bold(.bright_fg) ++ "ERR" ++ col.reset() ++
        Color.red.bold(.bright_fg) ++ "]  " ++ col.reset();
}

pub fn prompt() void {
    std.debug.print("{s}{s}", .{ comptime ilang(), comptime arrow_str(.yellow) });
}

pub fn respOk(comptime s: []const u8) void {
    std.debug.print("{s}{s}{s}{s}\n", .{ comptime ilang(), comptime resp_div(.yellow), comptime ok_str(), comptime s });
}
pub fn respErr(comptime s: []const u8) void {
    std.debug.print("{s}{s}{s}{s}\n", .{ comptime ilang(), comptime resp_div(.red), comptime err_str(), comptime s });
}

//// Same as print, but second arg is anytype, just like normal bufPrint
pub fn printA(comptime s: []const u8, msg: anytype) void {
    std.debug.print(s, msg);
}

pub fn print(comptime s: []const u8, msg: anytype) void {
    std.debug.print(s, msg);
}

pub fn printTwo(comptime s: []const u8, m1: []const u8, m2: []const u8) void {
    std.debug.print(s, .{ m1, m2 });
}

pub const Log = enum {
    warn,
    msg,
    info,
    debug,
    err,

    const Self = @This();

    pub fn info(comptime s: []const u8, args: anytype) void {
        std.log.info(s, args);
    }
};
