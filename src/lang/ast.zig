const std = @import("std");
const AutoHashMap = std.AutoHashMap;
const StrMap = std.StringHashMap;
const tk = @import("./token.zig");
const Token = tk.Token;

pub const AstError = error{
    MemoryLimit,
};

pub const Ast = struct {
    root: ?*Ast.Node,
    map: AutoHashMap(usize, Node),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, data: Token, lhs: ?*Node, rhs: ?*Node) Self {
        const hm = AutoHashMap(usize, Node).init(allocator);
        const root = Ast.Node{ .idx = 0, .data = data, .lhs = lhs, .rhs = rhs };
        return Self{ .adj_matrix = hm, .root = root, .map = hm };
    }

    pub fn withRoot(self: Self, data: Token) void {
        self.root = Node.init(data);
    }

    pub fn len(self: Self) usize {
        return self.len;
    }

    pub const Node = struct {
        data: Token,
        lhs: ?*Ast.Node,
        rhs: ?*Ast.Node,

        const AstNode = @This();

        pub fn init(data: Token) Ast.Node {
            return Ast.Node{
                .data = data,
                .lhs = null,
                .rhs = null,
            };
        }

        pub fn setLhs(self: Node, data: Token) void {
            self.lhs = Node.init(data);
        }

        pub fn setRhs(self: Node, data: Token) void {
            self.lhs = Node.init(data);
        }
    };
};
