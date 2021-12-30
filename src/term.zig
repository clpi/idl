const std = @import("std");
const ascii = std.ascii;
const space = ascii.spaces;
const ccode = ascii.control_code;
const unic = std.unicode;
const os = std.os;

pub const Cursor = struct { x: usize, y: usize };
pub const Terminal = struct {
    w: usize,
    h: usize,
    cursor: Cursor,
    uid: usize,
    const Self = @This();

    pub fn isAtty() bool {
        return std.os.isatty(std.io.getStdIn());
    }
};

/// Wrapper for ascii in stdlib for conveninece
pub const Ascii = enum {
    esc,
    nul,
    bs,
    ctrl,
    cr,
    bs, // and the list goes on.

    const Self = @This();

    pub fn toNumString(self: Self) []const u8 {
        return &[_]u8{@enumToInt(self)};
    }

    fn toString(self: Self) []const u8 {
        switch (self) {
            .esc => return self.esc(),
            .ctrl => return self.ctrl(),
            .tab => return self.tab(),
            .bs => return self.bs(),
            _ => return self.esc(),
        }
    }

    fn esc() []const u8 {
        return &[_]u8{ccode.ESC};
    }

    fn ctrl() []const u8 {
        return &[_]u8{ccode.CTRL};
    }

    fn tab() []const u8 {
        return &[_]u8{ccode.TAB};
    }
    fn bs() []const u8 {
        return &[_]u8{ccode.BS};
    }
};
