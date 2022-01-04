const std = @import("std");
const token = @import("token");
const Token = token.Token;
const Op = Token.Kind.Op;

pub const Cursor = struct { line: usize, col: usize };

pub const Expr = union(enum(u16)) {
    decl: Op,
    infix: Infix,
    prefix: Prefix,
    postfix: Postfix,

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

    pub const Postfix = struct {
        ta: Token.Kind.@"Type",
        tb: Token.Kind.@"Type",
        op: Token.Kind.Op,
    };

    pub const Out = union(enum(i32)) {
        boolean: bool,
        int: i32,
        float: f32,
        str: []const u8,
        byte: u8,
        seq,
    };
};

pub const ExprBlock = struct {
    pos: Cursor,
    text: []const u8,
    block: Token.Kind.Block,
    tokens: []Token,

    const Self = @This();
};
