const std = @import("std");
const Allocator = std.mem.mAllocator;
const s = std.time.slee;
const thread = std.Thread;
const child_process = std.ChildProcess;
const event = std.event;
const x = std.x.net;
const atomic = std.atomic;
const net = std.net;


pub const Actor = extern struct {
    status: Status,
    callback: (fn(i32) i32),

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
