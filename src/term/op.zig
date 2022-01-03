const std = @import("std");
const cursor = @import("cursor.zig");
const Ansi = @import("./code.zig").Ansi;

pub fn escPrefix() []const u8 {
    return Ansi.esc() ++ "["; // length 2, or 3 if bright_bg
}

pub const Clear = enum(u8) {
    screen = 'J',
    line = 'K',

    const Self = @This();

    pub const To = enum(u8) {
        start = '0',
        end = '1',
        full = '2',

        pub fn toCode(comptime self: Clear.To) []const u8 {
            return comptime switch (self) {
                .to_start => "0",
                .to_end => "1",
                .entire => "2",
            };
        }
    };

    pub fn pre() []const u8 {
        return Ansi.esc() ++ "[";
    }

    pub fn toCode(comptime self: Self) []const u8 {
        comptime switch (self) {
            .screen => "J",
            .line => "K",
        };
    }

    pub fn toSeq(self: Self, rel: Clear.To) []const u8 {
        return Self.pre() ++ rel.toCode() ++ self.toCode();
    }

    pub fn clearScreen(rel: Clear.To) []const u8 {
        return Self.pre() ++ rel.toCode() ++ "J";
    }

    pub fn clearLine(rel: Clear.To) []const u8 {
        return Self.pre() ++ rel.toCode() ++ "K";
    }

    pub fn toEnd(self: Self) []const u8 {
        return self.toSeq(Clear.To.to_end);
    }

    pub fn toStart(self: Self) []const u8 {
        return self.toSeq(Clear.To.to_start);
    }

    pub fn entire(self: Self) []const u8 {
        return self.toSeq(Clear.To.entire);
    }
};
