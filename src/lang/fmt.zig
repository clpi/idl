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

pub fn toStr(self: Self, a: std.mem.Allocator, s: []const u8) ![]const u8 {
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
    const common_args = .{ r, d, self.pos.line, self.pos.col, c1, @tagName(self.kind), r, c2, self.kind.toStr(), w };
    return try std.fmt.allocPrint(a, init_fmt ++ "{s}\n", common_args ++ .{s});
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
            .str => |st| try toStr(self, al, st),
            .byte => |_| try toStr(self, al, ""),
            .float => |_| try toStr(self, al, ""),
            .intl => |_| try toStr(self, al, ""),
        };
    } else {
        return switch (self.kind) {
            .op => |o| return switch (o) {
                .newline, .semicolon => try toStr(self, al, "::"),
                .sub => try toStr(self, al, "-"),
                .add => try toStr(self, al, "-"),
                .access => try toStr(self, al, "|"),
                else => try toStr(self, al, ""),
            },
            .block => |b| switch (b.isBlockStart()) {
                .start => try toStr(self, al, "\x1b[0m\x1b[33m/- blk start -\\"),
                .end => try toStr(self, al, "\x1b[0m\x1b[33m\\-  blk end  -/"),
                .outside => try toStr(self, al, ""),
            },
            .eof => try toStr(self, al, "EOF"),
            .unknown => try toStr(self, al, "UNK"),
            .kw => |_| try toStr(self, al, ""),
            .type => |ttype| {
                return switch (ttype) {
                    .none => |_| try toStr(self, al, ""),
                    .ident => |iden| try toStr(self, al, iden),
                    .byte => |_| try toStr(self, al, ""),
                    .seq => |_| try toStr(self, al, ""),
                    .int => |_| try toStr(self, al, ""),
                    .float => |_| try toStr(self, al, ""),
                    .str => |st| try toStr(self, al, st),
                    .bool => |st| try toStr(self, al, if (st) "true" else "false"),
                };
            },
        };
    }
}
