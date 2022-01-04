const std = @import("std");
const colors = @import("../term/colors.zig");
const Color = colors.Color;
const Token = @import("./token.zig").Token;
const Fg = colors.Fg;
const eq = std.mem.eql;
const meta = std.meta;
const mem = std.mem;
const enums = std.enums;
const fieldNames = meta.fieldNames;
const Self = Token;

pub fn kindColors(self: Token) type {
    return switch (comptime self.kind) {
        .unknown => |_| .{ .c1 = comptime Color.green.bold(.bright_fg), .c2 = Fg.green },
        .eof => |_| .{ .c1 = comptime Color.red.bold(.bright_fg), .c2 = Fg.red },
        .kw => |_| .{ .c1 = comptime Color.green.bold(.bright_fg), .c2 = Fg.green },
        .op => |_| .{ .c1 = comptime Color.yellow.bold(.bright_fg), .c2 = Fg.yellow },
        .type => |_| .{ .c1 = comptime Color.blue.bold(.bright_fg), .c2 = Fg.blue },
        .block => |_| .{ .c1 = comptime Color.magenta.bold(.bright_fg), .c2 = Fg.magenta },
    };
}

pub fn toStr(self: Self, value: []const u8) ![]const u8 {
    const init_fmt = "{s}{s}(L{d:>3}, C{d:>3}) {s} {s:<8}{s}{s}\t{s:<12}{s}";
    const d = comptime Color.white.dim(.bright_fg);
    const r = colors.reset();
    const c1 = switch (self.kind) {
        .unknown => |_| comptime Color.red.bold(.bright_fg),
        .eof => |_| comptime Color.cyan.bold(.bright_fg),
        .kw => |_| comptime Color.blue.bold(.bright_fg),
        .op => |_| comptime Color.magenta.bold(.normal_fg),
        .type => |_| comptime Color.green.bold(.bright_fg),
        .block => |_| comptime Color.yellow.bold(.bright_fg),
    };
    const c2 = switch (self.kind) {
        .unknown => |_| comptime Color.cyan.finish(.normal_fg),
        .eof => |_| comptime Color.red.finish(.normal_fg),
        .kw => |_| comptime Color.blue.finish(.normal_fg),
        .op => |_| comptime Color.magenta.finish(.normal_fg),
        .type => |_| comptime Color.green.finish(.normal_fg),
        .block => |_| comptime Color.yellow.finish(.normal_fg),
    };
    const w = switch (self.kind) {
        .op => comptime Color.white.finish(.bright_fg),
        .type => |ty| switch (ty) {
            .ident => comptime Color.green.bold(.bright_fg),
            .str => comptime Color.green.finish(.bright_fg),
            else => comptime Color.blue.finish(.bright_fg),
        },
        else => comptime Color.white.bold(.bright_fg),
    };
    var buf: [256]u8 = undefined;
    const common_args = .{ r, d, self.line, self.col, c1, @tagName(self.kind), r, c2, self.kind.toStr(), w };
    return try std.fmt.bufPrint(&buf, init_fmt ++ "{s}\n", common_args ++ .{value});
}
pub fn writeStr(self: Self, f: std.fs.File, a: std.mem.Allocator, s: []const u8) ![]const u8 {
    const c1 = switch (self.kind) {
        .unknown => |_| comptime Color.red.bold(.bright_fg),
        .eof => |_| comptime Color.cyan.bold(.bright_fg),
        .kw => |_| comptime Color.blue.bold(.bright_fg),
        .op => |_| comptime Color.magenta.bold(.normal_fg),
        .type => |_| comptime Color.green.bold(.bright_fg),
        .block => |_| comptime Color.yellow.bold(.bright_fg),
    };
    const c2 = switch (self.kind) {
        .unknown => |_| comptime Color.cyan.finish(.normal_fg),
        .eof => |_| comptime Color.red.finish(.normal_fg),
        .kw => |_| comptime Color.blue.finish(.normal_fg),
        .op => |_| comptime Color.magenta.finish(.normal_fg),
        .type => |_| comptime Color.green.finish(.normal_fg),
        .block => |_| comptime Color.yellow.finish(.normal_fg),
    };
    const d = comptime Color.white.dim(.bright_fg);
    const w = switch (self.kind) {
        .op => comptime Color.white.finish(.bright_fg),
        .type => |ty| switch (ty) {
            .ident => comptime Color.green.bold(.bright_fg),
            .str => comptime Color.green.finish(.bright_fg),
            else => comptime Color.blue.finish(.bright_fg),
        },
        else => comptime Color.white.bold(.bright_fg),
    };
    const r = colors.reset();
    const init_fmt = "{s}{s}(L{d:>3}, C{d:>3}) {s} {s:<8}{s}{s}\t{s:<12}{s}";
    const common_args = .{ r, d, self.line, self.col, c1, @tagName(self.kind), r, c2, self.kind.toStr(), w };
    const res = try std.fmt.allocPrint(a, init_fmt ++ "{s}\n", common_args ++ .{s});
    _ = try f.write(res);
    return res;
}
pub fn writeInt(self: Self, f: std.fs.File, a: std.mem.Allocator, s: u8) !void {
    const init_fmt = "{d:>5}{d:>7}  {s:<10}{s:<15}";
    const common_args = .{ self.line, self.col, self.kind.toStr() };
    const res = try std.fmt.allocPrint(a, init_fmt ++ "{d}\n", common_args ++ .{s});
    _ = try f.write(res);
    return res;
}

pub fn writeStdOut(self: Self, a: std.mem.Allocator, s: []const u8) ![]const u8 {
    var stdout = std.io.getStdOut();
    const r = try writeStr(self, stdout, a, s);
    return r;
}
pub fn write(self: Token, al: std.mem.Allocator) ![]const u8 {
    var tval = self.val;
    if (tval) |value| {
        return switch (value) {
            .str => |st| try writeStdOut(self, al, st),
            .byte => |_| try writeStdOut(self, al, ""),
            .float => |_| try writeStdOut(self, al, ""),
            .intl => |_| try writeStdOut(self, al, ""),
        };
    } else {
        return switch (self.kind) {
            .op => |o| return switch (o) {
                .newline, .semicolon => try writeStdOut(self, al, "::"),
                .sub => try writeStdOut(self, al, "-"),
                .add => try writeStdOut(self, al, "-"),
                .access => try writeStdOut(self, al, "|"),
                else => try writeStdOut(self, al, ""),
            },
            .block => |b| switch (b.isBlockStart()) {
                .start => try writeStdOut(self, al, "\x1b[0m\x1b[33m/- blk start -\\"),
                .end => try writeStdOut(self, al, "\x1b[0m\x1b[33m\\-  blk end  -/"),
                .outside => try writeStdOut(self, al, ""),
            },
            .eof => try writeStdOut(self, al, "EOF"),
            .unknown => try writeStdOut(self, al, "UNK"),
            .kw => |_| try writeStdOut(self, al, ""),
            .type => |ttype| {
                return switch (ttype) {
                    .ident => |iden| try writeStdOut(self, al, iden),
                    .byte => |_| try writeStdOut(self, al, ""),
                    .seq => |_| try writeStdOut(self, al, ""),
                    .int => |_| try writeStdOut(self, al, ""),
                    .float => |_| try writeStdOut(self, al, ""),
                    .str => |st| try writeStdOut(self, al, st),
                    .bool => |st| try writeStdOut(self, al, if (st) "true" else "false"),
                };
            },
        };
    }
}
