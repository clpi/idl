const std = @import("std");
const testing = std.testing;
const tok = @import("./token.zig");
const log = std.log.scoped(.lexer);
const ascii = std.ascii;
const Token = tok.Token;
const Cursor = tok.Cursor;
const tfmt = @import("./fmt.zig");
const colors = @import("../term/colors.zig");
const Color = colors.Color;
const Kind = Token.Kind;
const Val = Token.Val;
const @"Type" = @import("./token/type.zig").@"Type";
const Timer = std.time.Timer;
const Op = @import("./token/op.zig").Op;
const Block = @import("./token/block.zig").Block;
const Kw = @import("./token/kw.zig").Kw;

// pub fn lex(allocator: std.mem.Allocator, inp: []u8) !std.ArrayList(Token) {

pub const Lexer = struct {
    inp: []const u8,
    tokens: std.ArrayList(Token),
    pos: Cursor,
    offset: usize,
    start: bool,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(inp: []const u8, a: std.mem.Allocator) Lexer {
        const tokens = std.ArrayList(Token).init(a);
        defer tokens.deinit();
        return Lexer{
            .inp = inp,
            .tokens = tokens,
            .pos = Cursor.default(),
            .offset = 0,
            .start = true,
            .allocator = a,
        };
    }
    pub fn lex(self: *Self) !std.ArrayList(Token) {
        while (self.next()) |ch| {
            switch (ch) {
                ' ' => {},
                '*' => _ = try self.push(mulOrOther),
                '\n' => try self.tokens.append(self.newOp(.newline)),
                '.' => _ = try self.push(periodOrOther),
                '%' => try self.tokens.append(self.newOp(.mod)),
                '+' => _ = try self.push(addOrOther),
                '-' => _ = try self.push(subOrOther),
                '^' => try self.tokens.append(self.newOp(.caret)),
                '#' => try self.tokens.append(self.newOp(.pound)),
                '@' => try self.tokens.append(self.newOp(.at)),
                '$' => try self.tokens.append(self.newOp(.dol)),
                '~' => try self.tokens.append(self.newOp(.tilde)),
                '`' => try self.tokens.append(self.newBlock(.btick)),
                '!' => _ = try self.push(exclOrOther),
                '?' => try self.tokens.append(self.newOp(.ques)),
                '<' => _ = try self.push(ltOrOther),
                '>' => _ = try self.push(gtOrOther),
                '=' => _ = try self.push(eqOrOther),
                '(' => try self.tokens.append(self.newBlock(Block{ .lpar = null })),
                ')' => try self.tokens.append(self.newBlock(Block{ .rpar = null })),
                '{' => try self.tokens.append(self.newBlock(Block{ .lbrace = null })),
                '}' => try self.tokens.append(self.newBlock(Block{ .rbrace = null })),
                ';' => try self.tokens.append(self.newOp(.semicolon)),
                ':' => _ = try self.push(colonOrOther),
                ',' => try self.tokens.append(self.newOp(.comma)),
                '&' => try self.tokens.append(try self.consec('&', Kind{ .op = .amp })),
                '|' => _ = try self.push(pipeOrOther),
                '/' => _ = if (try self.divOrComment()) |token| try self.tokens.append(token),
                '_', 'a'...'z', 'A'...'Z' => try self.tokens.append(try self.identOrKw()),
                '"' => try self.tokens.append(try self.strLiteral()),
                '0'...'9' => try self.tokens.append(try self.intLiteral()),
                '\'' => try self.tokens.append(try self.intChar()),
                else => {},
            }
        }
        try self.tokens.append(self.newKind(Token.Kind.eof));
        return self.tokens;
    }

    pub fn push(self: *Self, f: fn (*Self) LexerError!?Token) !?Token {
        if (try f(self)) |token| {
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

    pub fn newToken() Token {
        return Token{ .kind = .unknown, .offset = 0, .pos = Cursor.default() };
    }

    pub fn newKind(self: Self, kind: Kind) Token {
        return Token{ .offset = 0, .pos = self.pos, .kind = kind };
    }

    pub fn newOp(self: Self, op: Op) Token {
        return Token{ .offset = 0, .pos = self.pos, .kind = Kind{ .op = op } };
    }
    pub fn newKw(self: Self, kw: Kw) Token {
        return Token{ .offset = 0, .pos = self.pos, .kind = Kind{ .kw = kw } };
    }
    pub fn newBlock(self: Self, block: Block) Token {
        return Token{ .offset = 0, .pos = self.pos, .kind = Kind{ .block = block } };
    }
    pub fn newType(self: Self, @"type": @"Type") Token {
        return Token{ .offset = 0, .pos = self.pos, .kind = Kind{ .type = @"type" } };
    }

    pub fn current(self: Self) u8 {
        if (self.offset < self.inp.len) {
            return self.inp[self.offset];
        } else return 0;
    }

    pub fn fmtPosition(self: Self) void {
        const args = .{ self.pos.line, self.pos.col, self.offset, self.inp.len };
        log.err("[ln {d}, col {d}, offset {d}, buflen {d}", args);
    }

    pub fn next(self: *Self) ?u8 {
        if (self.start) self.start = false else {
            self.offset += 1;
            if (self.current() == '\n') { // It's a new line
                self.pos.newLine();
            } else self.pos.incrCol();
        }
        if (self.offset >= self.inp.len) return null else return self.current();
    }

    pub fn peek(self: Self) ?u8 {
        if (self.offset + 1 >= self.inp.len) {
            return null;
        } else {
            return self.inp[self.offset + 1];
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
        return self.newOp(Op.div);
    }

    // Called when: found ':', need to know if next char is * or else
    pub fn colonOrOther(self: *Lexer) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk = switch (ch) {
                '.' => {
                    _ = self.next();
                    if (self.peek()) |chn| {
                        return switch (chn) {
                            '.' => self.newBlock(Block{ .rsynth = null }),
                            else => self.newBlock(Block{ .ldata = null }),
                        };
                    }
                    return LexerError.EofInComment;
                },
                ':' => self.newOp(Op.abstractor),
                '-' => {
                    _ = self.next();
                    if (self.peek()) |chn| {
                        return switch (chn) {
                            '-' => self.newBlock(Block{ .rdef = null }),
                            else => self.newBlock(Block{ .rattr = null }),
                        };
                    }
                    return LexerError.EofInComment;
                },
                '=' => self.newOp(Op.defn),
                '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.newOp(Op.faccess),
                ' ' => self.newOp(Op.colon),
                else => null,
            };
            _ = self.next();
            return tk;
        } else return LexerError.EofInComment;
    }

    // Called when: found '=', need to know if next char is * or else
    pub fn eqOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk = switch (ch) {
                '=' => self.newOp(Op.eq_comp),
                '>' => self.newOp(Op.bfarrow),
                '@' => self.newOp(Op.addressed),
                '?' => self.newOp(Op.query),
                '!' => self.newOp(Op.ne), // assign to something else? never?
                ':' => self.newOp(Op.defn), // secondary, colon 1st
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.newOp(Op.assign),
                else => null,
            };
            _ = self.next();
            return tk;
        } else return LexerError.EofInComment;
    }
    pub fn ltOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk = switch (ch) {
                '=' => self.newOp(Op.le),
                '>' => self.newOp(Op.assoc), // <>
                '-' => self.newOp(Op.barrow),
                '<' => self.newOp(Op.double_lt), // assign to something else? never?
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.newOp(Op.lt), // OR type param?
                else => null,
            };
            _ = self.next();
            return tk;
        } else return LexerError.EofInComment;
    }
    pub fn gtOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            _ = self.next();
            const tk = switch (ch) {
                '=' => self.newOp(Op.ge),
                '>' => self.newOp(Op.double_gt), // <>
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.newOp(Op.gt), // OR type param?
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
    }
    // Called when: found '+', need to know if next char is * or else
    pub fn mulOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk = switch (ch) {
                '*' => self.newOp(Op.exp),
                '=' => self.newOp(Op.mul_eq),
                ' ' => self.newOp(Op.mul),
                '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.newOp(Op.pointer),
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
    }
    // Called when: found '+', need to know if next char is * or else
    pub fn addOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk = switch (ch) {
                '+' => self.newOp(Op.bind),
                '=' => self.newOp(Op.add_eq),
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.newOp(Op.add),
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
    }
    pub fn subOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk = switch (ch) {
                '>' => self.newOp(Op.farrow),
                '-' => {
                    _ = self.next();
                    if (self.peek()) |chn| {
                        const ntk = switch (chn) {
                            '|' => self.newBlock(Block.lcomment),
                            '?' => self.newBlock(Block.lque),
                            '!' => self.newBlock(Block.ldoc),
                            ':' => self.newBlock(Block{ .ldef = null }),
                            else => self.newOp(Op.comment),
                        };
                        return ntk;
                    }
                    return LexerError.EofInComment;
                },
                '=' => self.newOp(Op.sub_eq),
                '|' => self.newBlock(Block{ .lstate = null }),
                '!' => self.newBlock(Block.ldocln),
                '?' => self.newBlock(Block.llnquery),
                ':' => self.newBlock(Block{ .lattr = null }),
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.newOp(Op.sub),
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
    }

    // Called when: found '!', need to know if next char is * or else
    pub fn exclOrOther(self: *Self) LexerError!?Token {
        if (self.peek()) |ch| {
            const tk: ?Token = switch (ch) {
                '=' => self.newOp(Op.ne),
                '.' => {
                    _ = self.next();
                    if (self.peek()) |chn| {
                        return switch (chn) {
                            '.' => self.newBlock(.rawait),
                            else => null,
                        };
                    }
                    return LexerError.EofInStr;
                },
                '-' => {
                    _ = self.next();
                    if (self.peek()) |chn| {
                        return switch (chn) {
                            '-' => self.newBlock(.rdoc),
                            else => self.newBlock(.rdocln),
                        };
                    }
                    return LexerError.EofInStr;
                },
                '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.newOp(Op.not),
                ' ' => self.newOp(.excl),
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
                                const tr: ?Token = self.newOp(Op.range);
                                return tr;
                            },
                            '!' => self.newBlock(Block.lawait),
                            '?' => self.newBlock(Block.lawaitque),
                            ':' => self.newOp(Op.range_xr),
                            else => self.newOp(Op.range_xx),
                        };
                    } else return LexerError.EofInComment;
                },
                '!' => self.newOp(Op.access), // deref?
                '?' => self.newOp(Op.access), // optional?
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.newOp(Op.access),
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
                        '-' => self.newBlock(.rcomment),
                        else => self.newBlock(Block{ .rstate = null }),
                    } else return LexerError.EofInStr;
                },
                '|' => self.newOp(Op.@"or"),
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.newOp(.pipe),
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
    }

    pub fn identOrKw(self: *Self) !Token {
        var outp = Self.newToken();
        const p_i = self.offset;
        while (self.peek()) |ch| : (_ = self.next()) {
            switch (ch) {
                '_', 'a'...'z', 'A'...'Z', '0'...'9' => {},
                else => break,
            }
        }
        const p_f = self.offset + 1;
        var st = self.inp[p_i..p_f];
        if (Kind.isKw(st)) |kwd| {
            outp.kind = Kind{ .kw = kwd };
        } else {
            outp.kind = Kind{ .type = @"Type"{ .ident = st } };
            outp.val = Val{ .str = st };
        }
        return outp;
    }

    pub fn strLiteral(self: *Self) !Token {
        var outp = self.newType(@"Type"{ .str = "" });
        const p_i = self.offset;
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
        const p_f = self.offset + 1;
        outp.val = Val{ .str = self.inp[p_i..p_f] };
        return outp;
    }

    pub fn followed(self: *Self, by: u8, pos_type: Kind, neg_type: Kind) Token {
        var outp = Self.newToken();
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
        const outp = self.newKind(kind);
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
        var outp = self.newKind(Kind{ .type = @"Type"{ .int = 0 } });
        const p_i = self.offset;
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
        const p_f = self.offset + 1;
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
        var outp = self.newType(@"Type"{ .int = 0 });
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

pub const LexerError = error{ Init, EmptyCharConst, UnknownEscSeq, MulticharConst, EofInComment, EofInStr, EolInStr, UnknownChar, InvalidNum, OutOfSpace } || std.fmt.ParseIntError;

test "parses_idents_ok" {
    testing.expectEqual(5, 5);
}
