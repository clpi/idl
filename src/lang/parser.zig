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

pub const Parser = struct {
    tokens: std.ArrayList(Token),
    allocator: std.mem.Allocator,
    state: Parser.State,

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator, tokens: std.ArrayList(Token)) Self {
        return Self{ .allocator = alloc, .tokens = tokens, .state = State.init() };
    }

    pub fn parse(self: *Self) !void {
        while (self.tokens.popOrNull()) |tk| {
            switch (tk.kind) {
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
                .block => |bloc| switch (bloc) {
                    .lpar => {},
                    .lbrace => {},
                    .lbracket => {},
                    .squote => {},
                    .dquote => {},
                    .rpar => {},
                    .rbrace => {},
                    .rbracket => {},
                    else => {},
                },
                .type => |typ| switch (typ) {
                    .ident => |_| {},
                    .byte => |_| {},
                    .str => |_| {},
                    .int => |_| {},
                    .float => |_| {},
                    .bool => |_| {},
                    .list => {},
                },
            }
            logs.info("[X: {d}, Y: {d}] {s}    {s}", .{ tk.line, tk.col, tk.kind.toStr(), tk.val });
        }
    }

    pub fn toAst(self: *Self, tk: Token, lhs: ?*Ast.Node, rhs: ?*Ast.Node) !*Ast {
        const res = try self.allocator.create(Ast);
        res.root = Ast.Node{ .lhs = lhs, .rhs = rhs, .data = tk };
        return res;
    }

    pub fn toExprNode(self: *Self, tk: Token, lhs: ?*Ast.Node, rhs: ?*Ast.Node) !*Ast.Node {
        const res = try self.allocator.create(Ast.Node);
        res.* = Ast.Node{ .lhs = lhs, .rhs = rhs, .data = tk };
        return res;
    }

    pub fn toNode(self: *Self, tk: Token) !*Ast.Node {
        const res = try self.allocator.create(Ast.Node);
        res.* = Ast.Node{ .lhs = null, .rhs = null, .data = tk };
        return res;
    }

    pub const State = struct {
        curr: Token,
        block: ?[]const u8,
        list: ?[]const u8,

        pub fn init() Parser.State {
            return Parser.State{
                .curr = Token{ .col = 1, .line = 1 },
                .block = null,
                .list = null,
            };
        }
    };

    pub const States = union(enum) {
        in_block: []const u8,
        in_parens: []const u8,
        in_braces: []const u8,
        in_squote: []const u8,
        in_dquote: []const u8,
        in_btick: []const u8,
        in_doc_cmt,
        in_cmt,
    };
};

pub const PerserError = error{
    Eof,
    NotFound,
    UnknownToken,
};
