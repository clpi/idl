const std = @import("std");
const time = std.time;
const client = std.x.net.tcp.Client;
const Box = std.crypto.nacl.Box;
const b = std.crypto.sign.Ed25519;
const stringify = std.json.stringify;


/// Provides a base config for the entire
/// IDL ecosystem, within the IS ecosystem
pub const IdlConfig = struct {

    id: ?[]const u8,
    identity: ?[]const u8,
    created: i64,

    const Self = @This();

    pub fn initialize(identity: ?[]const u8) Self {
        const now = time.timestamp();
    
    }
};

