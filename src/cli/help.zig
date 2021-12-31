const std = @import("std");
const col = @import("../term/colors.zig");
// const util = @import("../util.zig");
// const print = util.printA;

pub fn print_usage() void {
    std.debug.print("\n\n", .{});
    const intro_msg =
        \\   ~~                                   ~~                ~~ 
        \\              Oh wow, uh, this cli is... 
        \\              ___  ~~ ___    ___    ___        ~~        
        \\      ~~    ~/ _ `\  / __`\ / __`\~/ _ `\~       
        \\         ~~ /\ \/\ \/\  __//\ \_\ \\ \/\ \               
        \\------------\ \_\ \_\ \____\ \____/ \_\ \_\---------------------
        \\             \/_/\/_/\/____/\/___/ \/_/\/_/                     
        \\      
        \\
    ;
    const greet_msg = intro_msg ++
        \\
        \\  USAGE: izi <SUBCMD> [TARGET] [--args]
        \\
        \\  SUBCOMMANDS                                     DESCRIPTION
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
        \\  ARGUMENTS
        \\  --help <CMD>   | -h         An alternative way of getting help 
        \\  --verbose      | -v              Enable verbose output for ops
        \\
    ;
    std.debug.print(greet_msg, .{});
}

const testing = std.testing;
test "help message prints" {
    print_usage();
    try testing.expect(true);
}
