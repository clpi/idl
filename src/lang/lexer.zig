const std = @import("std");
const t = std.testing;
const tok = @import("./token.zig");
const ascii = std.ascii;
const Token = tok.Token;
const Kind = Token.Kind;
const Val = Token.Val;
const Op = Kind.Op;
const Kw = Kind.Kw;
const Block = Kind.Block;

// pub fn lex(allocator: std.mem.Allocator, inp: []u8) !std.ArrayList(Token) {
pub fn lex(allocator: std.mem.Allocator, inp: []const u8) !std.ArrayList(Token) {
    var tks = std.ArrayList(Token).init(allocator);
    var lexer = Lexer.init(inp);
    while (lexer.next()) |ch| {
        switch (ch) {
            ' ' => {},
            '*' => try tks.append(lexer.buildOp(.mul)),
            '\n' => try tks.append(lexer.buildOp(.newline)),
            '.' => try tks.append(lexer.buildOp(.period)),
            '%' => try tks.append(lexer.buildOp(.mod)),
            '+' => try tks.append(lexer.buildOp(.add)),
            '-' => try tks.append(lexer.buildOp(.sub)),
            '?' => try tks.append(lexer.buildOp(.ques)),
            '<' => try tks.append(lexer.followed('=', Kind{ .op = .le }, Kind{ .op = .lt })),
            '>' => try tks.append(lexer.followed('=', Kind{ .op = .ge }, Kind{ .op = .gt })),
            '=' => try tks.append(lexer.followed('=', Kind{ .op = .eq_comp }, Kind{ .op = .assign })),
            '!' => try tks.append(lexer.followed('=', Kind{ .op = .ne }, Kind{ .op = .excl })),
            '(' => try tks.append(lexer.buildBlock(.lpar)),
            ')' => try tks.append(lexer.buildBlock(.rpar)),
            '{' => try tks.append(lexer.buildBlock(.lbrace)),
            '}' => try tks.append(lexer.buildBlock(.rbrace)),
            ';' => try tks.append(lexer.buildOp(.semicolon)),
            ':' => try tks.append(lexer.buildOp(.colon)),
            ',' => try tks.append(lexer.buildOp(.comma)),
            '&' => try tks.append(try lexer.consec('&', Kind{ .op = .amp })),
            '|' => try tks.append(try lexer.consec('|', Kind{ .op = .pipe })),
            '/' => {
                if (try lexer.divOrComment()) |token| try tks.append(token);
            },
            '_', 'a'...'z', 'A'...'Z' => try tks.append(try lexer.identOrKw()),
            '"' => try tks.append(try lexer.strLiteral()),
            '0'...'9' => try tks.append(try lexer.intLiteral()),
            '\'' => try tks.append(try lexer.intChar()),
            else => {},
        }
    }
    try tks.append(lexer.buildKind(Token.Kind.eof));
    return tks;
}

pub fn tokenListToString(allocator: std.mem.Allocator, token_list: std.ArrayList(Token)) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    var w = result.writer();
    for (token_list.items) |token| {
        const common_args = .{ token.line, token.col, token.kind.toStr() };
        if (token.val) |value| {
            const init_fmt = "{d:>5}{d:>7} {s:<15}";
            switch (value) {
                .str => |str| _ = try w.write(try std.fmt.allocPrint(
                    allocator,
                    init_fmt ++ "{s}\n",
                    common_args ++ .{str},
                )),
                .byte => |by| _ = try w.write(try std.fmt.allocPrint(allocator, init_fmt ++ "{d}\n", common_args ++ .{by})),
                .float => |fl| _ = try w.write(try std.fmt.allocPrint(allocator, init_fmt ++ "{d}\n", common_args ++ .{fl})),
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

    pub fn buildKind(self: Self, kind: Kind) Token {
        return Token{ .line = self.line, .col = self.col, .kind = kind };
    }

    pub fn buildOp(self: Self, op: Kind.Op) Token {
        return Token{ .line = self.line, .col = self.col, .kind = Kind{ .op = op } };
    }
    pub fn buildKw(self: Self, kw: Kind.Kw) Token {
        return Token{ .line = self.line, .col = self.col, .kind = Kind{ .kw = kw } };
    }
    pub fn buildBlock(self: Self, block: Kind.Block) Token {
        return Token{ .line = self.line, .col = self.col, .kind = Kind{ .block = block } };
    }
    pub fn buildType(self: Self, @"type": Kind.@"Type") Token {
        return Token{ .line = self.line, .col = self.col, .kind = Kind{ .type = @"type" } };
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
        outp.kind = Kind{ .op = Op.div };
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
        if (Kind.isKw(st)) |kwd| {
            outp.kind = Kind{ .kw = kwd };
        } else {
            outp.kind = Kind{ .type = Kind.@"Type"{ .ident = st } };
            outp.val = Val{ .str = st };
        }
        return outp;
    }

    pub fn strLiteral(self: *Self) !Token {
        var outp = self.buildType(Kind.@"Type"{ .str = "" });
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
        outp.val = Val{ .str = self.inp[p_i..p_f] };
        return outp;
    }

    pub fn followed(self: *Self, by: u8, pos_type: Kind, neg_type: Kind) Token {
        var outp = self.buildToken();
        if (self.peek()) |ch| {
            if (ch == by) {
                _ = self.next();
                outp.kind = pos_type;
            } else {
                outp.kind = neg_type;
            }
        } else {
            outp.kind = neg_type;
        }
        return outp;
    }

    pub fn consec(self: *Self, by: u8, kind: Kind) LexerError!Token {
        const outp = self.buildKind(kind);
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
        var outp = self.buildKind(Kind{ .type = Kind.@"Type"{ .int = 0 } });
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
        outp.val = Val{
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
        var outp = self.buildType(Kind.@"Type"{ .int = 0 });
        switch (try self.nextOrEmpty()) {
            '\'', '\n' => return LexerError.EmptyCharConst,
            '\\' => {
                switch (try self.nextOrEmpty()) {
                    'n' => outp.val = Val{ .intl = '\n' },
                    '\\' => outp.val = Val{ .intl = '\\' },
                    else => return LexerError.EmptyCharConst,
                }
                switch (try self.nextOrEmpty()) {
                    '\'' => {},
                    else => return LexerError.EmptyCharConst,
                }
            },
            else => {
                outp.val = Val{ .intl = self.current() };
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
