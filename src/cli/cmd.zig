const std = @import("std");

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
            } else if (eq(u8, a, "h") or (eq(u8, a, "help"))) {
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
