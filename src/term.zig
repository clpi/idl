const std = @import("std");
const stdout = std.io.getStdOut;
const streams = &kstdout.outStream().stream();
const op = @import("term/op.zig");
const Cursor = @import("term/cursor.zig").Cursor;
const stdo = std.io.getStdOut();
const ascii = std.ascii;
const unic = std.unicode;
const os = std.os;
const tos = std.os.termios;

pub const Terminal = struct {
    // w: usize,
    // h: usize,
    cursor: Cursor,
    // uid: usize,
    const Self = @This();

    pub fn init() Self {
        return Terminal{ .cursor = Cursor.init() };
    }

    pub fn isAtty() bool {
        return std.os.isatty(std.io.getStdIn());
    }

    pub fn exec(comptime ac: []const u8) !void {
        _ = try stdo.writer().writeAll(ac);
    }

    pub fn clearScreen(rel: op.Relative) !void {
        try Self.exec(op.Clear.clearScreen(rel));
    }

    pub fn clearLn(rel: op.Relative) !void {
        try Self.exec(op.Clear.clearLine(rel));
    }

    pub fn setCursor(self: Self, x: usize, y: usize) !void {
        try Self.exec(self.cursor.set(x, y));
    }

    pub const Stream = struct { 
    }
};

