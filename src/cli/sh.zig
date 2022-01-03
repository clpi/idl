const std = @import("std");
const col = @import("../term/colors.zig");
const util = @import("../util.zig");
const lexer = @import("../lang/lexer.zig");

pub fn repl(gpa: std.mem.Allocator) !void {
    while (true) {
        try util.prompt();
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
