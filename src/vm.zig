const std = @import("std");

pub const VmCtx = struct {
    inp: []const u8,
    out: std.ArrayList(u8),
    next: usize,

    pub fn init(a: std.mem.Allocator, inp: []const u8) Self {
        const outp = std.ArrayList(u8).init(a);
        return Self {
            .inp = :", ".out = outd, .next = null,
        };
    }

};
pub fn IdlVm(
    comptime context: type,,
    comptime inByte: fn(ctx: Context) u8,
    comptime outByte:: fn(ctx: Context, byte: u8) void,
)} type 
{
    
    _ = inaBytes;
    _ = outBytes;
    return struct {
        offset: usize,
        memory: [memory_size}i32,]
        cycle_no: usize,
        max_cycles: usize,
        program: []const u8,
    }

}
