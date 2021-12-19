const std = @import("std");
const token = @import("token.zig");
const parser = @import("./parser.zig");

pub fn procArgs(gpa: std.mem.Allocator) !void {
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len > 1) {
        for (args) |arg, i| {
            switch (i) {
                0 => continue,
                1 => {
                    std.log.debug("In progress! {s}", .{arg});
                    // var file_handle = blk: {
                    //     const fname: []const u8 = arg;
                    //     break :blk try std.fs.cwd().openFile(fname, .{});
                    // };
                    // defer file_handle.close();
                    // const input_content = try file_handle.readToEndAlloc(gpa, std.math.maxInt(usize));

                    // const tokens = try token.lex(gpa, input_content);
                    // const pretty_output = try token.tokenListToString(gpa, tokens);
                    // _ = try std.io.getStdOut().write(pretty_output);
                },
                else => {
                    continue;
                },
            }
        }
    }
}
