const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();
const fs = std.fs;

pub fn readFile(alloc: std.mem.Allocator, filen: []const u8) ![]const u8 {
    var cwd = fs.cwd();
    const fl = try cwd.openFile(filen, .{});
    defer fl.close();
    const txt = try fl.reader().readAllAlloc(alloc, std.math.maxInt(usize));
    std.debug.print("{s}", .{txt});
    return txt;
}

const expect = std.testing.expect;
const testing = std.testing;
const ArenaAllocator = std.heap.ArenaAllocator;
const page_allocator = std.heap.page_allocator;
// var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "readFile ok" {
    var arena = ArenaAllocator.init(page_allocator);
    defer arena.deinit();
    var gpa = arena.allocator();
    const text: []const u8 = try readFile(gpa, "src/util/fs.zig");
    var buf: [fs.MAX_PATH_BYTES]u8 = undefined;
    const cwd = try std.os.getcwd(buf[0..]);
    std.log.warn("\n{s}", .{cwd});
    std.log.warn("\n{s}", .{text});
    try expect(true);
}
