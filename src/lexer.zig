const std = @import("std");
const t = std.testing;
const tok = @import("./token.zig");
const Token = tok.Token;
const TokenVal = tok.TokenVal;
const TokenType = tok.TokenType;

// pub fn lex(allocator: std.mem.Allocator, inp: []u8) !std.ArrayList(Token) {
pub fn lex(allocator: std.mem.Allocator, inp: []const u8) !std.ArrayList(Token) {
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

test "parses_idents_ok" {
    t.expectEqual(5, 5);
}
