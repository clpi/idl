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

pub const TokenError = error{
    UnexpectedToken,
};

pub const Token = struct {
    line: usize,
    col: usize,
    kind: Token.Kind = .unknown,
    val: ?Token.Val = null,

    const Self = @This();

    pub const Kind = union(enum(u8)) {
        op: Token.Kind.Op,
        type: Token.Kind.@"Type",
        kw: Token.Kind.Kw,
        block: Token.Kind.Block,
        unknown,
        eof,

        pub fn op(oper: Token.Kind.Op) Token.Kind {
            return Kind{ .op = oper };
        }
        pub fn kwd(kw: Kw) Kind {
            return Kind{ .kw = kw };
        }

        pub const isKw = Kw.isKw;
        pub const isOp = Op.isOp;
        pub const isBool = @"Type".isBool;
        pub const isBlock = Block.isBlock;
        pub const isType = @"Type".isType;

        pub fn toStr(self: Token.Kind) []const u8 {
            return switch (self) {
                .eof => "eof",
                .unknown => "unknown",
                .op => |opt| Token.Kind.Op.toStr(opt),
                .kw => |kwt| Token.Kind.Kw.toStr(kwt),
                .type => |tyt| tyt.toStr(),
                .block => |blt| blt.toStr(),
            };
        }

        pub const Op = enum(i32) {
            at,
            amp,
            dol,
            pound,
            caret,
            tilde,
            bslash,
            pipe,
            mul,
            div,
            mod,
            add,
            sub,
            comma,
            gt,
            lt,
            ques,
            semicolon,
            colon,
            newline,
            excl,
            assign,
            period,
            neg,
            add_eq,
            div_eq,
            sub_eq,
            @"or",
            @"and",
            mul_eq,
            ln_doc_cmt,
            abstractor,
            pointer, // ::
            ref,
            assoc,
            range, // range : ...
            range_xl, // range non-inclusive of start, : :..
            range_xr, // range non-inclusive of end ..:
            range_xx, // non-inclusive range         ..
            comment,
            access,
            faccess,
            use,
            maybe,
            not,
            ask,
            le,
            ge,
            farrow,
            barrow,
            eq_comp,
            ne,
            query,
            double_gt,
            double_lt,
            defn,
            open_lt,
            close_lt,

            pub const range_sym = "..";
            pub const le_sym = "<=";
            pub const ge_sym = ">=";
            pub const farrow_sym = "->";
            pub const barrow_sym = "<-";
            pub const eq_compn_sym = "==";
            pub const query_sym = "=?";
            pub const nen_sym = "!=";
            pub const defn_sym = ":=";
            pub const commentn_sym = "--";
            pub const sub_eq_sym = "-=";
            pub const div_eq_sym = "/=";
            pub const add_eq_sym = "+=";
            pub const mul_eq_sym = "*=";
            pub const assoc_sym = "++";
            pub const double_gt_sym = ">>";
            pub const double_lt_sym = "<<";
            pub const line_doc_cmt = "-!";

            pub const Op = @This();

            pub fn toStr(oper: Token.Kind.Op) []const u8 {
                return @tagName(oper);
            }

            pub fn code(self: Self) i32 {
                return @enumToInt(self);
            }

            pub fn isCharOp(inp: u8) ?Token.Kind.Op {
                inline for (enums.values(Token.Kind.Op)) |value| {
                    if (value == inp) {
                        return @intToEnum(Token.Kind.Op, value);
                    }
                }
                return null;
            }

            pub fn isOp(comptime inp: []const u8) ?Token.Kind.Op {
                return switch (inp[0]) {
                    ' ' => null,
                    '-' => comptime switch (inp[1]) {
                        '>' => .farrow,
                        '-' => .comment,
                        '=' => .sub_eq,
                        else => .sub,
                    },
                    '.' => comptime switch (inp[1]) {
                        '.' => .range,
                        '_', 'a'...'z', 'A'...'Z', '0'...'9' => .access,
                        else => .period,
                    },
                    '*' => switch (inp[1]) {
                        '=' => .mul_eq,
                        '_', 'a'...'z', 'A'...'Z', '0'...'9' => .pointer,
                        else => .mul,
                    },
                    '\n' => .newline,
                    ',' => .comma,
                    '%' => .mod,
                    '+' => switch (inp[1]) {
                        '=' => .add_eq,
                        '+' => .assoc,
                        else => .add,
                    },
                    '?' => .ques,
                    '<' => switch (inp[1]) {
                        '<' => .double_lt,
                        '=' => .le,
                        '-' => .barrow,
                        'a'...'z', 'A'...'Z', '0'...'9', '_' => .open_lt,
                        else => .lt,
                    },
                    '>' => switch (inp[1]) {
                        '>' => .double_gt,
                        '=' => .ge,
                        else => .gt,
                    },
                    '=' => switch (inp[1]) {
                        '=' => .eq,
                        '?' => .query,
                        else => .assign,
                    },
                    '!' => switch (inp[1]) {
                        '=' => .ne,
                        else => .excl,
                    },
                    ';' => .semicolon,
                    ':' => switch (inp[1]) {
                        '=' => .def,
                        else => .colon,
                    },
                    '&' => .amp,
                    '|' => .pipe,
                    '/' => switch (inp[1]) {
                        '=' => .div_eq,
                        '/' => .comment,
                        else => null,
                    },
                    '$' => .dol,
                    '#' => .pound,
                    '@' => .at,
                    '^' => .caret,
                    '\\' => .bslash,
                    else => null,
                };
            }
        };

        pub const Kw = enum {
            not,
            so,
            is,
            can,
            to,
            @"and",
            @"or",
            does,
            @"if",
            in,
            use,
            out,
            do,
            with,
            my,
            @"return",
            get,
            some,
            self,
            @"else",
            @"while",
            print,
            has,
            as,
            of,
            by,
            let,
            like,
            type,
            me,
            loop,
            hen,
            have,
            put,
            set,
            @"for",
            be,
            will,
            all,
            any,
            local,

            pub const Kw = @This();

            pub fn isKw(inp: []const u8) ?Token.Kind.Kw {
                inline for (comptime fieldNames(Token.Kind.Kw)) |field, i| {
                    if (eq(u8, inp, field)) {
                        return @intToEnum(Token.Kind.Kw, i);
                    }
                }
                return null;
            }

            pub fn toStr(kword: Token.Kind.Kw) []const u8 {
                return @tagName(kword);
            }

            pub fn kwOp(self: Self) ?Kind.Op {
                return switch (self) {
                    Kind.Kw.@"or" => Kind.Op.@"or",
                    Kind.Kw.@"and" => Kind.Op.@"and",
                    Kind.Kw.use => Kind.Op.use,
                    else => null,
                };
            }

            pub fn toNode(self: Self) Ast.Node {
                return Ast.Node.init(self);
            }
        };

        pub const @"Type" = union(enum) {
            pub const Typ = @This();

            const tv = .{ "true", "True", "TRUE" };
            const fv = .{ "false", "False", "FALSE" };

            seq,
            ident: []const u8,
            int: usize,
            float: f32,
            byte: u8,
            str: []const u8,
            bool: bool,

            pub fn isType(ty: []const u8) TokenError!?Token.Kind.@"Type" {
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
                                return Token.Kind.@"Type"{ .byte = wd };
                            } else {
                                return Token.Kind.@"Type"{ .ident = wd };
                            },
                            '"' => if (dquote) {
                                return Token.Kind.@"Type"{ .str = wd };
                            } else {
                                dquote = true;
                            },
                            '}' => if (bracket) {
                                return Token.Kind.@"Type"{ .seq = wd };
                            } else {
                                dquote = true;
                            },
                            '}' => if (bracket) {
                                return Token.Kind.@"Type"{ .seq = wd };
                            } else {
                                dquote = true;
                            },
                            'A'...'Z', 'a'...'z', '_', '0'...'9' => {
                                wd.append(ch);
                                continue;
                            },
                            ' ' => return Token.Kind.@"Type"{ .ident = wd },
                            else => return TokenError.UnexpectedToken,
                        }
                    }
                    ct += 1;
                }
                switch (ty[0]) {
                    'A'...'Z', 'a'...'z', '_', '0'...'9' => {
                        return Token.Kind.@"Type"{ .ident = ty };
                    },
                }
            }

            pub fn toStr(ty: Token.Kind.@"Type") []const u8 {
                return switch (ty) {
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

            pub fn isBool(inp: []const u8) ?Token.Kind.@"Type" {
                inline for (tv) |tval| {
                    if (eq(u8, inp, tval)) {
                        return Token.Kind.@"Type"{ .bool = true };
                    }
                }
                inline for (fv) |fval| {
                    if (eq(u8, inp, fval)) {
                        return Token.Kind.@"Type"{ .bool = true };
                    }
                }
                return null;
            }
        };

        pub const Block = union(enum(u8)) {
            lpar,
            rpar,
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

            pub const Info = struct {
                ident: ?[]const u8,
                state: Rel,

                pub const Rel = union(enum(u2)) { start, end, outside };
            };

            pub fn isBlockStart(self: Token.Kind.Block) Token.Kind.Block.Info.Rel {
                return switch (@tagName(self)[0]) {
                    'l' => .start,
                    'r' => .end,
                    else => .outside,
                };
            }

            pub fn brace(id: ?[]const u8, rel: Kind.Block.Rel) Kind.Block {
                switch (rel) {
                    .start, .outside => Kind.Block{ .lbrace = id },
                    .end => Kind.Block{ .rbrace = id },
                }
                return Self.lbrace;
            }

            pub fn state(id: ?[]const u8, rel: Kind.Block.Rel) Kind.Block {
                switch (rel) {
                    .start, .ambiguous => Kind.Block.State{ .lbrace = id },
                    .end => Kind.Block.State{ .rbrace = id },
                }
                return Self.lbrace;
            }

            pub const ltypesym = '<';
            pub const rtypesym = '>';

            // All are used as line statements
            pub const sblock = .{ "-|", "|-" };
            pub const ablock = .{ "-:", ":-" };
            pub const inlque = .{ "-?", "?-" };
            pub const doclnc = .{ "-!", "!-" };

            pub const bcomment = .{ "--|", "|--" };
            pub const dcomment = .{ "--!", "!--" };
            pub const defblock = .{ "--:", ":--" };
            pub const queblock = .{ "--?", "?--" };

            pub const waitblock = .{ "..!", "!.." };
            pub const waitquery = .{ "..?", "?.." };

            pub const Block = @This();

            pub fn isBlock(inp: []const u8) ?Token.Kind.Block {
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

            pub fn toStr(bl: Token.Kind.Block) []const u8 {
                return @tagName(bl);
            }
        };

        pub fn fromString(inp: []const u8) ?Self.Kind {
            inline for (std.meta.fields(Self.Kind)) |field| {
                if (eq(u8, inp, field.name)) {
                    return @field(Self.Kind, field.name);
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

const expect = std.testing.expect;
const expectStrEq = std.testing.expectEqualStrings;

test "Token.Kind.Kw toStr" {
    const kw = Token.Kind{ .kw = Token.Kind.Kw.all };
    const kwstr = kw.toStr();
    try expectStrEq("all", kwstr);
}

test "Token.Kind.Kw isKw" {
    const kw = "does";
    const tok = Token.Kind.Kw.isKw(kw);
    if (tok) |tk| {
        std.log.warn("{s}", .{tk.toStr()});
        try expect(true);
    } else {
        try expect(false);
    }
}

test "Token.Kind.Block isBlock" {
    const bcmt = "--|";
    const tok = Token.Kind.isBlock(bcmt);
    if (tok) |tk| {
        std.log.warn("{s}", .{tk.toStr()});
        try expect(true);
    } else {
        try expect(false);
    }
}

test "Token.Kind.Op isOp" {
    const dcmt = "-!";
    const tok = Token.Kind.isOp(dcmt);
    if (tok) |tk| {
        std.log.warn("{s}", .{tk.toStr()});
        try expect(true);
    } else {
        try expect(false);
    }
}
// test "Token.Kind.Op isType" {
//     const cstr: [_]u8 = "\"literal str\"";
//     const o1 = Token.Kind.isType(cstr);
//     try expect(o1 == Token.Kind.Op.comment);
// }
