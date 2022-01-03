const std = @import("std");
const token = @import("./lang/token.zig");
const parser = @import("./lang/parser.zig");
const cli = @import("./cli.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var gpa = arena.allocator();
    try cli.procArgs(gpa);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
