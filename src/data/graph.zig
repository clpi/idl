const std = @import("std");
const log = std.log.scoped(.graph);

pub fn Graph(comptime N: type, comptime E: type) type {
    return struct {
        pub const Self = @This();

        alloc: std.mem.Allocator,
        capacity: usize,
        nodes: []N,
        edges: []E,

        pub fn init(a: std.mem.Allocator) Self {
            return Self{ .alloc = a, .nodes = .{}, .edges = .{} };
        }

        pub fn addNode(node: N) !usize {
            log.info("addNode {}", .{node});
            return 0;
        }

        pub fn addEdge(edge: E) !usize {
            log.info("addEdge {}", .{edge});
            return 0;
        }
    };
}

pub fn GraphCtx(comptime N: type, comptime E: type) type {
    return struct {
        alloc: std.mem.Allocator,
        node_root: N,
        edge_root: E,

        pub const GraphEnv = struct {
            const Self = @This();
        };
    };
}
