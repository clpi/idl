const std = @import("std");
const stdo = std.io.getStdOut();
const ascii = std.ascii;
const unic = std.unicode;
const os = std.os;
const tos = std.os.termios;

pub const Cursor = struct { x: usize, y: usize };

pub const Terminal = struct {
    // w: usize,
    // h: usize,
    // cursor: Cursor,
    // uid: usize,
    const Self = @This();

    pub fn isAtty() bool {
        return std.os.isatty(std.io.getStdIn());
    }

    pub fn exec(comptime op: []const u8) !void {
        _ = try stdo.writer().writeAll();
    }
};
