const std = @import("std");
const colors = @import("../term/colors.zig");
const Color = colors.Color;
const ast = @import("./ast.zig");
const Ast = ast.Ast;
const Fg = colors.Fg;
const eq = std.mem.eql;
const meta = std.meta;
const mem = std.mem;
const enums = std.enums;
const fieldNames = meta.fieldNames;
const lex = @import("./lexer.zig");
const ops = @import("./token/op.zig");
const bloc = @import("./token/block.zig");
const tt = @import("./token/type.zig");
const kws = @import("./token/kw.zig");
pub const Kind = Token.Kind;
pub const Op = ops.Op;
pub const Block = bloc.Block;
pub const @"Type" = tt.@"Type";
pub const Cursor = @import("./expr.zig").Cursor;
pub const Kw = kws.Kw;

pub const TokenError = error{
    UnexpectedToken,
};

pub const Token = struct {
    pos: Cursor,
    offset: usize,
    kind: Token.Kind = .unknown,
    val: ?Token.Val = null,

    const Self = @This();

    pub fn initKind(k: Token.Kind, v: ?Token.Val) Self {
        return Self{
            .pos = Cursor.default(),
            .offset = 0,
            .kind = k,
            .val = v,
        };
    }

    // TODO Actually manually define precedence
    pub fn hasPrecedence(self: Self, other: Self) bool {
        return @enumToInt(self.kind) > @enumToInt(other.kind);
    }

    pub const Kind = union(enum(u8)) {
        op: Op,
        type: @"Type",
        kw: Kw,
        block: Block,
        unknown,
        eof,

        pub fn op(oper: Op) Token.Kind {
            return Token.Kind{ .op = oper };
        }
        pub fn kwd(kw: Kw) Token.Kind {
            return Token.Kind{ .kw = kw };
        }

        pub const isKw = Kw.isKw;
        pub const isOp = Op.isOp;
        pub const isBool = @"Type".isBool;
        pub const isBlock = Block.isBlock;

        pub fn toStr(self: Token.Kind) []const u8 {
            return switch (self) {
                .eof => "eof",
                .unknown => "unknown",
                .op => |opt| Op.toStr(opt),
                .kw => |kwt| Kw.toStr(kwt),
                .type => |tyt| tyt.toStr(),
                .block => |blt| blt.toStr(),
            };
        }

        pub fn fromString(inp: []const u8) ?Token.Kind {
            inline for (std.meta.fields(Token.Kind)) |field| {
                if (eq(u8, inp, field.name)) {
                    return @field(Token.Kind, field.name);
                }
            }
            return null;
        }
    };

    pub const Val = union(enum) {
        intl: i32,
        float: f32,
        byte: u8,
        str: []const u8,
    };

    pub const Iter = struct {
        allocator: std.mem.Allocator,
        items: std.ArrayList(Token),
        current: usize,

        const Self = @This();

        pub fn init(a: std.mem.Allocator, tok: std.ArrayList(Token)) Token.Iter {
            return Token.Iter{ .current = 0, .items = tok, .allocator = a };
        }

        pub fn next(self: *Token.Iter) ?Token {
            if (self.items.popOrNull()) |token| {
                return token;
            } else return null;
        }

        pub fn fromStr(input: []const u8, a: std.mem.Allocator) !Token.Iter {
            var ts = std.ArrayList([]const u8).init(a);
            var tl = std.ArrayList(Token).init(a);
            const token_ln = std.mem.tokenize(u8, input, "\n");
            for (token_ln) |tokln| {
                for (tokln) |tok| {
                    try ts.append(tok);
                }
            }
            return Iter{ .allocator = a, .items = tl };
        }
    };
};

pub fn tokFile(gpa: std.mem.Allocator, comptime path: ?[]const u8) !void {
    const test_file = if (path) |p| @embedFile(p) else @embedFile("../../res/test.is");
    // var arena = std.heap.ArenaAllocator.init(gpa);
    // .respOk("Welcome to the Idlang TOKENIZER REPL\n");
    var lx = lex.Lexer.init(test_file, gpa);
    _ = try lx.lex();
    const tokens = try lx.tokenListToString();
    _ = try std.io.getStdOut().writeAll(tokens);
    var at = ast.Ast.create(gpa, test_file);
    std.debug.print("AST DEBUG: {}", .{at});
}

const expect = std.testing.expect;
const expectStrEq = std.testing.expectEqualStrings;

test "Kw toStr" {
    const kw = Token.Kind{ .kw = Kw.all };
    const kwstr = kw.toStr();
    try expectStrEq("all", kwstr);
}

test "Kw isKw" {
    const kw = "does";
    const tok = Kw.isKw(kw);
    if (tok) |tk| {
        std.log.warn("{s}", .{tk.toStr()});
        try expect(true);
    } else {
        try expect(false);
    }
}

test "Block isBlock" {
    const bcmt = "--|";
    const tok = Token.Kind.isBlock(bcmt);
    if (tok) |tk| {
        std.log.warn("{s}", .{tk.toStr()});
        try expect(true);
    } else {
        try expect(false);
    }
}

test "Op isOp" {
    const dcmt = "-!";
    const tok = Token.Kind.isOp(dcmt);
    if (tok) |tk| {
        std.log.warn("{s}", .{tk.toStr()});
        try expect(true);
    } else {
        try expect(false);
    }
}
// test "Op isType" {
//     const cstr: [_]u8 = "\"literal str\"";
//     const o1 = isType(cstr);
//     try expect(o1 == Op.comment);
// }
