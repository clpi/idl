const std = @import("std");
/// Zig version. When writing code that supports multiple versions of Zig, prefer
/// feature detection (i.e. with `@hasDecl` or `@hasField`) over version checks.
pub const zig_version = std.SemanticVersion.parse("0.9.0-dev.1946+dbfcebf8d") catch unreachable;
/// Temporary until self-hosted is feature complete.
pub const zig_is_stage2 = false;
/// Temporary until self-hosted supports the `cpu.arch` value.
pub const stage2_arch: std.Target.Cpu.Arch = .aarch64;
/// Temporary until self-hosted can call `std.Target.x86.featureSetHas` at comptime.
pub const stage2_x86_cx16 = false;

pub const output_mode = std.builtin.OutputMode.Exe;
pub const link_mode = std.builtin.LinkMode.Dynamic;
pub const is_test = false;
pub const single_threaded = false;
pub const abi = std.Target.Abi.gnu;
pub const cpu: std.Target.Cpu = .{
    .arch = .aarch64,
    .model = &std.Target.aarch64.cpu.apple_a14,
    .features = std.Target.aarch64.featureSet(&[_]std.Target.aarch64.Feature{
        .aes,
        .aggressive_fma,
        .alternate_sextload_cvt_f32_pattern,
        .altnzcv,
        .am,
        .arith_bcc_fusion,
        .arith_cbz_fusion,
        .ccdp,
        .ccidx,
        .ccpp,
        .complxnum,
        .contextidr_el2,
        .crc,
        .crypto,
        .disable_latency_sched_heuristic,
        .dit,
        .dotprod,
        .flagm,
        .fp16fml,
        .fp_armv8,
        .fptoint,
        .fullfp16,
        .fuse_address,
        .fuse_aes,
        .fuse_arith_logic,
        .fuse_crypto_eor,
        .fuse_csel,
        .fuse_literals,
        .jsconv,
        .lor,
        .lse,
        .mpam,
        .neon,
        .nv,
        .pan,
        .pan_rwv,
        .pauth,
        .perfmon,
        .pmu,
        .predres,
        .ras,
        .rcpc,
        .rcpc_immo,
        .rdm,
        .sb,
        .sel2,
        .sha2,
        .sha3,
        .specrestrict,
        .ssbs,
        .tlb_rmi,
        .tracev8_4,
        .uaops,
        .v8_1a,
        .v8_2a,
        .v8_3a,
        .v8_4a,
        .v8a,
        .vh,
        .zcm,
        .zcz,
        .zcz_gp,
    }),
};
pub const os = std.Target.Os{
    .tag = .macos,
    .version_range = .{ .semver = .{
        .min = .{
            .major = 12,
            .minor = 0,
            .patch = 1,
        },
        .max = .{
            .major = 12,
            .minor = 0,
            .patch = 1,
        },
    }},
};
pub const target = std.Target{
    .cpu = cpu,
    .os = os,
    .abi = abi,
};
pub const object_format = std.Target.ObjectFormat.macho;
pub const mode = std.builtin.Mode.Debug;
pub const link_libc = true;
pub const link_libcpp = false;
pub const have_error_return_tracing = true;
pub const valgrind_support = false;
pub const position_independent_code = true;
pub const position_independent_executable = true;
pub const strip_debug_info = false;
pub const code_model = std.builtin.CodeModel.default;
