//! This module provides terminal coloring functionality
//! on an individual basis or combined using the terminal
//! formatter in the parent module
const std = @import("std");
const utils = @import("../util.zig");
const Ansi = @import("./code.zig").Ansi;
const Style = @import("./style.zig").Style;
const control_code = std.ascii.control_code;
const os = std.os;
const io = std.io;
const fmt = std.fmt;
const print = std.debug.print;
const reader = io.getStdIn().reader();
const writer = io.getStdIn().writer();

/// Struct Version of the escape sequence with
pub const Color = enum(u8) {
    black = 0,
    red = 1,
    green = 2,
    yellow = 3,
    blue = 4,
    magenta = 5,
    cyan = 6,
    white = 7,
    rgb = 8,

    const Self = @This();

    pub fn toCode(comptime self: Self, spec: Spec) []const u8 {
        const scode = spec.toCode();
        return scode ++ switch (self) {
            .black => "0",
            .red => "1",
            .green => "2",
            .yellow => "3",
            .blue => "4",
            .magenta => "5",
            .cyan => "6",
            .white => "7",
            .rgb => "8",
        };
    }

    pub fn index() []const u8 {
        return "\x1B[38;5m";
    }

    pub fn fg(comptime self: Self) []const u8 {
        const colcode = comptime self.toCode(Spec.normal_fg);
        return Spec.prefix() ++ colcode ++ Style.none();
    }
    pub fn bg(comptime self: Self) []const u8 {
        const colcode = comptime self.toCode(Spec.normal_bg);
        return Spec.prefix() ++ colcode ++ Style.none();
    }
    pub fn bfg(comptime self: Self) []const u8 {
        const colcode = comptime self.toCode(Spec.bright_bg);
        return Spec.prefix() ++ colcode ++ Style.none();
    }
    pub fn bbg(comptime self: Self) []const u8 {
        const colcode = comptime self.toCode(Spec.bright_bg);
        return Spec.prefix() ++ colcode ++ Style.none();
    }
    pub fn toPre(comptime self: Self, comptime spec: Spec) []const u8 {
        return Spec.prefix() ++ self.toCode(spec);
    }

    pub fn toPreParams(comptime self: Self, comptime bri: Spec.Brightness, comptime loc: Spec.Location) []const u8 {
        return Color.toPre(self, comptime Spec.init(bri, loc));
    }
    pub fn toInt(self: Self) u8 {
        return @enumToInt(self);
    }
    pub fn styled(self: Self, comptime style: Style, comptime spec: ?Spec) []const u8 {
        const seq = comptime self.toPre(spec orelse Spec.default());
        return seq ++ style.toCode();
    }

    pub fn finish(self: Self, comptime spec: ?Spec) []const u8 {
        return comptime self.toPre(spec orelse Spec.default()) ++ "m";
    }

    pub fn bold(comptime self: Self, comptime spec: ?Spec) []const u8 {
        return self.styled(Style.bold, spec);
    }
    pub fn dim(comptime self: Self, comptime spec: ?Spec) []const u8 {
        return self.styled(Style.dim, spec);
    }
    pub fn underline(comptime self: Self, comptime spec: ?Spec) []const u8 {
        return self.styled(Style.underline, spec);
    }
    pub fn italic(comptime self: Self, comptime spec: ?Spec) []const u8 {
        return self.styled(Style.italic, spec);
    }
    pub fn blink(comptime self: Self, comptime spec: ?Spec) []const u8 {
        return self.styled(Style.blink, spec);
    }
    pub fn write(comptime self: Self, comptime spec: ?Spec, comptime style: ?Style) void {
        const sp = spec orelse Spec.default();
        const sty = style orelse Style.none();
        try std.io.getStdOut().writer().writeAll(self.styled(comptime sty, comptime sp));
    }
    pub const Spec = enum(u8) {
        normal_fg = 3,
        normal_bg = 4,
        bright_fg = 9,
        bright_bg = 10,

        const Self = @This();

        pub fn default() Spec {
            return .normal_fg;
        }

        pub fn toCode(self: Spec) []const u8 {
            return switch (self) {
                .normal_fg => "3",
                .normal_bg => "4",
                .bright_fg => "9",
                .bright_bg => "10",
            };
        }

        pub fn init(bri: Brightness, loc: Location) Spec {
            return switch (bri) {
                Brightness.normal => switch (loc) {
                    Location.fg => Spec.normal_fg,
                    Location.bg => Spec.normal_bg,
                },
                Brightness.bright => switch (loc) {
                    Location.fg => Spec.bright_fg,
                    Location.bg => Spec.bright_bg,
                },
            };
        }

        pub fn len(comptime self: Spec) u8 {
            return comptime switch (self) {
                .bright_bg => 2,
                else => 1,
            } + Ansi.esc().len;
        }
        pub fn prefix() []const u8 {
            return Ansi.esc() ++ "["; // length 2, or 3 if bright_bg
        }
        pub fn toInt(self: Spec) u8 {
            return @enumToInt(self);
        }
        pub fn fmtAnsi(comptime self: Spec, ansi: Ansi) []const u8 {
            return Ansi.toNumString(ansi) ++ self.toNumString();
        }

        pub fn expandAnsi(self: Spec, asc: []u8) []const u8 {
            return asc ++ self.toCode();
        }

        pub const Location = enum {
            fg,
            bg,
        };

        pub const Brightness = enum { bright, normal };
    };
};

pub fn reset() []const u8 {
    return Ansi.esc() ++ "[0m";
}
pub fn writeReset() void {
    try std.io.getStdOut().writer().writeAll("\x1B[0m");
}
pub const Fg = packed struct {
    pub const Br = struct {
        pub const gray = "\x1B[30;1m";
        pub const red = "\x1B[31;1m";
        pub const green = "\x1B[32;1m";
        pub const yellow = "\x1B[33;1m";
        pub const blue = "\x1B[34;1m";
        pub const magenta = "\x1B[35;1m";
        pub const cyan = "\x1B[36;1m";
        pub const white = "\x1B[37;1m";
    };
    pub const black = "\x1B[30m";
    pub const red = "\x1B[31m";
    pub const green = "\x1B[32m";
    pub const yellow = "\x1B[33m";
    pub const blue = "\x1B[34m";
    pub const magenta = "\x1B[35m";
    pub const cyan = "\x1B[36m";
    pub const white = "\x1B[37m";
};
pub const Bg = packed struct {
    pub const Br = struct {
        pub const gray = "\x1B[40;1m";
        pub const red = "\x1B[41;1m";
        pub const green = "\x1B[42;1m";
        pub const yellow = "\x1B[43;1m";
        pub const blue = "\x1B[44;1m";
        pub const magenta = "\x1B[45;1m";
        pub const cyan = "\x1B[46;1m";
        pub const white = "\x1B[47;1m";
    };
    pub const black = "\x1B[40m";
    pub const red = "\x1B[41m";
    pub const green = "\x1B[42m";
    pub const yellow = "\x1B[43m";
    pub const blue = "\x1B[44m";
    pub const magenta = "\x1B[45m";
    pub const cyan = "\x1B[46m";
    pub const white = "\x1B[47m";
};

const expect = std.testing.expect;

test "Spec init" {
    const spec = Color.Spec.init(.normal, .fg);
    std.log.warn(" {s}: {d}", .{ spec, spec.toInt() });
    try expect(spec.toInt() == 3);
}
test "Color init" {
    const col = Color.blue;
    std.log.warn(" {s}: {d}", .{ col, col.toInt() });
    try expect(Color.toInt(.blue) == 4);
}

test "Color toCode" {
    const spec = comptime Color.Spec.init(.normal, .bg);
    const col = comptime Color.red;
    const code = comptime col.toCode(spec);
    const pre = comptime col.toPre(spec);
    std.log.warn(" {s} + {s}: {s}", .{ col, spec, code });
    // try expect(std.mem.eql(u8, code, "102"));
    std.log.warn("Prefix len: {d}", .{spec.len()});
    std.log.warn("{s}m This should have bright red bg{s} and now reset", .{ pre, reset() });
    std.log.warn("{s} This should have bright red bg{s} and now reset", .{ Color.blue.bg(), reset() });
    try expect(std.mem.eql(u8, code, "41") and std.mem.eql(u8, pre, "\x1B[41"));
}
test "Color toPre" {
    const bgrfg = comptime Color.toPre(.green, .bright_fg);
    std.log.warn("{s}m This should have bright green fg{s} and now reset", .{ bgrfg, reset() });
    try expect(std.mem.eql(u8, bgrfg, "\x1B[92"));
}
test "Color bold" {
    const col = comptime Color.bold(.yellow, .bright_fg);
    std.log.warn("{s} This should be bright green fg and bold{s} and now reset", .{ col, reset() });
}
