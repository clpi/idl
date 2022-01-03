const std = @import("std");
const cursor = @import("cursor.zig");
const Ansi = @import("./code.zig").Ansi;
const TermOp = @import("./op.zig").TermOp;

pub const Relative = enum(u8) {
    to_start = '0',
    to_end = '1',
    entire = '2',

    pub fn toCode(comptime self: Relative) []const u8 {
        return comptime switch (self) {
            .to_start => "0",
            .to_end => "1",
            .entire => "2",
        };
    }
};

pub const Direction = enum(u8) {
    up = 'A',
    down = 'B',
    left = 'C',
    right = 'D',

    pub fn toCode(comptime self: Direction, comptime amt: []const u8) []const u8 {
        return comptime Ansi.esc() ++ "[" ++ amt ++ switch (self) {
            .up => "A",
            .down => "B",
            .right => "C",
            .left => "D",
        };
    }
};

pub const Clear = enum(u8) {
    clr_screen = 'J',
    clr_line = 'K',

    const Self = @This();

    pub fn pre() []const u8 {
        return Ansi.esc() ++ "[";
    }

    pub fn toCode(comptime self: Self) []const u8 {
        comptime switch (self) {
            .clear_screen => "J",
            .clear_line => "K",
        };
    }

    pub fn clearScreen(rel: Relative) []const u8 {
        return Self.pre() ++ rel.toCode() ++ "J";
    }

    pub fn clearLine(rel: Relative) []const u8 {
        return Self.pre() ++ rel.toCode() ++ "K";
    }
};
