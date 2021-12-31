const std = @import("std");
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

pub fn prompt() void {
    std.debug.print("[Ilang] >_ ", .{});
}

pub fn respOk(comptime s: []const u8) void {
    std.debug.print("[Ilang] :: [OK] {s}", .{s});
}
pub fn respErr(comptime s: []const u8) void {
    std.debug.print("[Ilang] :: [ER] {s}", .{s});
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
