const col = struct {
    usingnamespace @import("./colors.zig");
};
const color = @import("colors.zig");
const Spec = color.Spec;
const Brightness = color.Spec.Brightness;
const Location = color.Spec.Location;
const Color = color.Color;
const code = @import("./code.zig");
const std = @import("std");
const fmt = std.fmt;
const print = std.debug.print;
const reader = std.io.getStdIn().reader();
const writer = std.io.getStdIn().writer();
const util = @import("../util.zig");

pub const Style = enum(u8) {
    reset = 0,
    bold = 1,
    dim = 2,
    italic = 3,
    underline = 4,
    blink = 5,
    reverse = 6,
    hidden = 7,
    eight = 8,
    nine = 9,
    default,

    const Self = @This();

    pub fn toCode(self: Self) []const u8 {
        return switch (self) {
            .default => "m",
            .reset => ";0m",
            .bold => ";1m",
            .dim => ";2m",
            .italic => ";3m",
            .underline => ";4m",
            .blink => ";5m",
            .reverse => ";6m",
            .hidden => ";7m",
            .eight => ";8m",
            .nine => ";9m",
        };
    }

    pub fn none() []const u8 {
        return "m";
    }
};

pub const FmtOpts = struct {
    bri: Brightness.normal,
    loc: Location = Location.fg,
    color: Color.white,
    styles: []Style,

    const Self = @This();

    pub fn init(bri: ?Brightness, loc: ?Location, co: ?Color) Self {
        return Self{
            .color = if (co) |c| c else Color.white,
            .loc = if (loc) |p| p else Location.fg,
            .bri = if (bri) |b| b else Brightness.normal,
            .styles = undefined,
        };
    }
};

pub const StyledStr = struct {
    buf: []u8,
    style: ?Style,
    args: anytype,

    const Self = @This();

    pub fn init(buf: []const u8, args: anytype) []const u8 {
        return Self{
            .buf = buf,
            .args = args,
        };
    }

    pub fn toString(self: Self) []const u8 {
        return self.color.fmtParams(self.loc, self.bri) ++ self.buf ++ "m";
    }

    pub fn withBold(self: Self) []const u8 {
        return self.color.fmtParams(self.loc, self.bri) ++ self.buf ++ "1;m";
    }

    pub fn print(self: Self) void {
        std.debug.print(self.buf, self.args);
    }
};

const expect = std.testing.expect;
test "Style toCode" {
    const cd = Style.toCode(.bold);
    std.log.warn("{s}", .{cd});
    try expect(std.mem.eql(u8, cd, ";1m"));
}
