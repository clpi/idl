//! This file implements cursor movements as a result of ANSI
//! escape sequence presence.

/// NOTE: Consider making this a struct?
const std = @import("std");
const mem = std.mem;
const os = std.os;

pub const Cursor = enum {
    up,
    down,
    left,
    right,
    lnup,
    lndown,
};

test "cursor goes up" {}

test "cursor goes down" {}

test "cursor goes right" {}

test "cursor goes left" {}
