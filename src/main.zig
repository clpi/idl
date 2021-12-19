const std = @import("std");
const token = @import("token.zig");
const parser = @import("./parser.zig");

pub fn main() !void {
    // var gp_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(!gp_allocator.deinit());
    // const gpa = gp_allocator.allocator();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var gpa = arena.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len > 1) {
        for (args) |arg, i| {
            switch (i) {
                0 => continue,
                1 => {
                    var file_handle = blk: {
                        const fname: []const u8 = arg;
                        break :blk try std.fs.cwd().openFile(fname, .{});
                    };
                    defer file_handle.close();
                    const input_content = try file_handle.readToEndAlloc(gpa, std.math.maxInt(usize));

                    const tokens = try token.lex(gpa, input_content);
                    const pretty_output = try token.tokenListToString(gpa, tokens);
                    _ = try std.io.getStdOut().write(pretty_output);
                },
                else => {
                    continue;
                },
            }
        }
    }
    // We accept both files and standard input.
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
