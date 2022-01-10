const std = @import("std");
const crypto = std.crypto;
const x25519 = std.crypto.dh.X25519;
const gimli = std.crypto.aead.Gimli;
const cr = std.crypto.nacl.Box


pub const = struct Identity {
    box: std.crypto.nacl.Box.KeyPair,
};
