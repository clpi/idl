//! This file implements cursor movements as a result of ANSI
//! escape sequence presence.

/// NOTE: Consider making this a struct?
const std = @import("std");
const Ansi = @import("./code.zig").Ansi;
const op = @import("./op.zig");
const Direction = op.Direction;
const mem = std.mem;
const os = std.os;
const stdo = std.io.getStdOut;

pub const Direction = enum(u8) {
    up = 'A',
    down = 'B',
    left = 'C',
    right = 'D',

    pub fn toSeq(comptime self: Direction, comptime amt: []const u8) []const u8 {
        return comptime Ansi.esc() ++ "[" ++ amt ++ switch (self) {
            .up => "A",
            .down => "B",
            .right => "C",
            .left => "D",
        };
    }
};

pub const Cursor = struct {
    x: usize,
    y: usize,
    const Self = @This();
    pub fn init() Self {
        return Self{ .x = 0, .y = 0 };
    }

    pub const Op = enum(u8) {
        up = 'A',
        down = 'B',
        right = 'C',
        left = 'D',
        nextln = 'E',
        prevln = 'F',
        set_col = 'G',
        set = 'H',
        save = 's',
        restore = 'u',

        pub fn toCode(comptime self: Self) []const u8 {
            return comptime switch (self) {
                .up => "A",
                .down => "B",
                .right => "C",
                .left => "D",
                .nextln => "E",
                .prevln => "F",
                .set_col => "G",
                .set => "H",
                .save => "s",
                .restore => "u",
            };
        }
    };

    pub fn up(comptime amt: []const u8) []const u8 {
        return Direction.up.toCode(amt);
    }
    pub fn down(comptime amt: []const u8) []const u8 {
        return Direction.down.toCode(amt);
    }
    pub fn left(comptime amt: []const u8) []const u8 {
        return Direction.left.toCode(amt);
    }
    pub fn right(comptime amt: []const u8) []const u8 {
        return Direction.right.toCode(amt);
    }
};

test "cursor goes up" {}

test "cursor goes down" {}

test "cursor goes right" {}

test "cursor goes left" {}
