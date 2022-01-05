const std = @import("std");
const token = @import("../token.zig");
const ast = @import("../ast.zig");
const fieldNames = std.meta.fieldNames;
const eq = std.mem.eq;
const TokenError = token.TokenError;
const Token = token.Token;
const Kind = Token.Kind;
const Ast = ast.Ast;
const enums = std.enums;
pub const Block = @import("./op.zig");
const @"Type" = @import("./type.zig").@"Type";
const Kw = @import("./kw.zig").Kw;

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
    exp,
    mod,
    add,
    bind,
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
    addressed,
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
    bbarrow,
    bfarrow,
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
    pub const gener_sym = "++";
    pub const assoc_sym = "<>";
    pub const double_gt_sym = ">>";
    pub const double_lt_sym = "<<";
    pub const line_doc_cmt = "-!";

    pub const Self = @This();

    pub fn toStr(oper: Op) []const u8 {
        return @tagName(oper);
    }

    pub fn code(self: Block) i32 {
        return @enumToInt(self);
    }

    pub fn isCharOp(inp: u8) ?Op {
        inline for (enums.values(Op)) |value| {
            if (value == inp) {
                return @intToEnum(Op, value);
            }
        }
        return null;
    }

    pub fn isOp(comptime inp: []const u8) ?Op {
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
