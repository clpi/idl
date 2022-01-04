const std = @import("std");
const token = @import("../token.zig");
const ast = @import("../ast.zig");
const fieldNames = std.meta.fieldNames;
const eq = std.mem.eq;
const TokenError = token.TokenError;
const Token = token.Token;
const Ast = ast.Ast;
const Kind = Token.Kind;
const @"Type" = @import("./type.zig").@"Type";
const Op = @import("./op.zig").Op;
const Kw = @import("./kw.zig").Kw;
const enums = std.enums;

pub const Block = union(enum(u8)) {
    const Self = @This();
    lpar: ?[]const u8,
    rpar: ?[]const u8,
    lbrace: ?[]const u8,
    rbrace: ?[]const u8,
    lbracket: ?[]const u8,
    rbracket: ?[]const u8,
    lstate: ?[]const u8,
    rstate: ?[]const u8,
    lattr: ?[]const u8,
    rattr: ?[]const u8,
    ldef: ?[]const u8,
    rdef: ?[]const u8,
    ltype: ?[]const u8,
    rtype: ?[]const u8,
    squote,
    dquote,
    btick,
    lcomment, //comment left block
    rcomment,
    lque,
    rque,
    ldoc,
    rdoc,
    lawait,
    rawait,
    llnquery,
    rlnquery,
    ldocln,
    rdocln,
    lawaitque,
    rawaitque,
    ldata: ?[]const u8,
    rdata: ?[]const u8,
    lsynth: ?[]const u8,
    rsynth: ?[]const u8,

    pub const Info = struct {
        ident: ?[]const u8,
        state: Rel,

        pub const Rel = union(enum(u2)) { start, end, outside };
    };

    pub fn isBlockStart(self: Block) Block.Info.Rel {
        return switch (@tagName(self)[0]) {
            'l' => .start,
            'r' => .end,
            else => .outside,
        };
    }

    pub fn brace(id: ?[]const u8, rel: Block.Rel) Block {
        switch (rel) {
            .start, .outside => Block{ .lbrace = id },
            .end => Block{ .rbrace = id },
        }
        return Block.lbrace;
    }

    pub fn state(id: ?[]const u8, rel: Block.Rel) Block {
        switch (rel) {
            .start, .ambiguous => Block.State{ .lbrace = id },
            .end => Block.State{ .rbrace = id },
        }
        return Block.lbrace;
    }

    pub const ltypesym = '<';
    pub const rtypesym = '>';

    // All are used as line statements
    pub const sblock = .{ "-|", "|-" };
    pub const ablock = .{ "-:", ":-" };
    pub const inlque = .{ "-?", "?-" };
    pub const doclnc = .{ "-!", "!-" };
    pub const databl = .{ ".:", ":." };

    pub const bcomment = .{ "--|", "|--" };
    pub const dcomment = .{ "--!", "!--" };
    pub const defblock = .{ "--:", ":--" };
    pub const queblock = .{ "--?", "?--" };

    pub const waitblock = .{ "..!", "!.." };
    pub const waitquery = .{ "..?", "?.." };
    pub const synthesis = .{ "..:", ":.." };

    pub fn isBlock(inp: []const u8) Block {
        return switch (inp[0]) {
            '(' => .lpar,
            ')' => .rpar,
            '[' => .lbracket,
            ']' => .lbracket,
            '{' => .lbrace,
            '}' => .rbrace,
            '\'' => .squote,
            '"' => .dquote,
            '`' => .btick,
            '-' => {
                if (eq(u8, bcomment[0], inp)) {
                    return .lcomment;
                } else if (eq(u8, bcomment[1], inp)) {
                    return .rcomment;
                } else {
                    return null;
                }
            },
            else => null,
        };
    }

    pub fn toStr(bl: Block) []const u8 {
        return @tagName(bl);
    }
};
