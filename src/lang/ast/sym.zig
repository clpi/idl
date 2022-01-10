const std = @import("std");



pub const SymDecl = struct {
    pos: usize,
    stype: ?typecode,
    token_code: u32,
    public: bool,
}

