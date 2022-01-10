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

pub const Kw = enum(u16) {
    // PREFI qualifier ops
    all = 0,
    some,
    any,
    once,
    ever,
    only,
    always,
    not,
    never,
    when,
    who,
    what,
    where,
    with,

    set = 25, //DECLARATTIONS  KW START
    type,
    be,
    put,
    @"for",
    @"init",
    get,
    have,
    use,
    @"return",
    print,
    let,
    loop,
    @"if",
    @"else",
    @"while",
    case,
    def,
    do,

    @"and" = 50, // START OF CONDITIONAL KW
    @"or",
    will,
    as,
    like,
    does,
    of,
    on,
    by,
    in,
    has,
    to,
    is,
    can,

    @"error" = 75, // START OF TYPE KW
    err,
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
    map,
    range,
    proc,
    str,
    float,

    // TYPE DESCRIPTOR START
    prop = 100,
    point,
    ref,
    qual,
    actual,
    abstr,
    local,
    global,
    this,
    state,
    data,
    that,

    so = 200, // MISC/UNASSIGNED KW START
    out,
    start,
    end,
    tst,
    tbd,

    // KW extenders
    until,

    const Self = @This();

    pub fn isKw(input: []const u8) ?Kw {
        inline for (@typeInfo(Kw).Enum.fields) |kword| {
            if (std.mem.eql(u8, input, kword.name)) {
                return @field(Kw, kword.name);
            }
        }
        return null;
        // return std.meta.stringToEnum(Kw, input);
    }

    // Redundant to have keyword + value types for float, etc.kwOp
    // should just consume the keyword and the value in one tuple?
    pub fn isType(kw: Kw) bool {
        const idx = @enumToInt(kw);
        return idx > 75 and idx < 100;
    }

    /// If keyword kw i(o s a verb in its postfix form, return true
    /// if keyword kw 
    pub fn isPrefix(kw: Kw) bool {
        const idx = @enumToInt(kw);
        return idx < 50;
    }

    pub fn isInfix(kw: Kw) bool {
        const idx = @enumToInt(kw);
        return idx >= 50 and idx < 75;
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

    pub fn tOp(kword: Kw) []const u8 {
        return @tagName(kword);
    }
    pub fn toType(kw: Kw) Kw {
        // const idx = @enumToInt(kw);
        return kw;
    }

    pub fn kwOp(kw: Kw) ?Op {
        return switch (kw) {
            Kw.@"or" => Op.@"or",
            Kw.@"and" => Op.@"and",
            .use => Op.use,
            else => null,
        };
    }

    pub fn toStr(k: Kw) []const u8 {
        return @tagName(k);
    }

    pub fn toNode(kw: Kw) Ast.Node {
        return Ast.Node.init(Token.initKind(Kind{ .kw = kw }));
    }
};

pub const KwAttrs = struct {
    verb: bool,
    aliases: [][]const u8,
};
