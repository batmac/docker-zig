//! This file is auto-generated by tools/update_cpu_features.zig.

const std = @import("../std.zig");
const CpuFeature = std.Target.Cpu.Feature;
const CpuModel = std.Target.Cpu.Model;

pub const Feature = enum {
    @"10e60",
    @"2e3",
    @"3e3r1",
    @"3e3r3",
    @"3e7",
    @"7e10",
    btst16,
    doloop,
    e1,
    e2,
    elrw,
    fpuv2_df,
    fpuv2_sf,
    fpuv3_df,
    fpuv3_sf,
    hard_float,
    hard_float_abi,
    java,
    mp1e2,
};

pub const featureSet = CpuFeature.feature_set_fns(Feature).featureSet;
pub const featureSetHas = CpuFeature.feature_set_fns(Feature).featureSetHas;
pub const featureSetHasAny = CpuFeature.feature_set_fns(Feature).featureSetHasAny;
pub const featureSetHasAll = CpuFeature.feature_set_fns(Feature).featureSetHasAll;

pub const all_features = blk: {
    const len = @typeInfo(Feature).Enum.fields.len;
    std.debug.assert(len <= CpuFeature.Set.needed_bit_count);
    var result: [len]CpuFeature = undefined;
    result[@enumToInt(Feature.@"10e60")] = .{
        .llvm_name = "10e60",
        .description = "Support CSKY 10e60 instructions",
        .dependencies = featureSet(&[_]Feature{
            .@"7e10",
        }),
    };
    result[@enumToInt(Feature.@"2e3")] = .{
        .llvm_name = "2e3",
        .description = "Support CSKY 2e3 instructions",
        .dependencies = featureSet(&[_]Feature{
            .e2,
        }),
    };
    result[@enumToInt(Feature.@"3e3r1")] = .{
        .llvm_name = "3e3r1",
        .description = "Support CSKY 3e3r1 instructions",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.@"3e3r3")] = .{
        .llvm_name = "3e3r3",
        .description = "Support CSKY 3e3r3 instructions",
        .dependencies = featureSet(&[_]Feature{
            .doloop,
        }),
    };
    result[@enumToInt(Feature.@"3e7")] = .{
        .llvm_name = "3e7",
        .description = "Support CSKY 3e7 instructions",
        .dependencies = featureSet(&[_]Feature{
            .@"2e3",
        }),
    };
    result[@enumToInt(Feature.@"7e10")] = .{
        .llvm_name = "7e10",
        .description = "Support CSKY 7e10 instructions",
        .dependencies = featureSet(&[_]Feature{
            .@"3e7",
        }),
    };
    result[@enumToInt(Feature.btst16)] = .{
        .llvm_name = "btst16",
        .description = "Use the 16-bit btsti instruction",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.doloop)] = .{
        .llvm_name = "doloop",
        .description = "Enable doloop instructions",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.e1)] = .{
        .llvm_name = "e1",
        .description = "Support CSKY e1 instructions",
        .dependencies = featureSet(&[_]Feature{
            .elrw,
        }),
    };
    result[@enumToInt(Feature.e2)] = .{
        .llvm_name = "e2",
        .description = "Support CSKY e2 instructions",
        .dependencies = featureSet(&[_]Feature{
            .e1,
        }),
    };
    result[@enumToInt(Feature.elrw)] = .{
        .llvm_name = "elrw",
        .description = "Use the extend LRW instruction",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.fpuv2_df)] = .{
        .llvm_name = "fpuv2_df",
        .description = "Enable FPUv2 double float instructions",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.fpuv2_sf)] = .{
        .llvm_name = "fpuv2_sf",
        .description = "Enable FPUv2 single float instructions",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.fpuv3_df)] = .{
        .llvm_name = "fpuv3_df",
        .description = "Enable FPUv3 double float instructions",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.fpuv3_sf)] = .{
        .llvm_name = "fpuv3_sf",
        .description = "Enable FPUv3 single float instructions",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.hard_float)] = .{
        .llvm_name = "hard-float",
        .description = "Use hard floating point features",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.hard_float_abi)] = .{
        .llvm_name = "hard-float-abi",
        .description = "Use hard floating point ABI to pass args",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.java)] = .{
        .llvm_name = "java",
        .description = "Enable java instructions",
        .dependencies = featureSet(&[_]Feature{}),
    };
    result[@enumToInt(Feature.mp1e2)] = .{
        .llvm_name = "mp1e2",
        .description = "Support CSKY mp1e2 instructions",
        .dependencies = featureSet(&[_]Feature{
            .@"3e7",
        }),
    };
    const ti = @typeInfo(Feature);
    for (result) |*elem, i| {
        elem.index = i;
        elem.name = ti.Enum.fields[i].name;
    }
    break :blk result;
};

pub const cpu = struct {
    pub const generic = CpuModel{
        .name = "generic",
        .llvm_name = "generic",
        .features = featureSet(&[_]Feature{}),
    };
};
