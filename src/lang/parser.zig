const std = @import("std");
const ast = @import("./ast.zig");
const tok = @import("./token.zig");
const lex = @import("./lexer.zig");
const expr = @import("./expr.zig");
const tfmt = @import("./fmt.zig");
const ExprBlock = expr.ExprBlock;
const Cursor = expr.Cursor;
pub const Op = @import("./token/op.zig").Op;
pub const Block = @import("./token/block.zig").Block;
pub const Tty = @import("./token/type.zig").Tty;
pub const Kw = @import("./token/kw.zig").Kw;
const logs = std.log.scoped(.parser);
const Ast = ast.Ast;
const Token = tok.Token;
const Lexer = lex.Lexer;

pub const Parser = struct {
    pos: Cursor,
    arena: std.heap.ArenaAllocator,
    tokens: std.ArrayList(Token),
    allocator: std.mem.Allocator,
    state: Parser.State,

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator, input: []const u8) !Self {
        var arena = std.heap.ArenaAllocator.init(alloc);
        errdefer arena.deinit();
        const tokens = try Lexer.init(input, alloc).lex();
        return Self{
            .pos = Cursor{ .line = 1, .col = 1 },
            .allocator = arena.allocator(),
            .tokens = tokens,
            .state = State.init(alloc),
            .arena = arena,
        };
    }

    pub fn deinit(self: *Self) void {
        self.arena.deinit();
        self.allocator.free(u8);
    }

    pub fn next(self: *Self) ?Token {
        return self.tokens.popOrNull();
    }

    pub fn parse(self: *Self) !Ast {
        var output = Ast.init(self.allocator, self.arena);
        var blocks = std.ArrayList(*ExprBlock).init(self.allocator);
        // var curr_block: ?Block = null;
        // var curr_expr_block: ?ExprBlock = null;
        defer blocks.deinit();
        for (self.tokens.items) |tk| {
            std.log.scoped(.parser).debug("{s}", .{try tfmt.toStr(tk, self.allocator, "")});
            switch (tk.kind) {
                .block => |bloc| {
                    // if (@tagName(bloc)[0] == 'l') {
                    //     logs.warn("GOT BLOCK START {s}", .{@tagName(bloc)});
                    //     curr_block = bloc;
                    //     _ = try self.allocator.create(ExprBlock);
                    //     curr_expr_block.? = &ExprBlock.init(self.pos.line, self.pos.col, bloc, self.allocator);
                    //     self.state.curr_block = @enumToInt(bloc);
                    // } else if (@tagName(bloc)[0] == 'r') {
                    //     const bc = curr_block.?.closing();
                    //     if (@enumToInt(bc) == @enumToInt(bloc)) {
                    //         logs.warn("GOT BLOCK END {s}", .{@tagName(bloc)});
                    //         try blocks.append(curr_expr_block.?);
                    //         self.state.curr_block = null;
                    //         curr_expr_block = null;
                    //         curr_block = null;
                    //     }
                    // } else {
                    switch (bloc) {
                        .lpar => {},
                        .rpar => {},
                        .lbracket => {},
                        .rbracket => {},
                        .lbrace => {},
                        .rbrace => {},
                        .squote => {},
                        .dquote => {},
                        else => {},
                    }
                    // }
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
                    .none => {},
                    .ident => |_| {},
                    .byte => |_| {},
                    .str => |_| {},
                    .int => |_| {},
                    .float => |_| {},
                    .bool => |_| {},
                    .seq => {},
                },
            }
            logs.info("{s}", .{tfmt.toStr(tk, self.allocator, "")});
            // if (curr_expr_block) |ceb| {
            //     try ceb.tokens.append(tk);
            // }
        }
        logs.warn("BLOCKS INFO: \n", .{});
        for (blocks.items) |bloc| {
            logs.warn("INFO: BLOCK {s} ({s}):", .{ bloc.pos, bloc.sblock.toStr() });
            for (bloc.tokens.items) |tkn| {
                logs.warn("TOKEN: {s} ", .{try tfmt.toStr(tkn, self.allocator, "")});
            }
        }
        logs.warn("BLOCKS LEN: {d}", .{std.mem.len(blocks.items)});
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
        curr_idx: Cursor,
        curr_block: ?i32,
        symbols: std.ArrayList(u32),
        blocks: std.ArrayList(Block),
        list: ?[]const u8,

        pub fn init(all: std.mem.Allocator) Parser.State {
            return Parser.State{
                .curr_idx = Cursor{ .line = 1, .col = 1 },
                .curr_t = null,
                .curr_block = null,
                .symbols = std.ArrayList(u32).init(all),
                .blocks = std.ArrayList(Block).init(all),
                .list = null,
            };
        }

        pub fn beginBlock(self: Parser.State, blc: Block) void {
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
