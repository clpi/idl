const std = @import("std");
const token = @import("token");
const Token = token.Token;

pub const Cursor = struct { line: usize, col: usize };

pub const Expr = union(enum(u16)) {
    infix: Infix,
    prefix: Prefix,

    pub const Infix = struct {
        op: Token.Kind.Op,
        lhs: Token.Kind.@"Type",
        rhs: Token.Kind.@"Type",
    };

    pub const Prefix = struct {
        op: Token.Kind.Op,
        ta: Token.Kind.@"Type",
        tb: Token.Kind.@"Type",
    };
};

pub const ExprBlock = struct {
    pos: Cursor,
    text: []const u8,
    block: Token.Kind.Block,
    tokens: []Token,

    const Self = @This();
};
