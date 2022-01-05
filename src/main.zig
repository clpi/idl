const std = @import("std");
const token = @import("./lang/token.zig");
const builtin = @import("builtin");
const parser = @import("./lang/parser.zig");
const cli = @import("./cli.zig");
pub const logs = @import("./log.zig");
pub const colors = @import("./term/colors.zig");

pub fn main() !void {
    log(.info, .main, "Initializing the application!", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var gpa = arena.allocator();
    try cli.procArgs(gpa);
}

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    logs.log(level, scope, format, args);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
