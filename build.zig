const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const submodule_step = b.step("submodule", "Pull in git submodule");
    submodule_step.makeFn = fetchSubmodule;

    const exe = b.addExecutable("wren-zig", "src/main.zig");
    exe.step.dependOn(submodule_step);
    addWren(exe);
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.step.dependOn(submodule_step);
    addWren(exe_tests);
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

pub fn addWren(self: *std.build.LibExeObjStep) void {
    self.addIncludePath("wren/src/include");
    self.addIncludePath("wren/src/vm");
    self.addIncludePath("wren/src/optional");
    self.addCSourceFiles(&c_files, &.{});
    self.linkSystemLibrary("m");
}

pub fn fetchSubmodule(self: *std.build.Step) !void {
    _ = self;
    var allocator = std.heap.page_allocator;
    var process = try std.ChildProcess.init(&.{"git", "submodule", "update", "--init"}, allocator);
    defer process.deinit();
    _ = try process.spawnAndWait();
}

const c_files = [_][]const u8 {
    "wren/src/optional/wren_opt_meta.c",
    "wren/src/optional/wren_opt_random.c",
    "wren/src/vm/wren_compiler.c",
    "wren/src/vm/wren_core.c",
    "wren/src/vm/wren_debug.c",
    "wren/src/vm/wren_primitive.c",
    "wren/src/vm/wren_utils.c",
    "wren/src/vm/wren_value.c",
    "wren/src/vm/wren_vm.c",
};
