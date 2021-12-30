const std = @import("std");
const print = std.fmt.bufPrint;
const util = @import("./util.zig");
const Token = @import("./token.zig").Token;
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");

pub fn procArgs(gpa: std.mem.Allocator) !void {
    var args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const test_file = @embedFile("../test.is");
    for (args) |arg, arg_count| {
        util.print("Hello!\n", null);
        if (args.len == 1) {
            util.respOk("Welcome to the Idlang TOKENIZER REPL\n");
            while (true) {
                util.prompt();
                const input = try util.readUntil(gpa, '\n');
                const tok = try lexer.lex(gpa, input);
                const tokens = try lexer.tokenListToString(gpa, tok);
                _ = try std.io.getStdOut().writeAll(tokens);
            }
        }
        switch (args.len) {
            1 => {},
            else => {
                std.log.warn("Inputted {d} args -- can't proces {s} yet!", .{ arg_count, arg });
                const tok = try lexer.lex(gpa, test_file);
                const tokens = try lexer.tokenListToString(gpa, tok);
                _ = try std.io.getStdOut().writeAll(tokens);
            },
        }
    }
}

// 1 => {
// std.log.debug("In progress! {s}", .{arg});
// var stdout = try std.io.getStdOut();
//
//
// var file_handle = blk: {
// const fname: []const u8 = arg;
// break :blk try std.fs.cwd().openFile(fname, .{});
// };
// defer file_handle.close();
// const input_content = try file_handle.readToEndAlloc(gpa, std.math.maxInt(usize));

//                 _ = try std.io.getStdOut().write(pretty_output);
//            },
//            else => {
//                continue;
//             }
// }

