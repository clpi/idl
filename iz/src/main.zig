const std = @import("std");
const proc = std.process;

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

const Ops = enum { New, Run, Build, Shell };

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
