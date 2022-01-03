const std = @import("std");
const ascii = std.ascii;
const ccode = ascii.control_code;
const ESC = ccode.ESC;

/// Wrapper for ascii in stdlib for conveninece
pub const Ansi = enum {
    Esc,
    Nul,
    Ctrl,
    Cr,
    Bs, // and the list goes on.

    const Self = @This();

    pub fn toNumString(self: Self) []const u8 {
        return &[_]u8{@enumToInt(self)};
    }

    pub fn toCode(self: Self) []const u8 {
        return switch (self) {
            .esc => "\x1B",
            .ctrl => self.ctrl(),
            .tab => self.tab(),
            .bs => self.bs(),
            _ => self.esc(),
        };
    }

    pub fn esc() []const u8 {
        return "\x1B";
    }

    pub fn ctrl() []const u8 {
        return &[_]u8{ccode.CTRL};
    }

    pub fn tab() []const u8 {
        return &[_]u8{ccode.TAB};
    }
    pub fn bs() []const u8 {
        return &[_]u8{ccode.BS};
    }
};

const expectEq = std.testing.expectEqual;
test "ESC ansii" {
    const exp = 0x1B;
    const esc = Ansi.esc();
    std.debug.print("Type of esc: {s}", .{@TypeOf(esc)});
    try expectEq(exp, exp);
}
