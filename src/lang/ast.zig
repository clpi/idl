const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const StrMap = std.StringHashMap;
const tk = @import("./token.zig");
const hash = std.hash;
const Token = tk.Token;
const Kind = Token.Kind;
const lex = @import("./lexer.zig");
const Lexer = lex.Lexer;
const LexerError = lex.LexerError;
const @"Type" = @import("./token/type.zig").@"Type";
const Op = @import("./token/op.zig").Op;
const Block = @import("./token/block.zig").Block;
const Kw = @import("./token/kw.zig").Kw;

pub const AstError = error{
    MemoryLimit,
};

pub const Ast = struct {
    root: ?*Ast.Node = null,
    arena: std.heap.ArenaAllocator,
    allocator: std.mem.Allocator,
    sym_map: std.StringHashMap([]const u8),

    const Self = @This();

    pub fn init(a: std.mem.Allocator, arena: std.heap.ArenaAllocator) Self {
        var hm = StringHashMap([]const u8).init(a);
        defer hm.deinit();
        return Self{ .arena = arena, .allocator = a, .root = null, .sym_map = hm };
    }

    pub fn deinit(self: *Self) void {
        self.sym_map.deinit();
        _ = self.arena.state.promote(self.allocator);
        self.arena.deinit();
        self.* = undefined;
    }

    pub fn push(self: *Self, data: Token) void {
        var node = self.newLeaf(data);
        if (self.root) |root| {
            node.next = root;
            self.root = node;
        } else self.root = node;
    }

    pub fn create(a: std.mem.Allocator, input: []const u8) !void {
        var lx = Lexer.init(input, a);
        const tok_str = try lx.tokenListToString();
        std.debug.print("{s}", .{tok_str});
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        var ast = Self.init(a, arena);
        defer ast.deinit();
        // var stack = Stack.init(a, @intCast(i32, input.len));
    }

    /// Tokenize input without use of Lexer struct
    pub fn tokenize(a: std.mem.Allocator, input: []const u8) *Self {
        var ln_instr = std.mem.tokenize(u8, input, '\n');
        while (ln_instr.next()) |instr| {
            var ws_strip = std.mem.tokenize(u8, instr, " ");
            for (ws_strip) |w| {
                std.debug.print("Got {s}\n", w);
            }
        }
        return Self.init(a, std.heap.ArenaAllocator.init(a));
    }

    pub fn pop(self: *Self) ?*Node {
        const node = self.root;
        self.root = self.root.?.next;
        return node;
    }

    pub fn newLeaf(self: *Self, data: Token) !Ast.Node {
        const new = self.allocator.create(Ast.Node);
        var node: Ast.Node = Node.init(data);
        node = Ast.Node{ .idx = 0, .data = data, .lhs = null, .rhs = null };
        try return new;
    }

    pub fn newNode(self: *Self, data: Token, lhs: ?*Ast.Node, rhs: ?*Ast.Node) !Ast.Node {
        const new = self.allocator.create(Ast.Node);
        new.* = Ast.Node{ .idx = 0, .data = data, .lhs = lhs, .rhs = rhs };
        try return new;
    }

    pub fn build(self: *Self, tkl: ArrayList(Token)) AstError!?Self {
        // var curr_st = ":";
        if (!self.root) self.withRoot(tkl.next());
        for (tkl) |token| {
            switch (token.kind) {
                .type => |ty| switch (ty) {
                    .ident => |_| continue, //store in sym table
                    else => continue,
                },
                .op => |o| switch (o) {
                    .newline, .semicolon => continue,
                },
                .kw => |kwd| switch (kwd) {
                    .is => continue,
                    else => continue,
                },
                .block => |bl| switch (bl) {
                    .lpar => continue,
                    else => continue,
                },
            }
        }
        return self;
    }

    pub fn withRoot(self: Self, data: Token) void {
        self.root = Node.init(data);
    }

    pub fn len(self: Self) usize {
        return self.len;
    }

    pub const Node = struct {
        idx: usize,
        data: Token,
        lhs: ?*Ast.Node = null,
        rhs: ?*Ast.Node = null,

        const AstNode = @This();

        pub fn init(data: Token) Ast.Node {
            return Ast.Node{
                .idx = 0,
                .data = data,
                .lhs = null,
                .rhs = null,
            };
        }

        pub fn inOrder(self: ?Ast.Node, a: std.mem.Allocator) void {
            if (self) |root| {
                root.inOrder(a);
                std.debug.print("{s}", .{&root.toStr(a)});
                root.inOrder(a);
            }
        }

        pub fn undef() Ast.Node {
            return Ast.Node{ .idx = 0, .lhs = null, .rhs = null, .data = Token.initKind(.unknown, null) };
        }

        pub fn initExpr(idx: usize, data: Token, lhs: ?*Ast.Node, rhs: ?*Ast.Node) Node {
            return Ast.Node{ .idx = idx, .data = data, .lhs = lhs, .rhs = rhs };
        }

        pub fn addNode() void {}

        pub fn setLhs(self: Ast.Node, data: Token) void {
            self.lhs = Ast.Node.init(data);
        }

        pub fn setRhs(self: Ast.Node, data: Token) void {
            self.lhs = Ast.Node.init(data);
        }

        pub fn eval(self: Ast.Node, a: std.mem.Allocator) void {
            if (self.lhs) |lhs| if (self.rhs) |rhs| {
                const args = .{ lhs.toStr(a), self.toStr(a), rhs.toStr(a) };
                std.debug.print("Ast.Node.Eval {s} {s} {s}", args);
                switch (self.data.kind) {
                    Kind.op => |op| switch (op) {
                        .mul => Eval.mul(0, 0),
                        else => {},
                    },
                    Kind.@"Type" => |_| {},
                    else => {},
                }
            };
        }

        pub fn toStr(self: *Ast.Node, a: std.mem.Allocator) []const u8 {
            const args = .{
                self.idx,
                self.data.kind.toStr(),
                if (self.lhs) |l| Ast.Node.toStr(l, a) else "",
                if (self.rhs) |r| Ast.Node.toStr(r, a) else "",
            };
            const pfmt = "AST NODE: {s} with data:\n{s}\nlhs: {s}\trhs: {s}";
            std.debug.print("AST NODE: {s} with data:\n{s}\nlhs: {s}\trhs: {s}", args);
            return std.fmt.allocPrint(a, comptime pfmt, comptime args) catch {
                return " ";
            };
        }
    };

    pub const Eval = struct {
        op: ?Token.Kind.Op,
        lhs: []const u8,
        lhs: []const u8,

        pub fn add(a: i32, b: i32) i32 {
            return a + b;
        }
        pub fn sub(a: i32, b: i32) i32 {
            return a - b;
        }
        pub fn mul(a: i32, b: i32) i32 {
            return a * b;
        }
        pub fn div(a: i32, b: i32) f32 {
            return a / b;
        }
    };

    pub const Symbols = struct {
        const Sym = @This();

        sym: StringHashMap(Symbol),

        pub fn init(a: std.mem.Allocator) Symbols {
            return Self{ .sym = StringHashMap(Symbol).init(a) };
        }

        pub fn print(self: Symbols) void {
            std.debug.print("IDLANG SYMBOL TABLE: ", .{});
            for (self.sym) |sy| {
                sy.print();
            }
        }
    };

    pub const Symbol = struct {
        key: []const u8,
        val: []const u8,
        scope: Scope,
        context: []const u8,
        line: usize,
        next: ?Symbol,

        pub fn print(self: Symbol) void {
            const args = .{ self.key, self.val, self.scope, self.line, self.context };
            std.debug.print("SYM: {s} = {s} :: SCOPE {s}, LINE {s} :: CTX {s}", args);
        }

        pub fn init(ident: []const u8, val: []const u8, scope: []const u8, ln: usize) Symbol {
            return Self{ .key = ident, .val = val, .scope = scope, .line = ln, .next = null };
        }

        pub const Scope = union(enum(u8)) {
            local,
            public,
            block: ?[]const u8,

            pub fn fromStr(st: []const u8) ?Scope {
                if (std.mem.eql(u8, "loc", st) or std.mem.eql(u8, "local", st)) {
                    return Scope.local;
                } else if (std.mem.eql(u8, "pub", st) or std.mem.eql(u8, "public", st)) {
                    return Scope.public;
                } else if (st[0] == ':') {
                    return Scope{ .block = st[1..] };
                }
                return null;
            }
        };
    };

    pub fn toStr(self: *Ast, a: std.mem.Allocator) []const u8 {
        std.debug.print("AST: ROOT {s}", .{self.root.?.toStr(a)});
        return "";
    }
};

pub const Stack = struct {
    const Self = @This();
    capacity: i32,
    top: i32 = -1,
    alloc: std.mem.Allocator,
    nodes: std.ArrayList(Token),

    pub fn init(a: std.mem.Allocator, cap: i32) Stack {
        const nodes = std.ArrayList(Token).init(a);
        return Stack{ .top = -1, .capacity = cap, .nodes = nodes, .alloc = a };
    }

    pub fn isFull(self: *Self) bool {
        return self.top == self.capacity - 1;
    }

    pub fn isEmpty(self: *Self) bool {
        return self.top == -1;
    }

    pub fn push(self: *Self, data: Token) StackError!void {
        if (self.isFull()) return StackError.MaxCapacity;
        self.nodes.items[@intCast(usize, self.top) + 1] = data;
    }

    pub fn pop(self: *Self) StackError!Token {
        if (@intCast(usize, self.top) == -1) return StackError.Empty;
        return self.nodes.items[@intCast(usize, self.top) - 1];
    }

    pub fn peek(self: *Self) Token {
        return self.nodes.items[@intCast(usize, self.top)];
    }

    pub fn fromArrayList(self: *Self, sl: ArrayList(Ast.Node)) !?Ast {
        self.nodes = sl;
        self.capacity = std.mem.len(sl.items);
        self.top = self.capacity - 1;
    }
};
pub const StackError = error{ MaxCapacity, Empty };
