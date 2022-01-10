const std = @import("std");
const token = @import("./token.zig");
const Token = token.Token;
const Cursor = token.Cursor;
pub const Block = @import("./token/block.zig").Block;
pub const @"Type" = @import("./token/type.zig").Type;
pub const Kw = @import("./token/kw.zig").Kw;
pub const Op = @import("./token/op.zig").Op;

// TODO Figure out why this comes out all messed up

pub const Expr = union(enum(u16)) {
    decl: Op,
    infix: Infix,
    prefix: Prefix,
    postfix: Postfix,

    pub const Infix = packed struct {
        op: *Op,
        lhs: *@"Type",
        rhs: *@"Type",
    };

    pub const Prefix = packed struct {
        op: **Op,
        ta: *@"Type",
        tb: *@"Type",
    };

    pub const Postfix = packed struct {
        ta: *@"Type",
        tb: *@"Type",
        op: *Op,
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

pub const LoopExpr = union(enum) {
    forall: []token,
    whhile: struct {
        wexpr: []Token,
        else_expr: []Token,
    },
    labeled: struct {
        name: []const u8,
        loop: *LoopExpr,
    },
    loop: []Token,
};

pub const Conditional = struct {}{};
pub const ConditionalExpr = enum(u3) {
    If,
    When,
    Where,
    While,
    While,
    Who,
};

/// A declaration is performed in the infix-operator pattern: 
/// <Ident> <Kind> <Vis?> <Declaratio.Block?>
/// In some cases <Declaration.Value> can be multiple "words", indicating enumerationr of categories
///  Declaration.Block's contents or lack thereof are determined by the value
pub const Declaration = struct {
    @"export": false,
    ident: []const u8,
    ///  Must be in the set of 
    global: false,
    kind: Declaration.Kind,

    pub const Kind = union(enum(u8)) {
        local: bool = true, // will actually be the result of (is in global scope or ()
    };
};
