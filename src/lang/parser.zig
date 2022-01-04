const std = @import("std");
const ast = @import("./ast.zig");
const tok = @import("./token.zig");
const lex = @import("./lexer.zig");
const logs = std.log.scoped(.parser);
const Ast = ast.Ast;
const Token = tok.Token;
const Kind = Token.Kind;
const Op = Token.Kind.Op;
const Typ = Token.Kind.@"Type";
const Block = Token.Kind.Block;
const Kw = Token.Kind.Kw;
const Lexer = lex.Lexer;

pub const Parser = struct {
    tokens: std.ArrayList(Token),
    allocator: std.mem.Allocator,
    state: Parser.State,

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator, input: []const u8) !Self {
        const tokens = try Lexer.init(input, alloc).lex();
        return Self{ .allocator = alloc, .tokens = tokens, .state = State.init(alloc) };
    }

    pub fn next(self: *Self) ?Token {
        return self.tokens.popOrNull();
    }

    pub fn parse(self: *Self) !Ast {
        var output = Ast.init(self.allocator);
        var token_iter = Token.Iter.init(self.allocator, self.tokens);
        while (token_iter.next()) |tk| {
            std.log.scoped(.parser).debug("{s}", .{try tk.toStr("")});
            switch (tk.kind) {
                .block => |bloc| switch (bloc) {
                    .lpar => {},
                    .rpar => {},
                    .lbracket => {},
                    .rbracket => {},
                    .lbrace => {},
                    .rbrace => {},
                    .squote => {},
                    .dquote => {},
                    else => {},
                },
                .unknown => return PerserError.UnknownToken,
                .eof => break,
                .op => |oper| switch (oper) {
                    .at => {},
                    else => {},
                },
                .kw => |kword| switch (kword) {
                    .let => {},
                    .do => {},
                    else => {},
                },
                .type => |typ| switch (typ) {
                    .ident => |_| {},
                    .byte => |_| {},
                    .str => |_| {},
                    .int => |_| {},
                    .float => |_| {},
                    .bool => |_| {},
                    .seq => {},
                },
            }
            logs.info("[X: {d}, Y: {d}] {s}    {s}", .{ tk.line, tk.col, tk.kind.toStr(), tk.val });
        }
        return output;
    }

    pub fn blockToTree(self: *Self, block_start: Token, block_end: Token, between: []Token) !*Ast.Node {
        const block_root = try self.allocator.create(Ast.Node);
        defer self.allocator.destroy(block_root);
        block_root.* = Ast.Node{ .lhs = null, .rhs = null, .data = block_start };
        for (between) |btw| {
            std.debug.print("{s}{s}{s}", .{ block_start.toStr(), btw.toStr(), block_end.toStr() });
        }
        return block_root;
    }

    pub fn toAst(self: *Self, tk: Token, lhs: ?*Ast.Node, rhs: ?*Ast.Node) !*Ast {
        const res = try self.allocator.create(Ast);
        defer self.allocator.destroy(res);
        res.root = Ast.Node{ .lhs = lhs, .rhs = rhs, .data = tk };
        return res;
    }

    pub fn toExprNode(self: *Self, tk: Token, lhs: ?*Ast.Node, rhs: ?*Ast.Node) !*Ast.Node {
        const res = try self.allocator.create(Ast.Node);
        defer self.allocator.destroy(res);
        res.* = Ast.Node{ .lhs = lhs, .rhs = rhs, .data = tk };
        return res;
    }

    pub fn toNode(self: *Self, tk: Token) !*Ast.Node {
        const res = try self.allocator.create(Ast.Node);
        defer self.allocator.destroy(res);
        res.* = Ast.Node{ .lhs = null, .rhs = null, .data = tk };
        return res;
    }

    pub const State = struct {
        curr_t: ?Token,
        curr_idx: i32,
        curr_block: ?[]const u8,
        symbols: std.AutoHashMap(usize, []const u8),
        blocks: std.StringHashMap(Token.Kind.Block),
        list: ?[]const u8,

        pub fn init(all: std.mem.Allocator) Parser.State {
            return Parser.State{
                .curr_idx = 0,
                .curr_t = null,
                .curr_block = null,
                .symbols = std.AutoHashMap(usize, []const u8).init(all),
                .blocks = std.StringHashMap(Token.Kind.Block).init(all),
                .list = null,
            };
        }

        pub fn beginBlock(self: Parser.State, blc: Token.Kind.Block) void {
            switch (blc) {
                .lbrace => |braceid| if (braceid) |br_ident| {
                    self.blocks.put(br_ident, blc);
                    self.curr_block = br_ident;
                } else {
                    const bid = @tagName(blc) ++ [_]u8{self.blocks.count()};
                    self.blocks.put(bid, blc);
                    self.curr_block = bid;
                },
                .rbrace => |braceid| if (braceid) |bident| {
                    self.curr_block = bident;
                    self.blocks.put(bident, blc);
                } else {
                    const bid = @tagName(blc) ++ [_]u8{self.blocks.count()};
                    self.blocks.put(bid, blc);
                    self.curr_block = bid;
                },
                else => {},
            }
        }
    };
};

pub const PerserError = error{
    Eof,
    NotFound,
    UnknownToken,
};
