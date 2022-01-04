const std = @import("std");
const token = @import("../token.zig");
const ast = @import("../ast.zig");
const fieldNames = std.meta.fieldNames;
const eq = std.mem.eq;
const TokenError = token.TokenError;
const Token = token.Token;
const Kind = Token.Kind;
const Ast = ast.Ast;
pub const Block = @import("./op.zig");
const Op = @import("./op.zig").@"Type";
const Kw = @import("./kw.zig").Kw;

pub const @"Type" = union(enum) {
    pub const Self = @This();

    const tv = .{ "true", "True", "TRUE" };
    const fv = .{ "false", "False", "FALSE" };

    seq,
    none,
    ident: []const u8,
    int: usize,
    float: f32,
    byte: u8,
    str: []const u8,
    bool: bool,

    pub fn isType(ty: []const u8) TokenError!?@"Type" {
        var squote = false;
        var dquote = false;
        var bracket = false;
        var braces = false;
        var wd: [32]u8 = undefined;
        var ct = 0;
        while (ty.next()) |ch| {
            if (ct == 0) {
                switch (ch) {
                    '\'' => squote = true,
                    '"' => dquote = true,
                    '[' => bracket = true,
                    '{' => braces = true,
                    'A'...'Z', 'a'...'z', '_', '0'...'9' => {
                        wd.append(ch);
                        continue;
                    },
                    else => return TokenError.UnexpectedToken,
                }
            } else {
                switch (ch) {
                    '\'' => if (squote) {
                        return @"Type"{ .byte = wd };
                    } else {
                        return @"Type"{ .ident = wd };
                    },
                    '"' => if (dquote) {
                        return @"Type"{ .str = wd };
                    } else {
                        dquote = true;
                    },
                    '}' => if (bracket) {
                        return @"Type"{ .seq = wd };
                    } else {
                        dquote = true;
                    },
                    '}' => if (bracket) {
                        return @"Type"{ .seq = wd };
                    } else {
                        dquote = true;
                    },
                    'A'...'Z', 'a'...'z', '_', '0'...'9' => {
                        wd.append(ch);
                        continue;
                    },
                    ' ' => return @"Type"{ .ident = wd },
                    else => return TokenError.UnexpectedToken,
                }
            }
            ct += 1;
        }
        switch (ty[0]) {
            'A'...'Z', 'a'...'z', '_', '0'...'9' => {
                return @"Type"{ .ident = ty };
            },
        }
    }

    pub fn toStr(ty: @"Type") []const u8 {
        return switch (ty) {
            .none => |_| std.meta.tagName(.none),
            .ident => |_| std.meta.tagName(.ident),
            .byte => |_| std.meta.tagName(.byte),
            .seq => std.meta.tagName(.seq),
            .int => |_| std.meta.tagName(.int),
            .float => |_| std.meta.tagName(.float),
            .str => |_| std.meta.tagName(.str),
            .bool => |bln| switch (bln) {
                true => "bool:t",
                false => "bool:f",
            },
        };
    }

    pub fn isBool(inp: []const u8) ?@"Type" {
        inline for (tv) |tval| {
            if (eq(u8, inp, tval)) {
                return @"Type"{ .bool = true };
            }
        }
        inline for (fv) |fval| {
            if (eq(u8, inp, fval)) {
                return @"Type"{ .bool = true };
            }
        }
        return null;
    }
};
