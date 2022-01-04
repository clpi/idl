const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const IdlVm = struct {
    const Self = @This();

    alloc: Allocator,
    stack: [stack_size]i32,
    stack_p: usize,
    prog_ct: usize,
    program: ArrayList(u8),
    tokens: ArrayList([]const u8),
    globals: ArrayList(i32),
    out: ArrayList(u8),

    const stack_size: usize = 64;
    const str_size: usize = @sizeOf(i32);

    pub fn init(a: Allocator, prog: ArrayList(u8), tok: ArrayList([]const u8), globals: ArrayList(i32)) Self {
        return IdlVm{
            .alloc = a,
            .stack = [_]i32{std.math.maxInt(i32)} ** stack_size,
            .tokens = tok,
            .program = prog,
            .globals = globals,
            .out = ArrayList.init(a),
            .stack_p = 0,
            .prog_ct = 0,
        };
    }
};
