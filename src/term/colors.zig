//! This module provides terminal coloring functionality
//! on an individual basis or combined using the terminal
//! formatter in the parent module
const std = @import("std");
const util = @import("../util.zig");
const ascii = std.ascii;
const os = std.os;
const fmt = std.fmt;
const print = std.debug.print;
const io = std.io;
const reader = io.getStdIn().reader();
const writer = io.getStdIn().writer();

/// Todo: Check this as well
pub const EscSeq = enum {
    octal, unicode, hexadecimal, hex_unicode, newline,

    const Self = @This();

    pub fn prefix(self: Self) ?[]const u8 {
        switch(self) {
            .octal         => "\\033",
            .unicode       => "\\u001b",
            .hexadecimal   => "\x",
            .hex_unicode   => "\u",
            .newline       => "\n",
            else           => null,
        }
    }

    pub fn format(self: Self, comptime s: []const u8) []const u8 {
        switch (self) {
            .hex_unicode => return "\\u{" ++ s ++ "}",
            else => return self.prefix() ++ s,
        }
    }
};

/// Struct Version of the escape sequence with
/// all default 
pub const Esc = packed struct {
    octal        = "\\033",
    unicode      = "\\u001b",
    hex          = "\\x1B",
    hex_unicode  = "\\x",
    decimal      = "27",
    creturn      = "\r",
    tab          = "\t",
    bslash       = "\\",
    newline      = "\n",
    squote       = "\'",
    dquote       = "\"",

    const Self = @This();

    pub fn delim(comptime a: []const u8, comptime b: []const u8) []const u8 {
        return a ++ ";" ++ b;
    }
};

pub const Intensity = packed enum(u8) {
    normal_fg = 3,
    normal_bg = 4,
    bright_fg = 9,
    bright_bg = 10,
    const Self = @This();
};

pub const ColorCode = packed enum(u8) {
    black  = 0,
    red    = 1,
    green  = 2,
    yellow = 3,
    blue   = 4,
    purple = 5,
    cyan   = 6,
    white  = 7,

    const Self = @This();

    pub fn fg(self: Self) []const u8 {
        switch (self) {
            .bmagenta => return "\\033[105m",
            .byellow  => return "\\033[103m",
            .bgreen   => return "\\033[102m",
            .bblue    => return "\\033[104m",
            .bcyan    => return "\\033[106m",
            .bgray    => return "\\033[37m",
            .bred     => return "\\033[101m",
            .black    => return "\\033[30m",
            .magenta  => return "\\033[35m",
            .yellow   => return "\\033[33m",
            .green    => return "\\033[32m",
            .blue     => return "\\033[34m",
            .red      => return "\\033[31m",
            .gray     => return "\\033[100m",
            .reset    => return "\\033[39m",
        }
    }

    pub fn bg(self: Self) []const u8 {
        switch (self) {
            .bmagenta => return "\\033[105m",
            .byellow  => return "\\033[103m",
            .bgreen   => return "\\033[102m",
            .bblue    => return "\\033[104m",
            .bcyan    => return "\\033[106m",
            .bgray    => return "\\033[37m",
            .bred     => return "\\033[101m",
            .black    => return "\\033[30m",
            .magenta  => return "\\033[35m",
            .yellow   => return "\\033[33m",
            .green    => return "\\033[32m",
            .blue     => return "\\033[34m",
            .red      => return "\\033[31m",
            .gray     => return "\\033[100m",
            .reset    => return "\\033[49m"
        }
    }
};

const Color = enum {
    bblue, blue, bred, red, bcyan, cyan, bmagenta, magenta, byellow, yellow, bgreen, green, bwhite, white, bblack, black, bgray, gray, reset,

};

const Style = struct {
    fg: ?Fg,
    bg: ?Bg,
    style: ?Style,
    msg: comptime []const u8,

    
    // pub fn toString(self: Self) {

    // }
};

const Fg = enum {
    color: Color,

    const Self = @This();

    pub fn toAnsi(self: Self) []const u8 {
        

    }

    // pub fn toString(self: Self, comptime s: []const u8) {
        // switch(self) {
            // .bblue => ""

        // }

    // }

};

// pub fn bblue(comptime s: []const u8) []const u8 {
     
// };
