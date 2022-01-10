const std = @import("std");
const col = @import("../term/colors.zig");
const r = col.reset();
const Cmd = @import("../cli.zig").Cmd;

pub const intro_msg = col.Color.dim(.blue, .normal_fg) ++
    \\                                                               
    \\              Oh wow, uh, this cli is... 
++ col.reset();
pub const intro_img = col.Color.bold(.green, .bright_fg) ++
    \\
    \\              ___  ~~ ___    ___    ___        ~~        
    \\      ~~    ~/ _ `\  / __`\ / __`\~/ _ `\~       
    \\         ~~ /\ \/\ \/\  __//\ \_\ \\ \/\ \               
    \\------------\ \_\ \_\ \____\ \____/ \_\ \_\---------------------
    \\             \/_/\/_/\/____/\/___/ \/_/\/_/                     
    \\      
    \\
++ col.reset();
pub const subc_title = col.Color.green.bold(.bright_fg) ++
    \\  
    \\  SUBCOMMANDS                                        DESCRIPTION
++ col.reset();
pub const args_title = col.Color.yellow.bold(.bright_fg) ++
    \\
    \\  ARGUMENTS                                          DESCRIPTION
++ col.reset();

pub fn print_usage() void {
    std.debug.print("\n\n", .{});
    const usage_msg = col.Color.blue.bold(.bright_fg) ++
        \\
        \\  USAGE: izi <SUBCMD> [TARGET] [--args]
        \\
    ++ col.reset();
    const subc =
        \\
        \\  - new   | n            Create a new Idl file/project/anything!
        \\  - check | c                  See an overview of your resources
        \\  - build | b                       Build/eval a .is or .il file 
        \\  - run   | r                    Run a specified .is or .il file 
        \\  - shell | s                      Start a shell or REPL session 
        \\  - lsp   | l                   Start a (nonexistent) LSP server 
        \\  - auth  | a               Authorize with (nonexistent) servers 
        \\  - id    | I                Perform identity-related operations
        \\  - init  | i                           Begin a new project type  
        \\  - test  | t                            Test (kinda) your files 
        \\  - about | A                  Information about the Idl project
        \\  - guide | G             A small tutorial to show you the ropes
        \\  - help  | h                        Print the usage info for iz  
        \\
    ++ col.reset();
    const args =
        \\  
        \\  --debug      | -d                Enable verbose output for ops
        \\  --version    | -d                Print out the current version
        \\  --curr-user  | -U              Print out the current user info
        \\  --curr-base  | -B           Information about the active kbase
        \\  --env-info   | -E         Information about usage, storage, ...
        \\  --sync       | -s     Check if workspace(s) are synced anywhere
        \\
        \\
    ;
    const full = intro_msg ++ intro_img ++ usage_msg ++ subc_title ++ subc ++ args_title ++ args;
    std.debug.print(full, .{});
}

pub fn printCmdUsage(cmd: Cmd) void {
    const msg = switch (cmd) {
        .run => run_cmd: {
            const run_usage = col.Fg.Br.green ++
                \\
                \\ RUN subcommand usage:
                \\
                \\     idl run <FILE.is> -o [TARGET] [--args]
                \\
            ++ r();
            const run_opts_d = col.Color.white.finish(.normal_fg) ++
                \\   --verbose | -v             Enables verbose and debug run output
                \\   --base    | -b           Select a specific base by ID to select
                \\   --tags    | -t             Associate tag metadata with this run
                \\
            ++ r();
            break :run_cmd intro_msg ++ run_usage ++ args_title ++ run_opts_d;
        },
        .id => id_cmd: {
            const id_usage = col.Fg.Br.blue ++
                \\
                \\ ID subcommand usage:
                \\
                \\     idl id [SUBCOMMAND] <OPERATION> [--args]
                \\
            ++ r();
            const id_opts = col.Color.white.finish(.normal_fg) ++
                \\   --verbose | -v             Enables verbose and debug run output
                \\   --base    | -b           Select a specific base by ID to select
                \\   --tags    | -t             Associate tag metadata with this run
                \\
            ++ r();
            break :id_cmd intro_msg ++ id_usage ++ args_title ++ id_opts;
        },
        else => std.debug.print("\x1b[32;1bStill working on the docs!\x1b[0m"),
    };
    std.debug.print("{s}", .{msg});
}

const testing = std.testing;
test "help message prints" {
    print_usage();
    try testing.expect(true);
}
