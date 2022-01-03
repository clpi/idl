const std = @import("std");
const eq = std.mem.eql;
const print = std.fmt.bufPrint;
const util = @import("./util.zig");
const Token = @import("./lang/token.zig").Token;
const lexer = @import("./lang/lexer.zig");
const parser = @import("./lang/parser.zig");
const help = @import("./cli/help.zig");
const sh = @import("./cli/sh.zig");
const color = @import("./term/colors.zig");
const Color = color.Color;

pub const Cmd = enum {
    run,
    shell,
    init,
    build,
    help,

    const Self = @This();

    pub fn fromStr(arg: ?[]const u8) !Self {
        var cmd = Cmd.shell;
        if (arg) |a| {
            if (eq(u8, a, "r") or (eq(u8, a, "run"))) {
                cmd = Cmd.run;
            } else if (eq(u8, a, "h") or eq(u8, a, "help") or
                eq(u8, a, "--help") or eq(u8, a, "-h"))
            {
                cmd = Cmd.help;
            } else if (eq(u8, a, "b") or (eq(u8, a, "build"))) {
                cmd = Cmd.build;
            } else if (eq(u8, a, "sh") or (eq(u8, a, "shell"))) {
                cmd = Cmd.shell;
            } else if (eq(u8, a, "i") or (eq(u8, a, "init"))) {
                cmd = Cmd.init;
            } else {
                cmd = Cmd.help;
            }
        } else {
            cmd = Cmd.shell;
        }
        return cmd;
    }

    pub fn exec(self: Self, gpa: std.mem.Allocator) !void {
        switch (self) {
            .run => try tokFile(gpa),
            .shell => try repl(gpa),
            .help => help.print_usage(),
            .init => try tokFile(gpa),
            .build => try repl(gpa),
        }
    }
};

pub fn procArgs(gpa: std.mem.Allocator) !void {
    var args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    util.print("Arg len: {}\n", .{args.len});
    var cnt: usize = 0;
    var cmd = Cmd.help;
    for (args) |arg, arg_count| {
        util.print("Arg {s}: {d}!\n", .{ arg, arg_count });
        if (args.len == 1) {
            cmd = Cmd.shell;
        } else {
            cmd = try Cmd.fromStr(arg);
        }
        cnt += 1;
    }
    _ = try cmd.exec(gpa);
}

pub fn tokFile(gpa: std.mem.Allocator) !void {
    const test_file = @embedFile("../res/test.is");
    util.respOk("Welcome to the Idlang TOKENIZER REPL\n");
    const tok = try lexer.lex(gpa, test_file);
    const tokens = try lexer.tokenListToString(gpa, tok);
    _ = try std.io.getStdOut().writeAll(tokens);
}

pub fn repl(gpa: std.mem.Allocator) !void {
    while (true) {
        util.prompt();
        const input = try util.readUntil(gpa, '\n');
        util.respOk("Tokenizing input...");
        const tok = try lexer.lex(gpa, input);
        const tokens = try lexer.tokenListToString(gpa, tok);
        _ = try std.io.getStdOut().writeAll(tokens);
    }
}
test "repl works" {
    _ = try repl();
    std.testing.expect(true);
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

