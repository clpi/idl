const std = @import("std");
const testing = std.testing;
const tok = @import("./token.zig");
const ascii = std.ascii;
const Token = tok.Token;
const tfmt = @import("./fmt.zig");
const colors = @import("../term/colors.zig");
const Color = colors.Color;
const Kind = Token.Kind;
const Val = Token.Val;
const Op = Kind.Op;
const Kw = Kind.Kw;
const Block = Kind.Block;
const lg = std.log.scoped(.lexer);

// pub fn lex(allocator: std.mem.Allocator, inp: []u8) !std.ArrayList(Token) {

pub const Lexer = struct {
    inp: []const u8,
    tokens: std.ArrayList(Token),
    line: usize,
    col: usize,
    pos: usize,
    start: bool,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(inp: []const u8, a: std.mem.Allocator) Lexer {
        return Lexer{
            .inp = inp,
            .tokens = std.ArrayList(Token).init(a),
            .line = 1,
            .col = 1,
            .pos = 0,
            .start = true,
            .allocator = a,
        };
    }
    pub fn lex(self: *Self) !std.ArrayList(Token) {
        while (self.next()) |ch| {
            switch (ch) {
                ' ' => {},
                '*' => try self.tokens.append(self.buildOp(.mul)),
                '\n' => try self.tokens.append(self.buildOp(.newline)),
                '.' => _ = try self.addToken(try self.periodOrOther()),
                '%' => try self.tokens.append(self.buildOp(.mod)),
                '+' => try self.tokens.append(self.buildOp(.add)),
                '-' => _ = try self.addToken(try self.subOrOther()),
                '!' => _ = try self.addToken(try self.exclOrOther()),
                '?' => try self.tokens.append(self.buildOp(.ques)),
                '<' => try self.tokens.append(self.followed('=', Kind{ .op = .le }, Kind{ .op = .lt })),
                '>' => try self.tokens.append(self.followed('=', Kind{ .op = .ge }, Kind{ .op = .gt })),
                '=' => try self.tokens.append(self.followed('=', Kind{ .op = .eq_comp }, Kind{ .op = .assign })),
                '(' => try self.tokens.append(self.buildBlock(.lpar)),
                ')' => try self.tokens.append(self.buildBlock(.rpar)),
                '{' => try self.tokens.append(self.buildBlock(Block{ .lbrace = null })),
                '}' => try self.tokens.append(self.buildBlock(Block{ .rbrace = null })),
                ';' => try self.tokens.append(self.buildOp(.semicolon)),
                ':' => _ = try self.addToken(try self.colonOrOther()),
                ',' => try self.tokens.append(self.buildOp(.comma)),
                '&' => try self.tokens.append(try self.consec('&', Kind{ .op = .amp })),
                '|' => _ = try self.addToken(try self.pipeOrOther()),
                '/' => _ = if (try self.divOrComment()) |token| try self.tokens.append(token),
                '_', 'a'...'z', 'A'...'Z' => try self.tokens.append(try self.identOrKw()),
                '"' => try self.tokens.append(try self.strLiteral()),
                '0'...'9' => try self.tokens.append(try self.intLiteral()),
                '\'' => try self.tokens.append(try self.intChar()),
                else => {},
            }
        }
        try self.tokens.append(self.buildKind(Token.Kind.eof));
        return self.tokens;
    }

    pub fn addToken(self: *Self, tokn: ?Token) !?Token {
        if (tokn) |token| {
            _ = self.next();
            self.tokens.append(token) catch {
                return LexerError.OutOfSpace;
            };
            return token;
        } else return null;
    }

    pub fn tokenListToString(self: Self) ![]u8 {
        var st = std.ArrayList(u8).init(self.allocator);
        for (self.tokens.items) |token| {
            const res = try tfmt.write(token, self.allocator);
            try st.appendSlice(res);
        }
        return st.allocatedSlice();
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

    // Called when: found '/', need to know if next char is * or else
    pub fn divOrComment(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| if (ch == '*') {
            _ = self.next();
            while (self.next()) |chs| if (chs == '*') {
                if (self.peek()) |nch| if (nch == '/') {
                    _ = self.next();
                    return null;
                };
            };
            return LexerError.EofInComment;
        };
        return self.buildOp(Op.div);
    }

    // Called when: found ':', need to know if next char is * or else
    pub fn colonOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk = switch (ch) {
                '>' => self.buildOp(Op.farrow),
                '-' => {
                    _ = self.next();
                    if (self.peek()) |chn| {
                        return switch (chn) {
                            '|' => self.buildBlock(Block.lcomment),
                            '?' => self.buildBlock(Block.lque),
                            '!' => self.buildBlock(Block.ldoc),
                            ':' => self.buildBlock(Block{ .ldef = null }),
                            else => self.buildBlock(Block{ .rattr = null }),
                        };
                    }
                    return LexerError.EofInComment;
                },
                '=' => self.buildOp(Op.sub_eq),
                '|' => self.buildBlock(Block{ .lstate = null }),
                '!' => self.buildBlock(Block.ldocln),
                '?' => self.buildBlock(Block.llnquery),
                ':' => self.buildOp(Op.abstractor),
                '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.buildOp(Op.faccess),
                ' ' => self.buildOp(Op.colon),
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
    }
    pub fn subOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk = switch (ch) {
                '>' => self.buildOp(Op.farrow),
                '-' => {
                    _ = self.next();
                    if (self.peek()) |chn| {
                        return switch (chn) {
                            '|' => self.buildBlock(Block.lcomment),
                            '?' => self.buildBlock(Block.lque),
                            '!' => self.buildBlock(Block.ldoc),
                            ':' => self.buildBlock(Block{ .ldef = null }),
                            else => self.buildOp(Op.comment),
                        };
                    }
                    return LexerError.EofInComment;
                },
                '=' => self.buildOp(Op.sub_eq),
                '|' => self.buildBlock(Block{ .lstate = null }),
                '!' => self.buildBlock(Block.ldocln),
                '?' => self.buildBlock(Block.llnquery),
                ':' => self.buildBlock(Block{ .lattr = null }),
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.buildOp(Op.sub),
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
    }

    // Called when: found '!', need to know if next char is * or else
    pub fn exclOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk: ?Token = switch (ch) {
                '=' => self.buildOp(Op.ne),
                '.' => {
                    _ = self.next();
                    if (self.peek()) |chn| {
                        return switch (chn) {
                            '.' => self.buildBlock(.rawait),
                            else => null,
                        };
                    }
                    return LexerError.EofInStr;
                },
                '-' => {
                    _ = self.next();
                    if (self.peek()) |chn| {
                        return switch (chn) {
                            '-' => self.buildBlock(.rdoc),
                            else => self.buildBlock(.rdocln),
                        };
                    }
                    return LexerError.EofInStr;
                },
                '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.buildOp(Op.not),
                ' ' => self.buildOp(.excl),
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
    }

    // Called when: found '.', need to know if next char is * or else
    pub fn periodOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk: ?Token = switch (ch) {
                '.' => {
                    _ = self.next();
                    if (self.peek()) |chn| {
                        return switch (chn) {
                            '.' => {
                                _ = self.next();
                                const tr: ?Token = self.buildOp(Op.range);
                                return tr;
                            },
                            '!' => self.buildBlock(Block.lawait),
                            '?' => self.buildBlock(Block.lawaitque),
                            ':' => self.buildOp(Op.range_xr),
                            else => self.buildOp(Op.range_xx),
                        };
                    } else return LexerError.EofInComment;
                },
                '!' => self.buildOp(Op.access), // deref?
                '?' => self.buildOp(Op.access), // optional?
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.buildOp(Op.access),
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
    }

    // Called when: found '|', need to know if next char is - or else
    pub fn pipeOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk: ?Token = switch (ch) {
                '-' => {
                    _ = self.next();
                    if (self.peek()) |chn| return switch (chn) {
                        '-' => self.buildBlock(.rcomment),
                        else => self.buildBlock(Block{ .rstate = null }),
                    } else return LexerError.EofInStr;
                },
                '|' => self.buildOp(Op.@"or"),
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.buildOp(.pipe),
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
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

pub const Tokenizer = struct {
    it: std.mem.SplitIterator(u8),
    idk: usize,

    const Self = @This();

    pub fn init(input: []const u8) Self {
        return Self{ .it = std.mem.split(u8, input, "\n") };
    }

    pub fn next(self: *Self) !?Token {
        while (self.it.next()) |ln| {
            if (ln.len == 0) return null;
            var tok_it = std.mem.tokenize(u8, ln, " ");
            const content = tok_it.next();
            if (content) |t| {
                const token = Token.Kind.fromString(t);
                self.idx = t.index;
                return token;
            }
        }
        return null;
    }
};

pub const LexerError = error{ EmptyCharConst, UnknownEscSeq, MulticharConst, EofInComment, EofInStr, EolInStr, UnknownChar, InvalidNum, OutOfSpace } || std.fmt.ParseIntError;

test "parses_idents_ok" {
    testing.expectEqual(5, 5);
}
