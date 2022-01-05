const std = @import("std");
const util = @import("./util.zig");
const lexer = @import("./lang/lexer.zig");
const col = @import("./term/colors.zig");
const CProcess = std.ChildProcess;
const Color = col.Color;
const File = std.fs.File;
const io = std.io;
const os = std.os;

pub const IdlShell = struct {
    session_id: usize,
    allocator: std.mem.Allocator,
    mode: Mode = .repl,
    state: State,
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        var state = try State.init(allocator);
        return Self{
            .session_id = 0,
            .mode = .repl,
            .state = state,
            .allocator = allocator,
        };
    }

    pub fn repl(self: Self) !void {
        var exit_flag = false;
        var help_flag = false;
        while (true) rpl: {
            try ShPrompt.promptFmt();
            const input = try util.readUntil(self.allocator, '\n');
            var re = std.mem.split(u8, input, " ");
            var lexr = lexer.Lexer.init(input, self.allocator);
            _ = try lexr.lex();
            const tks = try lexr.tokenListToString();
            _ = try std.io.getStdOut().writeAll(tks);
            const cmd = re.next();
            while (re.next()) |arg| rpl_parse: {
                if (re.index) |ix| if (ix == 0) {
                    if (cmd) |cm| {
                        if (std.mem.eql(u8, cm, "exit") or std.mem.eql(u8, cm, "quit")) {
                            exit_flag = true;
                            break :rpl;
                        } else if (std.mem.startsWith(u8, cm, "--")) {
                            switch (arg[2]) {
                                'Q' => {
                                    exit_flag = true;
                                    break :rpl;
                                },
                                'H' => {
                                    help_flag = true;
                                    break :rpl_parse;
                                },
                                'R' => {},
                                else => {},
                            }
                        } else if (std.mem.startsWith(u8, arg, "-")) {
                            switch (arg[1]) {
                                'Q' => {
                                    exit_flag = true;
                                    break :rpl;
                                },
                                'H' => {
                                    help_flag = true;
                                    break :rpl_parse;
                                },
                                'R' => {},
                                else => {},
                            }
                        }
                    }
                };
            }
            if (exit_flag) {
                respOk("Goodbye!");
                std.process.exit(0);
            }
        }
    }

    pub const State = struct {
        pwd: []const u8,
        pids: []usize,
        prev_cmd: ?[]const u8,
        prompt: ShPrompt,
        session_hist: std.StringArrayHashMap([]const u8),
        curr_hist: std.StringArrayHashMap([]const u8),
        config: std.StringArrayHashMap([]const u8),

        pub fn init(a: std.mem.Allocator) !State {
            var cwd: [256]u8 = undefined;
            _ = try os.getcwd(&cwd);
            const cfg = std.StringArrayHashMap([]const u8).init(a);
            const shi = std.StringArrayHashMap([]const u8).init(a);
            const chi = std.StringArrayHashMap([]const u8).init(a);
            const pr = ShPrompt.default(a);
            return State{
                .pids = undefined,
                .prompt = pr,
                .pwd = &cwd,
                .prev_cmd = null,
                .session_hist = chi,
                .curr_hist = shi,
                .config = cfg,
            };
        }
    };

    pub const Mode = enum(u16) {
        os,
        edit,
        repl,
    };
};

pub const ShPrompt = struct {
    text: []const u8,
    custom: bool,

    pub fn default(a: std.mem.Allocator) ShPrompt {
        return ShPrompt{ .text = promptAlloc(a) catch {
            return ShPrompt{ .text = "idlsh >", .custom = false };
        }, .custom = false };
    }

    pub fn arrowStr(comptime color: Color) []const u8 {
        return comptime color.bold(null) ++ " -> " ++ col.reset();
    }

    pub fn promptAlloc(a: std.mem.Allocator) ![]const u8 {
        const pr = ilangFmt();
        const arr = arrowStr(.yellow);
        return try std.fmt.allocPrint(a, "{s}{s}{s}", .{ pr, "", arr });
    }
    pub fn promptFmt() !void {
        const pr = ilangFmt();
        const arr = arrowStr(.yellow);
        std.debug.print("{s}{s}{s}", .{ pr, "", arr });
    }
};
pub const ShellError = error{
    InvalidInput,
};
pub fn ilangFmt() []const u8 {
    return comptime Color.blue.bold(null) ++ "[" ++ col.reset() ++
        Color.blue.bold(null) ++ " I" ++ col.reset() ++
        Color.green.finish(.bright_fg) ++ "lang " ++ col.reset() ++
        Color.blue.bold(null) ++ "]" ++ col.reset();
}

pub fn respOk(comptime s: []const u8) void {
    const a = .{ comptime ilangFmt(), comptime respDiv(.yellow), comptime okStr(), comptime s };
    std.debug.print("{s}{s}{s}{s}\n", a);
}
pub fn respErr(comptime s: []const u8) void {
    std.debug.print("{s}{s}{s}{s}\n", .{ comptime ilangFmt(), comptime respDiv(.red), comptime errStr(), comptime s });
}
pub fn respDiv(comptime color: Color) []const u8 {
    return comptime color.bold(null) ++ " :: " ++ col.reset();
}
pub fn okStr() []const u8 {
    return comptime Color.green.bold(null) ++ "[" ++ col.reset() ++
        Color.green.bold(null) ++ "OK" ++ col.reset() ++
        Color.green.bold(.bright_fg) ++ "] " ++ col.reset();
}
pub fn errStr() []const u8 {
    return comptime Color.green.bold(null) ++ "[" ++ col.reset() ++
        Color.red.bold(.bright_fg) ++ "ERR" ++ col.reset() ++
        Color.red.bold(.bright_fg) ++ "] " ++ col.reset();
}
