const token = @import("./lang/token.zig");
const colors = @import("./term/colors.zig");
const Colors = colors.Color;
const builtin = @import("builtin");
const parser = @import("./lang/parser.zig");
const cli = @import("./cli.zig");
const std = @import("std");
const w = Colors.white;
const d = Colors.red;
const c = Colors.cyan;
const g = Colors.green;
const y = Colors.yellow;
const m = Colors.magenta;
const b = Colors.blue;

pub const log_level: std.log.Level = .debug;

pub const info = std.log.scoped(.info);
pub const warn = std.log.scoped(.warn);
pub const err = std.log.scoped(.err);

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const r = comptime colors.reset();
    const wb = comptime w.bold(.normal_fg);
    const wd = comptime w.finish(.bright_fg);
    const cb = comptime c.bold(.bright_fg);
    const cd = comptime c.dim(.normal_fg);
    const rb = comptime d.bold(.bright_fg);
    const rd = comptime d.finish(.normal_fg);
    const gb = comptime g.bold(.bright_fg);
    const gd = comptime g.finish(.normal_fg);
    const yb = comptime y.bold(.bright_fg);
    const yd = comptime y.finish(.normal_fg);
    const bb = comptime b.bold(.bright_fg);
    const bd = comptime b.finish(.normal_fg);
    const mb = comptime m.bold(.bright_fg);
    const md = comptime m.finish(.normal_fg);
    const sc_colors = switch (scope) {
        .compiler => "[" ++ wb ++ "COMP" ++ wd ++ " :: ",
        .parser => "[" ++ cb ++ "PARS" ++ cd ++ " :: ",
        .lexer => "[" ++ bb ++ "LEX " ++ bd ++ " :: ",
        .vm => "[" ++ mb ++ " VM " ++ md ++ " :: ",
        .cli => "[" ++ yb ++ "CLI " ++ yd ++ " ][ ",
        .ast => "[" ++ bb ++ "AST " ++ bd ++ " ][ ",
        .expr => "[" ++ gb ++ "EXPR" ++ gd ++ ":: ",
        .fmt => yb ++ "FMTG" ++ "\x1b[37;1m" ++ " :: ",
        .token => mb ++ @tagName(scope)[0..3] ++ md ++ " :: ",
        else => if (@enumToInt(level) <= @enumToInt(std.log.Level.err))
            @tagName(scope)
        else
            return,
    };
    const status_pre = switch (level) {
        .debug => gb ++ "DBG " ++ r ++ gd ++ "] -> ",
        .info => bb ++ "INF " ++ r ++ bd ++ "] -> ",
        .warn => yb ++ "WAR " ++ r ++ yd ++ "] -> ",
        .err => rb ++ "ERR " ++ r ++ rd ++ "] -> ",
    };
    // std.debug.getStderrMutex().lock();
    // defer std.debug.getStderrMutex().unlock();
    // const stderr = std.io.getStdErr().writer();
    const stdout = std.io.getStdOut().writer();
    stdout.print(sc_colors ++ status_pre ++ format ++ "\n", args) catch return;
    // nosuspend stderr.print(sc_colors ++ status_pre ++ format ++ "\n", args) catch return;
}
