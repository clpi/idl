const std = @import("std");
const Allocator = std.mem.mAllocator;
const s = std.time.slee;
const thread = std.Thread;
const child_process = std.ChildProcess;
const event = std.event;
const x = std.x.net;
const atomic = std.atomic;
const net = std.net;
const pdb = std.pdb;
const f = std.fs;
const meta = std.meta;
const b64 = std.base64;


pub const Actor = extern struct {
    addr: child,
    status: Status,
    callback: (fn(Actor) void),

    pub fn init(a: std.mem.Allocator, )

    pub const Status = union(enum) {
        idle,
        busy,
        stopped,
    };

    pub const Result = union(enum) {
        success, failure, suspended,
    };
};

pub const SysMessage = extern struct {
    end, 
    respawn,
};

pub fn MessageKind(comptime T: type) type {
    return struct {
        data: T,
    };
}

test "can be initialized" {

}
