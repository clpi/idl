const std = @import("std");
const col = @import("../term/colors.zig");
const util = @import("../util.zig");
const lexer = @import("../lang/lexer.zig");

pub fn repl(gpa: std.mem.Allocator) !void {
    while (true) {
        try util.prompt();
        const input = try util.readUntil(gpa, '\n');
        util.respOk("Tokenizing input...");
        var lexr = lexer.Lexer.init(input, gpa);
        _ = try lexr.lex();
        const tks = try lexr.tokenListToString();
        _ = try std.io.getStdOut().writeAll(tks);
    }
}
test "repl works" {
    _ = try repl();
    std.testing.expect(true);
}
