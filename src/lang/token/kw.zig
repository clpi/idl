const std = @import("std");
const token = @import("../token.zig");
const ast = @import("../ast.zig");
const fieldNames = std.meta.fieldNames;
const eq = std.mem.eql;
const TokenError = token.TokenError;
const Token = token.Token;
const Kind = Token.Kind;
const Op = Token.Kind.Op;
const Tty = @import("./type.zig").@"Type";
const Block = @import("./block.zig").Block;
const Ast = ast.Ast;

pub const Kw = enum {
    const Self = @This();

    so,
    out,
    my,
    some,
    self,
    like,
    type,
    me,
    hen,
    will,

    all, // QUALIFIERS
    any,

    set, // PREFIX ops
    be,
    put,
    do,
    @"for",
    get,
    have,
    not,
    use,
    @"return",
    print,
    let,
    loop,
    @"else",
    @"while",
    case,
    by,

    @"and", // INFIX ops
    @"or",
    as,
    does,
    of,
    @"if",
    in,
    has,
    to,
    is,
    can,
    with, // OR PREFIX?

    @"pub",
    public,
    loc,
    local,

    @"error",
    none,
    maybe,
    int,
    @"enum",
    @"class",
    num,
    rule,
    bool,
    tuple,
    seq,
    range,
    proc,
    str,
    float,

    // Redundant to have keyword + value types for float, etc.kwOp
    // should just consume the keyword and the value in one tuple?

    pub const Kwd = @This();

    pub fn isKw(inp: []const u8) ?Kw {
        inline for (comptime fieldNames(Kw)) |field, i| {
            if (eq(u8, inp, field)) {
                return @intToEnum(Kw, i);
            }
        }
        return null;
    }

    pub const Declaration = struct {
        name: []const u8,

        pub fn fromKw(kw: Kw) ?Declaration {
            switch (kw) {
                .rule,
                .range,
                .attribute,
                => {},
                else => null,
            }
        }
    };

    pub fn toStr(kword: Kw) []const u8 {
        return @tagName(kword);
    }

    pub fn kwOp(self: Block) ?Op {
        return switch (self) {
            Kw.@"or" => Op.@"or",
            Kw.@"and" => Op.@"and",
            .use => Op.use,
            else => null,
        };
    }

    pub fn toNode(self: Block) Ast.Node {
        return Ast.Node.init(self);
    }
};
