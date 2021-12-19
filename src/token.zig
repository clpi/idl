const std = @import("std");

pub fn lex(allocator: std.mem.Allocator, inp: []u8) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(allocator);
    var lexer = Lexer.init(inp);
    while (lexer.next()) |ch| {
        switch (ch) {
            ' ' => {},
            '*' => try tokens.append(lexer.buildTokenType(.op_mul)),
            '\n' => try tokens.append(lexer.buildTokenType(.newline)),
            '.' => try tokens.append(lexer.buildTokenType(.op_period)),
            '%' => try tokens.append(lexer.buildTokenType(.op_mod)),
            '+' => try tokens.append(lexer.buildTokenType(.op_add)),
            '-' => try tokens.append(lexer.buildTokenType(.op_sub)),
            '?' => try tokens.append(lexer.buildTokenType(.op_question)),
            '<' => try tokens.append(lexer.followed('=', .op_le, .op_lt)),
            '>' => try tokens.append(lexer.followed('=', .op_ge, .op_gt)),
            '=' => try tokens.append(lexer.followed('=', .op_eq, .op_assign)),
            '!' => try tokens.append(lexer.followed('=', .op_ne, .kw_not)),
            '(' => try tokens.append(lexer.buildTokenType(.lpar)),
            ')' => try tokens.append(lexer.buildTokenType(.rpar)),
            '{' => try tokens.append(lexer.buildTokenType(.lbrace)),
            '}' => try tokens.append(lexer.buildTokenType(.rbrace)),
            ';' => try tokens.append(lexer.buildTokenType(.semicolon)),
            ':' => try tokens.append(lexer.buildTokenType(.colon)),
            ',' => try tokens.append(lexer.buildTokenType(.comma)),
            '&' => try tokens.append(try lexer.consec('&', .kw_and)),
            '|' => try tokens.append(try lexer.consec('|', .kw_or)),
            '/' => {
                if (try lexer.divOrComment()) |token| try tokens.append(token);
            },
            '_', 'a'...'z', 'A'...'Z' => try tokens.append(try lexer.identOrKw()),
            '"' => try tokens.append(try lexer.strLiteral()),
            '0'...'9' => try tokens.append(try lexer.intLiteral()),
            '\'' => try tokens.append(try lexer.intChar()),
            else => {},
        }
    }
    try tokens.append(lexer.buildTokenType(.eof));
    return tokens;
}

pub fn tokenListToString(allocator: std.mem.Allocator, token_list: std.ArrayList(Token)) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    var w = result.writer();
    for (token_list.items) |token| {
        const common_args = .{ token.line, token.col, token.ttype.toString() };
        if (token.val) |value| {
            const init_fmt = "{d:>5}{d:>7} {s:<15}";
            switch (value) {
                .str => |str| _ = try w.write(try std.fmt.allocPrint(
                    allocator,
                    init_fmt ++ "{s}\n",
                    common_args ++ .{str},
                )),
                .intl => |i| _ = try w.write(try std.fmt.allocPrint(
                    allocator,
                    init_fmt ++ "{d}\n",
                    common_args ++ .{i},
                )),
            }
        } else {
            _ = try w.write(try std.fmt.allocPrint(allocator, "{d:>5}{d:>7} {s}\n", common_args));
        }
    }
    return result.items;
}

pub const Lexer = struct {
    inp: []const u8,
    line: usize,
    col: usize,
    pos: usize,
    start: bool,

    const Self = @This();

    pub fn init(inp: []const u8) Lexer {
        return Lexer{
            .inp = inp,
            .line = 1,
            .col = 1,
            .pos = 0,
            .start = true,
        };
    }

    pub fn buildToken(self: Self) Token {
        return Token{ .line = self.line, .col = self.col };
    }

    pub fn buildTokenType(self: Self, ttype: TokenType) Token {
        return Token{ .line = self.line, .col = self.col, .ttype = ttype };
    }

    pub fn current(self: Self) u8 {
        return self.inp[self.pos];
    }

    pub fn next(self: *Self) ?u8 {
        if (self.start) self.start = false else {
            const isNewLine = self.current() == '\n';
            self.pos += 1;
            if (isNewLine) {
                self.col = 1;
                self.line += 1;
            } else self.col += 1;
        }
        if (self.pos >= self.inp.len) return null else return self.current();
    }

    pub fn peek(self: Self) ?u8 {
        if (self.pos + 1 >= self.inp.len) {
            return null;
        } else {
            return self.inp[self.pos + 1];
        }
    }

    pub fn divOrComment(self: *Self) LexerError!?Token {
        var outp = self.buildToken();
        if (self.peek()) |ch| {
            if (ch == '*') {
                _ = self.next();
                while (self.next()) |chs| {
                    if (chs == '*') {
                        if (self.peek()) |nch| {
                            if (nch == '/') {
                                _ = self.next();
                                return null;
                            }
                        }
                    }
                }
                return LexerError.EofInComment;
            }
        }
        outp.ttype = .op_div;
        return outp;
    }

    pub fn identOrKw(self: *Self) !Token {
        var outp = self.buildToken();
        const p_i = self.pos;
        while (self.peek()) |ch| : (_ = self.next()) {
            switch (ch) {
                '_', 'a'...'z', 'A'...'Z', '0'...'9' => {},
                else => break,
            }
        }
        const p_f = self.pos + 1;
        var st = self.inp[p_i..p_f];
        if (TokenType.isKw(st)) |ttype| {
            outp.ttype = ttype;
        } else {
            outp.ttype = .ident;
            outp.val = TokenVal{ .str = st };
        }
        return outp;
    }

    pub fn strLiteral(self: *Self) !Token {
        var outp = self.buildTokenType(.str);
        const p_i = self.pos;
        while (self.next()) |ch| {
            switch (ch) {
                '"' => break,
                '\n' => return LexerError.EolInStr,
                '\\' => {
                    switch (self.peek() orelse return LexerError.EofInStr) {
                        'n', '\\' => _ = self.next(),
                        else => return LexerError.UnknownEscSeq,
                    }
                },
                else => {},
            }
        } else {
            return LexerError.EofInStr;
        }
        const p_f = self.pos + 1;
        outp.val = TokenVal{ .str = self.inp[p_i..p_f] };
        return outp;
    }

    pub fn followed(self: *Self, by: u8, pos_type: TokenType, neg_type: TokenType) Token {
        var outp = self.buildToken();
        if (self.peek()) |ch| {
            if (ch == by) {
                _ = self.next();
                outp.ttype = pos_type;
            } else {
                outp.ttype = neg_type;
            }
        } else {
            outp.ttype = neg_type;
        }
        return outp;
    }

    pub fn consec(self: *Self, by: u8, ttype: TokenType) LexerError!Token {
        const outp = self.buildTokenType(ttype);
        if (self.peek()) |ch| {
            if (ch == by) {
                _ = self.next();
                return outp;
            } else {
                return LexerError.UnknownChar;
            }
        } else {
            return LexerError.UnknownChar;
        }
    }

    pub fn intLiteral(self: *Self) LexerError!Token {
        var outp = self.buildTokenType(.int);
        const p_i = self.pos;
        while (self.peek()) |ch| {
            switch (ch) {
                '0'...'9' => {
                    _ = self.next();
                },
                '_', 'a'...'z', 'A'...'Z' => {
                    return LexerError.InvalidNum;
                },
                else => break,
            }
        }
        const p_f = self.pos + 1;
        outp.val = TokenVal{
            .intl = std.fmt.parseInt(i32, self.inp[p_i..p_f], 10) catch {
                return LexerError.InvalidNum;
            },
        };
        return outp;
    }

    pub fn nextOrEmpty(self: *Self) LexerError!u8 {
        return self.next() orelse LexerError.EmptyCharConst;
    }

    pub fn intChar(self: *Self) LexerError!Token {
        var outp = self.buildTokenType(.int);
        switch (try self.nextOrEmpty()) {
            '\'', '\n' => return LexerError.EmptyCharConst,
            '\\' => {
                switch (try self.nextOrEmpty()) {
                    'n' => outp.val = TokenVal{ .intl = '\n' },
                    '\\' => outp.val = TokenVal{ .intl = '\\' },
                    else => return LexerError.EmptyCharConst,
                }
                switch (try self.nextOrEmpty()) {
                    '\'' => {},
                    else => return LexerError.EmptyCharConst,
                }
            },
            else => {
                outp.val = TokenVal{ .intl = self.current() };
                switch (try self.nextOrEmpty()) {
                    '\'' => {},
                    else => return LexerError.MulticharConst,
                }
            },
        }
        return outp;
    }
};

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
    kw_and,
    kw_or,
    kw_does,
    kw_if,
    kw_do,
    kw_with,
    kw_my,
    kw_get,
    kw_else,
    kw_while,
    kw_print,
    kw_has,
    kw_as,
    kw_have,
    kw_put,
    kw_set,
    kw_for,
    kw_will,
    ident,
    int,
    str,
    eof,

    pub fn isKw(inp: []const u8) ?TokenType {
        if (std.mem.eql(u8, inp, "print")) {
            return .kw_print;
        } else if (std.mem.eql(u8, inp, "put")) {
            return .kw_put;
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
        } else if (std.mem.eql(u8, inp, "not")) {
            return .kw_not;
        } else if (std.mem.eql(u8, inp, "can")) {
            return .kw_can;
        } else if (std.mem.eql(u8, inp, "will")) {
            return .kw_will;
        } else if (std.mem.eql(u8, inp, "for")) {
            return .kw_for;
        } else if (std.mem.eql(u8, inp, "set")) {
            return .kw_set;
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
            .kw_not => "kw_not",
            .kw_is => "kw_is",
            .kw_as => "kw_as",
            .kw_does => "kw_does",
            .kw_so => "kw_so",
            .op_assign => "op_assign",
            .lpar => "lpar",
            .rpar => "rpar",
            .newline => "newline",
            .lbrace => "lbrace",
            .rbrace => "rbrace",
            .semicolon => "semicolon",
            .colon => "colon",
            .comma => "comma",
            .kw_can => "kw_can",
            .kw_and => "kw_and",
            .kw_will => "kw_will",
            .kw_have => "kw_have",
            .kw_has => "kw_has",
            .kw_my => "kw_my",
            .kw_get => "kw_get",
            .kw_do => "kw_do",
            .kw_with => "kw_with",
            .kw_for => "kw_for",
            .kw_or => "kw_or",
            .kw_if => "kw_if",
            .kw_else => "kw_else",
            .kw_while => "kw_while",
            .kw_print => "kw_print",
            .kw_set => "kw_set",
            .kw_put => "kw_put",
            .ident => "ident",
            .str => "str",
            .int => "int",
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

pub const LexerError = error{
    EmptyCharConst,
    UnknownEscSeq,
    MulticharConst,
    EofInComment,
    EofInStr,
    EolInStr,
    UnknownChar,
    InvalidNum,
};
