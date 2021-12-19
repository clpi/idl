const std = @import("std");
const token = @import("token.zig");
const parser = @import("./parser.zig");
const cli = @import("./cli.zig");
const wasm = std.wasm;

pub fn main() !void {
    // var gp_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(!gp_allocator.deinit());
    // const gpa = gp_allocator.allocator();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var gpa = arena.allocator();
    try cli.procArgs(gpa);

    // We accept both files and standard input.
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}