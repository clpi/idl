const std = @import("std");
const eq = std.mem.eql;
const print = std.fmt.bufPrint;
const util = @import("./util.zig");
const sh = @import("./sh.zig");
const ast = @import("./lang/ast.zig");
const Ast = ast.Ast;
const token = @import("./lang/token.zig");
const Token = token.Token;
const lexer = @import("./lang/lexer.zig");
const parser = @import("./lang/parser.zig");
const help = @import("./cli/help.zig");
const color = @import("./term/colors.zig");
const Color = color.Color;

pub fn run() void {}

pub const Cli = struct {
    const Self = @This();

    alloc: std.mem.Allocator,
    main_cmd: ?Cmd = Cmd{ .help = .main },
    sub_cmd: ?[]const u8 = null,
    args: ?[]const []const u8 = null,
    opts: std.StringArrayHashMap([]const u8),

    pub fn initMain(
        a: std.mem.Allocator,
    ) Cli {
        var args = try std.process.args();
        _ = args.skip();
        var cmdm = if ((args.next(a) catch null)) |cmd| cmd else null;
        return Cli{ std.process.ArgIterator.n, .main_cmd = cmdm, .sub_cmd = null, .opts = null };
    }

    pub fn init() !Cli {
        var a = std.heap.ArenaAllocator.init(std.heap.page_allocator).child_allocator;
        var args = try std.process.argsAlloc(a);
        defer std.process.argsFree(a, args);
        var mcmd: ?[]const u8 = null;
        var scmd: ?[]const u8 = null;
        var args = std.process.args()
        whil
        for (args) |arg, i| {
            if (i == 0) {
                return Cli{ .alloc = a, .main_cmd = Cmd{ .help = .main } };
            }
            std.debug.print("\x1b[33m CMD #:{d} CMD: {s}\x1b[0m", .{ i, arg });
            if (i == 1) {
                mcmd = try Cmd.mainCmd(arg);
            } else if (i == 2) {
                scmd = try Cmd.subCmd(scmd);
            } else {
                std.debug.print("\x1b34mArgs: {d}: {s}\x1b[0m", .{ i, arg });
            }
        }
    }

    pub fn parse(self: Self) !void {
        std.debug.print("Parsing {s}", .{self});
    }

    pub fn exec(cli: Cli) !void {
        if (cli.main_cmd) |mc| return switch (mc) {
            .lang => {
                std.debug.print("\x1b[32;1mConfigure language compiler settings\x1b[0m\n", .{});
            },
            .run => {
                std.debug.print("\x1b[32;1mRun an Idlang/Idldown file or workspace\x1b[0m\n", .{});
                if (cli.sucmd) |sc| {
                    const file = try std.fs.path.resolve(cli.alloc, &[_][]const u8{sc});
                    std.debug.print("Found file at {s}", file);
                    var bf: [2048]u8 = undefined;
                    _ = try std.io.CountingReader(u8).reader().readAllAlloc(cli.alloc, 2048);
                    const lx = try lexer.Lexer.init(bf, cli.alloc);
                    _ = try lx.lex();
                    const tokens = try lx.tokenListToString();
                    _ = try std.io.getStdOut().writeAll(tokens);
                }
                try token.tokFile(cli.allocator);
            },
            .shell => {
                std.debug.print("\x1b[32;1mOpen up a base instance of the Idlshell\x1b[0m\n", .{});
                const shl = try sh.IdlShell.init(cli.allocator);
                try shl.repl();
            },
            .help => {
                std.debug.print("\x1b[32;1mGet help for each subcommand\x1b[0m\n", .{});
                help.print_usage();
            },
            .init => {
                std.debug.print("\x1b[32;1mInit a new Idlang/Idlsdown workspace/environment\x1b[0m\n", .{});
                try token.tokFile(cli.allocator);
            },
            .build => {
                std.debug.print("\x1b[32;1mBuild an Idlang module/book/workspace/project, or single file to executable/library\x1b[0m\n", .{});
                const shell = try sh.IdlShell.init(cli.allocator);
                try shell.repl();
            },
            .repl => {
                std.debug.print("\x1b[32;1mOpen up a Idlang interprete/Idl ecosystem interfacer\x1b[0m\n", .{});
                const shell = try sh.IdlShell.init(cli.allocator);
                try shell.repl();
            },
            .id => {
                std.debug.print("\x1b[32;1mManage your IDs and keys, centrally and across peers\x1b[0m\n", .{});
                // const shell = try sh.IdlShell.init(gpa); // open shell to key manaagement
                // try shell.repl();
            },
            .guide => {
                std.debug.print("\x1b[32;1mA guide to how you should; and why you would- use this\x1b[0m\n", .{});
                const shell = try sh.IdlShell.init(cli.allocator); // open shell to key manaagement
                try shell.repl();
                // Open shell to interactive guide
            },
            .about => {
                std.debug.print("\x1b[32;1mAbout the Idlang project\x1b[0m\n", .{});
                help.print_usage(); // Open pager or something for more in-depth readme
            },
            .config => {
                std.debug.print("\x1b[32;1mConfigure your Idlang!\x1b[0m\n", .{});
            },
            else => std.debug.print("\x1b[32;1mUnder development!\x1b[0m\n", .{}),
        };
    }

    pub const Cmd = union(enum) {
        pub fn cmdSubcmd(a: std.mem.Allocator) [2]Cmd {
            var args = std.process.args();
            _ = args.skip();
            var cmdm = if ((args.next(a) catch null)) |cmd| cmd else null;
            var cmds = if ((args.next(a) catch null)) |cmd| cmd else null;
            std.debug.print("\x1b[32;1m COMMAND = {s}\n,\x1b[34;1m SUBCMD = {s}\n ", .{ cmdm, cmds });
            var mcmd = try Cmd.mainCmd(cmdm);
            var scmd = try Cmd.subCmd(cmds);
            return .{ mcmd, scmd };
        }
        pub fn mainCmd(ar: []const u8) !Cli.Cmd {
            for (std.meta.FieldEnum(Cli.Cmd)) |field| {
                if (matches(ar, field.name, field.name[0])) {
                    const cmd_idx = std.meta.fieldIndex(Cli.Cmd, field.name) orelse Cli.Cmd.help;
                    return @intToEnum(Cli.Cmd, cmd_idx);
                } else return null;
            }
            return null;
        }
        pub fn subCmd(self: Cli.Cmd, arg: []const u8) !Cli.Cmd {
            return switch (self) {
                .help => for (std.meta.FieldEnum(Cli.Cmd)) |field| {
                    if (matches(arg, field.name, field.name[0])) {
                        const cmd_idx = std.meta.fieldIndex(Cli.Cmd, field.name) orelse Cli.Cmd.help;
                        return @intToEnum(Cli.Cmd, cmd_idx);
                    }
                },
                else => return null,
            };
        }
        /// Run an Idlscript or Idldown document with provided settings
        run: ?struct {
            file: std.fs.File,
            compile_opts: anytype,
        },
        /// Use the Idl shell and perform configuration
        shell: ?struct {
            init_cmd: []const u8,
            profile: []const u8,
        },
        /// Configure and view configuration
        config: ?union(enum) {
            set: struct {
                key: []const u8,
                val: []const u8,
            },
            get: []const u8,
            list,
            init,
        },
        /// Specifically code-related utils and subcommands
        lang: ??union(enum) { lint, lsp },
        /// Configure your knowledge bases
        bases: ?union(enum) {
            init: struct {},
            delete: []const u8,
            switch_to: []const u8,
            list: struct {
                filters: []const u8 = null,
            },
            all: bool,
            @"switch": []const u8,
            clear,
        },
        /// Configure your pages of notes and data and code
        pages: ??union(enum) {
            add: struct {
                name: []const u8,
                desc: []const u8,
                tags: [][]u8,
            },
            remove: []const u8,
            list,
            clear,
        },
        /// Configure your collaborative tooling
        spaces: ?union {
            add: struct {
                name: []const u8,
                desc: []const u8,
                tags: [][]u8,
            },
            remove: []const u8,
            list: enum { local, networked },
            clear: enum { all, with_tags },
        },
        /// Initialize some Idl resource
        init: ?struct {
            name: []const u8,
        },
        //// Build an Idlang/Idldown file or project/workspace
        build: ?struct {

            //// Get help on the CLI or any specific commands
        },
        help: union(enum) {
            main,
            cmd: []const u8,
            color: bool,
        },
        //// Create some new resource within a spece/base
        new: ?struct {},
        //// Launch the Idl shell to the REPL for Idlang/Idldown
        repl: ?struct {},
        //// Launch ID configuration editor for private/public keys and auth
        id: ??union(enum) {
            keypair: struct {},
            sign: struct {},
            verify: struct {},
            sync: struct {},
            login: struct {},
        },
        //// Launch one of several (to be made) guides on how to use the platform
        guide: ?enum(u8) {
            how_to,
            commands,
            idlang,
            idldown,
        },
        //// About the project
        about: ?union { goals: []const u8, description: []const u8 },

        const cli = @This();
    };
};
pub fn Opt() type {
    return struct {
        pub const Kind = enum(u2) { short = 1, long = 2 };

        kind: Opt.Kind,
        key: []const u8,
        flag: bool = true,
        /// Could genericize this but not necessary?
        val: ?[]const u8 = null,
        parent_cmd: *Cli.Cmd,

        pub fn isOpt(s: []const u8) ?Opt.Kind {
            if (std.mem.startsWith(u8, s, "-")) return Opt.Kind.short else if (std.mem.startsWith(u8, s, "--")) return Opt.kind.long else return null;
        }

        /// Queried on the term immediately following an opt, rn naively assuming all such
        /// opts to be fulfilling values of their prior flaggs
        pub fn isOptVal(self: Opt, s: []const u8) ?Opt {
            if (!isOpt(s)) return Opt{
                .kind = self.kind,
                .key = self.key,
                .parent_cmd = self.parent_cmd,
                .flag = false,
                .val = s,
            };
            return null;
        }

        pub fn isOptKey(pcmd: *Cli.Cmd, s: []const u8) ?Opt {
            return if (isOpt(s)) |ok| ptp: {
                return switch (ok) {
                    .short => {
                        break :ptp Opt{ .parent_cmd = pcmd, .kind = .short, .key = s[1..], .val = null };
                    },
                    .long => {
                        break :ptp Opt{ .parent_cmd = pcmd, .kind = .long, .key = s[2..], .val = null };
                    },
                };
            };
        }
    };
}

pub fn matches(arg: []const u8, a1: []const u8, a2: []const u8) bool {
    return (std.mem.eql(u8, a1, arg) and std.mem.eql(u8, a2, arg));
}
