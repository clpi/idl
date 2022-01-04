const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const StrMap = std.StringHashMap;
const tk = @import("./token.zig");
const hash = std.hash;
const Token = tk.Token;
const Kind = Token.Kind;
const Op = Token.Kind.Op;

pub const AstError = error{
    MemoryLimit,
};

pub const Ast = struct {
    root: ?*Ast.Node,
    allocator: std.mem.Allocator,
    sym_map: std.StringHashMap([]const u8),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        const hm = StringHashMap([]const u8).init(allocator);
        return Self{ .allocator = allocator, .root = null, .sym_map = hm };
    }

    pub fn newLeaf(self: *Self, data: Token) Ast.Node {
        const new = self.allocator.create(Ast.Node);
        new.* = Ast.Node{ .idx = 0, .data = data, .lhs = null, .rhs = null };
        return new;
    }

    pub fn newNode(self: *Self, data: Token, lhs: ?*Ast.Node, rhs: ?*Ast.Node) Ast.Node {
        const new = self.allocator.create(Ast.Node);
        new.* = Ast.Node{ .idx = 0, .data = data, .lhs = lhs, .rhs = rhs };
        return new;
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
        lhs: ?*Ast.Node,
        rhs: ?*Ast.Node,

        const AstNode = @This();

        pub fn init(data: Token) Ast.Node {
            return Ast.Node{
                .idx = 0,
                .data = data,
                .lhs = null,
                .rhs = null,
            };
        }

        pub fn initExpr(idx: usize, data: Token, lhs: ?*Node, rhs: ?*Node) Node {
            return Ast.Node{ .idx = idx, .data = data, .lhs = lhs, .rhs = rhs };
        }

        pub fn addNode() void {}

        pub fn setLhs(self: Node, data: Token) void {
            self.lhs = Node.init(data);
        }

        pub fn setRhs(self: Node, data: Token) void {
            self.lhs = Node.init(data);
        }

        pub fn eval(self: Node) void {
            if (self.lhs) |lhs| if (self.rhs) |rhs| {
                const args = .{ lhs.toStr(), self.toStr(), rhs.toStr() };
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

        pub fn toStr(self: *Ast.Node) []const u8 {
            const args = .{ self.idx, self.data.toStr(), self.lhs.toStr(), self.rhs.toStr() };
            std.debug.print("AST NODE: {s} with data:\n{s}\nlhs: {s}\trhs: {s}", args);
            return "";
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

    pub fn toStr(self: *Ast.Node) []const u8 {
        std.debug.print("AST: ROOT {s}", .{self.root.?.toStr()});
        return "";
    }
};
