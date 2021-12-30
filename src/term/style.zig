const std = @import("std");
const fmt = std.fmt;
const print = std.debug.print;
const reader = std.io.getStdIn().reader();
const writer = std.io.getStdIn().writer();
const util = @import("../util.zig");

const Styl = enum {
    bold, italic, sthrough, uline, dim, blink,
    const Self = @This();

    pub fn bold(comptime s: []const u8) []const u8 {
        

    }
};
const Style = struct {
    fg: ?Fg,
    bg: ?Bg,
    style: ?Style,
    msg: comptime []const u8,

    pub fn toString(self: Self) {

    }
}

const Fg = enum {
    bblue, blue, bred, red, bcyan, cyan, bmagenta, magenta, byellow, yellow, bgreen, green,

    const Self = @This();

    pub fn toString(self: Self, comptime s: []const u8) {
        switch(self) {
            .bblue => std.DynamicBitSetUnmanaged

        }

    }

}

pub fn bblue(comptime s: []const u8) []const u8 {
     
}
