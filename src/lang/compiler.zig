const std = @import("std");
const token = @import("./token.zig");
const Token = token.Token;

pub const Compiler = struct {
    symbols: std.StringHashMap(u32),
    tokens: []const Token,
    errors: [*]Error,
    scopes: []const Scope,

    pub const Error = union(enum(u32)) {
        unknown_char,
    };

    pub const Scope = union(enum(u16)) {
        main,
    };
};
