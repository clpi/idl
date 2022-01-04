const std = @import("std");
const testing = std.testing;
const tok = @import("./token.zig");
const ascii = std.ascii;
const Token = tok.Token;
const colors = @import("../term/colors.zig");
const Color = colors.Color;
const Kind = Token.Kind;
const Val = Token.Val;
const Op = Kind.Op;
const Kw = Kind.Kw;
const Block = Kind.Block;
const lg = std.log.scoped(.lexer);

// pub fn lex(allocator: std.mem.Allocator, inp: []u8) !std.ArrayList(Token) {
pub fn lex(allocator: std.mem.Allocator, inp: []const u8) !std.ArrayList(Token) {
    var tks = std.ArrayList(Token).init(allocator);
    var lexer = Lexer.init(inp);
    while (lexer.next()) |ch| {
        switch (ch) {
            ' ' => {},
            '*' => try tks.append(lexer.buildOp(.mul)),
            '\n' => try tks.append(lexer.buildOp(.newline)),
            '.' => _ = try addToken(try lexer.periodOrOther(), &tks),
            '%' => try tks.append(lexer.buildOp(.mod)),
            '+' => try tks.append(lexer.buildOp(.add)),
            '-' => _ = try addToken(try lexer.subOrOther(), &tks),
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
            ':' => _ = try addToken(try lexer.colonOrOther(), &tks),
            ',' => try tks.append(lexer.buildOp(.comma)),
            '&' => try tks.append(try lexer.consec('&', Kind{ .op = .amp })),
            '|' => _ = try addToken(try lexer.pipeOrOther(), &tks),
            '/' => _ = if (try lexer.divOrComment()) |token| try tks.append(token),
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
pub fn addToken(tokn: ?Token, tokenl: *std.ArrayList(Token)) !?Token {
    if (tokn) |token| {
        tokenl.append(token) catch {
            return LexerError.OutOfSpace;
        };
        return token;
    } else return null;
}

pub fn tokenListToString(allocator: std.mem.Allocator, token_list: std.ArrayList(Token)) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    var w = result.writer();
    for (token_list.items) |token| {
        const common_args = .{ token.line, token.col, token.kind.toStr() };
        try token.write(allocator);
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
            if (@TypeOf(token.kind) == Kind.Op) {
                std.debug.print(" [{s}END STATEMENT{s}] ", colors.Fg.green, colors.Fg.reset);
            }
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

    // Called when: found '-', need to know if next char is * or else
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
                            ':' => self.buildBlock(Block.ldef),
                            else => self.buildOp(Op.comment),
                        };
                    }
                    return LexerError.EofInComment;
                },
                '=' => self.buildOp(Op.sub_eq),
                '|' => self.buildBlock(Block.lstate),
                '!' => self.buildBlock(Block.ldocln),
                '?' => self.buildBlock(Block.llnquery),
                ':' => self.buildOp(Op.abstractor),
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.buildOp(Op.sub),
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
                            ':' => self.buildBlock(Block.ldef),
                            else => self.buildOp(Op.comment),
                        };
                    }
                    return LexerError.EofInComment;
                },
                '=' => self.buildOp(Op.sub_eq),
                '|' => self.buildBlock(Block.lstate),
                '!' => self.buildBlock(Block.ldocln),
                '?' => self.buildBlock(Block.llnquery),
                ':' => self.buildBlock(Block.lattr),
                ' ', '_', 'a'...'z', 'A'...'Z', '0'...'9' => self.buildOp(Op.sub),
                else => null,
            };
            return tk;
        } else return LexerError.EofInComment;
    }

    // Called when: found '-', need to know if next char is * or else
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
                        else => self.buildBlock(.rstate),
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

pub const LexerError = error{ EmptyCharConst, UnknownEscSeq, MulticharConst, EofInComment, EofInStr, EolInStr, UnknownChar, InvalidNum, OutOfSpace };

test "parses_idents_ok" {
    testing.expectEqual(5, 5);
}
