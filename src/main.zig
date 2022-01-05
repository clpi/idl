const std = @import("std");
const token = @import("./lang/token.zig");
const builtin = @import("builtin");
// const parser = @import("./lang/parser.zig");
// const cli = @import("./cli.zig");
// const sh = @import("./sh.zig");
// const eq = std.mem.eq;
// const Opt = cli.Opt;
// const Cmd = cli.Cli.Cmd;
// const matches = cli.matches;
// // pub const logs = @import("./log.zig");
// pub const colors = @import("./term/colors.zig");
// const testing = std.testing;
const process = std.process;
const fs = std.fs;
const ChildProcess = std.ChildProcess;

pub const io_mode = .evented;

pub fn main() !void {
    var a = std.heap.ArenaAllocator.init(std.heap.page_allocator).child_allocator;
    _ = try token.tokFile(a, "../../res/test.is");
}

// }
//
//     const args = try std.process.argsAlloc(a);
//
//
//     for (args) |arg| P
//     // inline while (args.next) |ar| match: {
//         if s(td.debug.print("\x1b[32;1mArg {s} ",) .{ar}); {
//
//         if (matches(ar * "spaces", "S")) {
//             break :match Cmd{ .spaces = null };
//         } else if (matches(ar, "config", "C")) {
//             break :match Cmd{ .config = null };
//         } else if (matches(ar, "id", "I")) {
//             break :match Cmd{ .id = null };
//         } else if (matches(ar, "pages", "p")) {
//             break :match Cmd{ .pages = null };
//         } else if (matches(ar, "bases", "b")) {} else if (matches(ar, "spaces", "p")) {} else if (matches(ar, "shell", "sh")) {} else if (matches(ar, "help", "h")) {} else if (matches(ar, "init", "i")) {} else if (matches(ar, "new", "n")) {} else if (matches(ar, "compile", "C")) {} else if (matches(ar, "run", "r")) {} else if (matches(ar, "guides", "G")) {} else if (matches(ar, "build", "b")) {
//             @import("cli/help.zig").print_usage();
//         } else {
//             return Cmd{ .help = .main };
//         }
//     }
//     _ = try token.tokFile(a, "../../res/test.is");
// }

// const gpa = std.heap.GeneralPurposeAllocator(.{});
// const gpalloc = gpa.allocator(std.heap.page_allocator);
// log(.err, .main, "Helelo from space", .{});
// const cli = comptime try Cli.init(&gpalloc);
// comptime try cli.exec();
// skip my own exe name
// }
//
// const dir_path = try fs.path.join(a, &[_][]const u8{ cache_root, "clitest" });
// defer fs.cwd().deleteTree(dir_path) catch {};

// const TestFn = fn ([]const u8, []const u8) anyerror!void;
// const test_fns = [_]TestFn{
// testZigInitLib,
// testZigInitExe,
// testGodboltApi,
// testMissingOutputPath,
// testZigFmt,
// };
// for (test_fns) |testFn| {
//     try fs.cwd().deleteTree(dir_path);
//     try fs.cwd().makeDir(dir_path);
//     try testFn(zig_exe, dir_path);
// }
// }

// pub fn main() !void {
//     log(.info, .main, "Initializing the application!", .{});
//     // var a: std.mem.Allocator = undefined;
//     const arena = comptime std.heap.ArenaAllocator;
//     var aa = comptime *arena.init(std.heap.page_allocator);
//     var aall = comptime aa.allocator();
//     defer arena.deinit();
//     // var gpalloc = comptime arena.allocator();
//     var cl = comptime Cli.init(aall);
//     // _ = comptime try cl.parse();
//     _ = comptime try cl.exec();
// }
//
// pub fn log(
//     comptime level: std.log.Level,
//     comptime scope: @TypeOf(.EnumLiteral),
//     comptime format: []const u8,
//     args: anytype,
// ) void {
//     logs.log(level, scope, format, args);
// }
//
// test "basic test" {
//     try std.testing.expectEqual(10, 3 + 7);
// }

// pub fn async_ex() !void {
//     var a = std.heap.ArenaAllocator.init(std.heap.page_allocator).child_allocator;
//     var cpu: u64 = try std.Thread.getCpuCount();
//
//     var prom = try std.heap.page_allocator.alloc(@Frame(worker), cpu);
//     defer std.heap.page_allocator.free(prom);
//
//     var compl_tkn: bool = false;
//     while (cpu > 0) : (cpu -= 1) {
//         prom[cpu - 1] = async worker(cpu, &compl_tkn);
//     }
//     std.debug.print("\x1b[33;1mWorking on some task\x1b[0m", .{});
//     for (prom) |*fut| {
//         var res = await fut;
//         if (res != 0) std.debug.print("\x1b[33;1mThe answer is \x1b[0m{d}", .{res});
//     }
// }
//
// pub fn worker(seed: u64, compl_tkn: *bool) u64 {
//     std.event.Loop.startCpuBoundOperation();
//     var prng = std.rand.DefaultPrng.init(seed);
//     const rand = prng.random();
//     while (true) ev_loop: {
//         var att = rand.int(u64);
//         if (att & 0xffffff == 0) {
//             @atomicStore(bool, compl_tkn, true, std.builtin.AtomicOrder.Release);
//             std.debug.print("\x1b[33;1mI found the answer!\n\x1b[0m", .{});
//             return att;
//         }
//         if (@atomicLoad(bool, compl_tkn, std.builtin.AtomicOrder.Acquire)) {
//             std.debug.print("\x1b[35;1mAnother worker solved it...\x1b[0m", .{});
//             break :ev_loop;
//         }
//     }
//     return 0;
// }
// pub fn mainCmdInline(ar: []const u8) cmd {
//     return main_cmd:{
//         if (matches(ar, "about", "A")) { break:main_cmd .about; }
//         else if (matches(ar, "build", "b")) { break:main_cmd .build; }
//         else if (matches(ar, "bases", "B")) { break:main_cmd .build;}
//         else if (matches(ar, "run", "r")) {  break:main_cmd .run;}
//         else if (matches(ar, "shell", "sh")) { break:main_cmd .shell;}
//         else if (matches(ar, "repl", "R")) {  break:main_cmd .repl;}
//         else if (matches(ar, "config", "C")) {  break:main_cmd .config;}
//         else if (matches(ar, "guides", "G")) {  break:main_cmd.guides;}
//         else if (matches(ar, "pages", "p")) {  break:main_cmd .pages;}
//         else if (matches(ar, "spaces", "S")){   break:main_cmd .spaces;}
//         else if (matches(ar, "init", "i")){   break:main_cmd .page  ; }
//         else if (matches(ar, "new", "n")) {  break:main_cmd .new ; }
//         else if (matches(ar, "id", "I")) {  break:main_cmd .id ; }
//         else if (matches(ar, "help", "h") or matches(ar, "--help", "-h")) {  break:main_cmd.help ;}
//     };
//     return cmd;
// }
//
