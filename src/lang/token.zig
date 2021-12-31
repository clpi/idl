const std = @import("std");

pub const TokenType = enum {
    unknown,
    op_mul,
    op_div,
    op_mod,
    op_add,
    op_sub,
    op_neg,
    op_gt,
    op_lt,
    op_ge,
    op_period,
    op_question,
    op_le,
    op_arrow,
    op_eq,
    op_ne,
    op_assign,
    lpar,
    rpar,
    lbrace,
    rbrace,
    semicolon,
    comma,
    colon,
    newline,
    kw_not,
    kw_so,
    kw_is,
    kw_can,
    kw_to,
    kw_and,
    kw_or,
    kw_does,
    kw_if,
    kw_in,
    kw_use,
    kw_out,
    kw_do,
    kw_with,
    kw_my,
    kw_return,
    kw_get,
    kw_some,
    kw_self,
    kw_else,
    kw_while,
    kw_print,
    kw_has,
    kw_as,
    kw_of,
    kw_by,
    kw_let,
    kw_like,
    kw_type,
    kw_me,
    kw_loop,
    kw_then,
    kw_have,
    kw_put,
    kw_set,
    kw_for,
    kw_true,
    kw_false,
    kw_be,
    kw_will,
    kw_all,
    kw_any,
    kw_local,
    kw_str,
    kw_list,
    kw_float,
    kw_int,
    ident,
    list,
    int,
    float,
    str,
    eof,

    pub fn isKw(inp: []const u8) ?TokenType {
        if (std.mem.eql(u8, inp, "print")) {
            return .kw_print;
        } else if (std.mem.eql(u8, inp, "put")) {
            return .kw_put;
        } else if (std.mem.eql(u8, inp, "self")) {
            return .kw_self;
        } else if (std.mem.eql(u8, inp, "if")) {
            return .kw_if;
        } else if (std.mem.eql(u8, inp, "else")) {
            return .kw_else;
        } else if (std.mem.eql(u8, inp, "as")) {
            return .kw_as;
        } else if (std.mem.eql(u8, inp, "does")) {
            return .kw_does;
        } else if (std.mem.eql(u8, inp, "do")) {
            return .kw_do;
        } else if (std.mem.eql(u8, inp, "get")) {
            return .kw_get;
        } else if (std.mem.eql(u8, inp, "while")) {
            return .kw_while;
        } else if (std.mem.eql(u8, inp, "has")) {
            return .kw_has;
        } else if (std.mem.eql(u8, inp, "have")) {
            return .kw_have;
        } else if (std.mem.eql(u8, inp, "and")) {
            return .kw_and;
        } else if (std.mem.eql(u8, inp, "so")) {
            return .kw_so;
        } else if (std.mem.eql(u8, inp, "with")) {
            return .kw_with;
        } else if (std.mem.eql(u8, inp, "or")) {
            return .kw_or;
        } else if (std.mem.eql(u8, inp, "my")) {
            return .kw_my;
        } else if (std.mem.eql(u8, inp, "is")) {
            return .kw_is;
        } else if (std.mem.eql(u8, inp, "some")) {
            return .kw_some;
        } else if (std.mem.eql(u8, inp, "not")) {
            return .kw_not;
        } else if (std.mem.eql(u8, inp, "let")) {
            return .kw_let;
        } else if (std.mem.eql(u8, inp, "can")) {
            return .kw_can;
        } else if (std.mem.eql(u8, inp, "me")) {
            return .kw_me;
        } else if (std.mem.eql(u8, inp, "will")) {
            return .kw_will;
        } else if (std.mem.eql(u8, inp, "for")) {
            return .kw_for;
        } else if (std.mem.eql(u8, inp, "type")) {
            return .kw_type;
        } else if (std.mem.eql(u8, inp, "like")) {
            return .kw_like;
        } else if (std.mem.eql(u8, inp, "of")) {
            return .kw_of;
        } else if (std.mem.eql(u8, inp, "by")) {
            return .kw_by;
        } else if (std.mem.eql(u8, inp, "in")) {
            return .kw_in;
        } else if (std.mem.eql(u8, inp, "use")) {
            return .kw_use;
        } else if (std.mem.eql(u8, inp, "out")) {
            return .kw_out;
        } else if (std.mem.eql(u8, inp, "to")) {
            return .kw_to;
        } else if (std.mem.eql(u8, inp, "set")) {
            return .kw_set;
        } else if (std.mem.eql(u8, inp, "all")) {
            return .kw_all;
        } else if (std.mem.eql(u8, inp, "any")) {
            return .kw_any;
        } else if (std.mem.eql(u8, inp, "then")) {
            return .kw_then;
        } else if (std.mem.eql(u8, inp, "false")) {
            return .kw_false;
        } else if (std.mem.eql(u8, inp, "return")) {
            return .kw_return;
        } else if (std.mem.eql(u8, inp, "true")) {
            return .kw_true;
        } else if (std.mem.eql(u8, inp, "be")) {
            return .kw_be;
        } else if (std.mem.eql(u8, inp, "loop")) {
            return .kw_loop;
        } else if (std.mem.eql(u8, inp, "local")) {
            return .kw_local;
        } else if (std.mem.eql(u8, inp, "int")) {
            return .kw_int;
        } else if (std.mem.eql(u8, inp, "str")) {
            return .kw_str;
        } else if (std.mem.eql(u8, inp, "list")) {
            return .kw_list;
        } else if (std.mem.eql(u8, inp, "float")) {
            return .kw_float;
        } else return null;
    }

    pub fn fromString(inp: []const u8) ?TokenType {
        inline for (std.meta.fields(TokenType)) |field| {
            if (std.mem.eql(u8, inp, field.name)) {
                return @field(TokenType, field.name);
            }
        }
        return null;
    }

    pub fn toString(self: @This()) []const u8 {
        return switch (self) {
            .unknown => "unknown",
            .op_mul => "op_mul",
            .op_div => "op_div",
            .op_mod => "op_mod",
            .op_add => "op_add",
            .op_sub => "op_sub",
            .op_neg => "op_neg",
            .op_gt => "op_gt",
            .op_ge => "op_ge",
            .op_le => "op_le",
            .op_lt => "op_lt",
            .op_eq => "op_eq",
            .op_question => "op_question",
            .op_period => "op_period",
            .op_ne => "op_ne",
            .op_assign => "op_assign",
            .lpar => "lpar",
            .rpar => "rpar",
            .newline => "newline",
            .lbrace => "lbrace",
            .rbrace => "rbrace",
            .semicolon => "semicolon",
            .colon => "colon",
            .comma => "comma",
            .kw_not => "kw_not",
            .kw_is => "kw_is",
            .kw_as => "kw_as",
            .kw_does => "kw_does",
            .kw_so => "kw_so",
            .kw_all => "kw_all",
            .kw_any => "kw_any",
            .kw_can => "kw_can",
            .kw_some => "kw_some",
            .kw_and => "kw_and",
            .kw_will => "kw_will",
            .kw_have => "kw_have",
            .kw_has => "kw_has",
            .kw_my => "kw_my",
            .kw_int => "kw_int",
            .kw_float => "kw_float",
            .kw_str => "kw_str",
            .kw_list => "kw_list",
            .kw_me => "kw_me",
            .kw_loop => "kw_loop",
            .kw_self => "kw_self",
            .kw_return => "kw_return",
            .kw_get => "kw_get",
            .kw_let => "kw_let",
            .kw_do => "kw_do",
            .kw_then => "kw_then",
            .kw_be => "kw_be",
            .kw_with => "kw_with",
            .kw_for => "kw_for",
            .kw_or => "kw_or",
            .kw_if => "kw_if",
            .kw_of => "kw_of",
            .kw_by => "kw_by",
            .kw_like => "kw_like",
            .kw_local => "kw_local",
            .kw_type => "kw_type",
            .op_arrow => "op_arrow",
            .kw_else => "kw_else",
            .kw_while => "kw_while",
            .kw_print => "kw_print",
            .kw_to => "kw_to",
            .kw_set => "kw_set",
            .kw_in => "kw_in",
            .kw_use => "kw_in",
            .kw_out => "kw_out",
            .kw_put => "kw_put",
            .ident => "ident",
            .str => "str",
            .kw_true => "kw_true",
            .kw_false => "kw_false",
            .int => "int",
            .list => "list",
            .float => "float",
            .eof => "eof",
        };
    }
};

pub const TokenVal = union(enum) {
    intl: i32,
    str: []const u8,
};

pub const Token = struct {
    line: usize,
    col: usize,
    ttype: TokenType = .unknown,
    val: ?TokenVal = null,
};
