const std = @import("std");
const ascii = std.ascii;
const actrl = std.ascii.control_code;
const spaces = std.ascii.spaces;
const unic = std.unicode;
const mem = std.mem.eql;
const os = std.os;
const io = std.io;

pub fn ansii(esc: ascii.control_code) []const u8 {
    return &[_]u8{@enumToInt(esc)};
}
