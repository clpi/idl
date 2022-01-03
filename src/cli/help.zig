const std = @import("std");
const col = @import("../term/colors.zig");
// const util = @import("../util.zig");
// const print = util.printA;

pub fn print_usage() void {
    std.debug.print("\n\n", .{});
    const intro_msg = col.Color.dim(.blue, .normal_fg) ++
        \\                                                               
        \\              Oh wow, uh, this cli is... 
    ++ col.reset();
    const intro_img = col.Color.bold(.green, .bright_fg) ++
        \\
        \\              ___  ~~ ___    ___    ___        ~~        
        \\      ~~    ~/ _ `\  / __`\ / __`\~/ _ `\~       
        \\         ~~ /\ \/\ \/\  __//\ \_\ \\ \/\ \               
        \\------------\ \_\ \_\ \____\ \____/ \_\ \_\---------------------
        \\             \/_/\/_/\/____/\/___/ \/_/\/_/                     
        \\      
        \\
    ++ col.reset();
    const usage_msg = col.Color.blue.bold(.bright_fg) ++
        \\
        \\  USAGE: izi <SUBCMD> [TARGET] [--args]
        \\
    ++ col.reset();
    const subc_title = col.Color.green.bold(.bright_fg) ++
        \\  
        \\  SUBCOMMANDS                                        DESCRIPTION
    ++ col.reset();
    const subc =
        \\
        \\  - build | b                       Build/eval a .is or .il file 
        \\  - run   | r                    Run a specified .is or .il file 
        \\  - shell | s                      Start a shell or REPL session 
        \\  - lsp   | l                   Start a (nonexistent) LSP server 
        \\  - auth  | a               Authorize with (nonexistent) servers 
        \\  - init  | i                           Begin a new project type  
        \\  - test  | t                            Test (kinda) your files 
        \\  - help  | h                        Print the usage info for iz  
        \\
    ++ col.reset();
    const args_title = col.Color.yellow.bold(.bright_fg) ++
        \\
        \\  ARGUMENTS                                          DESCRIPTION
        \\
    ++ col.reset();
    const args =
        \\  --help <CMD> | -h           An alternative way of getting help 
        \\  --debug      | -d                Enable verbose output for ops
        \\  --version    | -d                Print out the current version
        \\
        \\
    ;
    const full = intro_msg ++ intro_img ++ usage_msg ++ subc_title ++ subc ++ args_title ++ args;
    std.debug.print(full, .{});
}

const testing = std.testing;
test "help message prints" {
    print_usage();
    try testing.expect(true);
}
