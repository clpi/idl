const std = @import("std");
const token = @import("./token.zig");
const Token = token.Token;
const pipe = std.os.pipe;

pub const Compiler = struct {
    const Self = @This();

    symbols: std.StringArrayHashMap(u32),
    tokens: []const Token,
    errors: [*]Error,
    scopes: []const Scope,
    arena: std.heap.ArenaAllocator,
    alloc: std.mem.Allocator,

    pub fn init(a: std.mem.Allocator) Self {
        var arena = std.heap.ArenaAllocator.init(a);
        const sym = std.StringArrayHashMap(u32).init(a);
        Compiler{ .symbols = sym, .arena = arena, .scopes = .{}, .tokens = .{}, .alloc = a };
    }

    pub const Error = union(enum(u32)) {
        unknown_input,
    };
};

pub const Mod = struct {
    name: []const u8,
    scopes: []const Scope,
    allocator: std.mem.Allocator,
    sym: std.StringArrayHashMap(u32),
    const Self = @This();

    pub fn init(a: std.mem.Allocator, name: []const u8, scopes: []const Scope) Self {
        const sym = std.StringArrayHashMap(u32).init(a);
        return Self{ .allocator = a, .sym = sym, .name = name, .scopes = scopes };
    }
};

pub const Scope = struct {
    name: []const u8,
    kind: Scope.Kind,
    offset: u32,
    allocator: std.mem.Allocator,
    parent: ?*Scope,
    sym: std.StringArrayHashMap(u32),
    const Self = @This();

    pub const Kind = union(enum) {
        global,
        loop,
        mod: ?[]const u8,
    }; // add block?

    pub const Default = union(enum(u16)) {
        main,
    };
};
