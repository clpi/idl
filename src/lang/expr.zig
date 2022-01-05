const std = @import("std");
pub const bloc = @import("./token/block.zig");
pub const tt = @import("./token/type.zig");
pub const kws = @import("./token/kw.zig");
pub const Kind = Token.Kind;
pub const Block = bloc.Block;
const token = @import("./token.zig");
const Token = token.Token;
const Op = Token.Kind.Op;

pub const Cursor = packed struct {
    line: usize,
    col: usize,
    const Self = @This();

    pub fn default() Cursor {
        return Cursor{ .line = 1, .col = 1 };
    }
    pub fn init(l: usize, c: usize) Cursor {
        return Cursor{ .line = l, .col = c };
    }
    pub fn newLine(self: *Cursor) void {
        self.line += 1;
        self.col = 1;
    }

    pub fn incrCol(self: *Cursor) void {
        self.col += 1;
    }

    pub fn incrRow(self: *Cursor) Cursor {
        self.row += 1;
    }
};

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
    sblock: Block,
    alloc: std.mem.Allocator,
    tokens: std.ArrayList(Token),

    const Self = @This();

    pub fn init(ln: usize, co: usize, block: Block, alloc: std.mem.Allocator) Self {
        const tk = std.ArrayList(Token).init(alloc);
        return Self{
            .pos = Cursor{ .line = ln, .col = co },
            .sblock = block,
            .alloc = alloc,
            .tokens = tk,
        };
    }
};
