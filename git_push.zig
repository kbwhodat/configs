const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Initialize an array list to hold the arguments.
    var argsList = std.ArrayList([]const u8).init(allocator);
    defer argsList.deinit();

    // Fetch command-line arguments and add them to the list.
    var args_it = std.process.args();
    while (args_it.next()) |arg| {
        try argsList.append(arg);
    }

    // Skip the first argument, which is the program name, then create the command string.
    var cmd = std.ArrayList(u8).init(allocator);
    try cmd.appendSlice("cd ~/notes && ");
    for (argsList.items[1..]) |arg| {
        try cmd.appendSlice(arg);
        try cmd.appendSlice(" ");
    }

    const full_cmd = try cmd.toOwnedSlice();
    const args_for_child = [_][]const u8{ "bash", "-c", full_cmd };

    // Run the command.
    var child = std.ChildProcess.init(&args_for_child, allocator);
    try child.spawn();
    _ = try child.wait(); // Ignoring the value here
}
