const std = @import("std");
const serial = @import("serial");

fn find_port(iterator: *serial.PortIterator) ![]const u8 {
    // TODO: great detection... i know
    while (try iterator.next()) |port| {
        if (std.mem.eql(u8, port.driver.?, "\\Device\\USBSER000")) {
            return port.file_name;
        }
    }

    return error.NoPortFound;
}

pub fn main() !void {
    var iterator = try serial.list();
    defer iterator.deinit();

    const port_name = try find_port(&iterator);
    std.log.info("Found serial device ({s})", .{port_name});

    var port = try std.fs.openFileAbsolute(port_name, .{ .mode = .read_write });
    defer port.close();
    std.log.info("Connected to device", .{});

    // copied from PuTTY default values, but im not sure if those are getting used, the GUI is not intuitive
    try serial.configureSerialPort(port, .{
        .baud_rate = 9600,
        .word_size = .eight,
        .stop_bits = .one,
        .parity = .none,
        .handshake = .none,
    });

    var GPA: std.heap.GeneralPurposeAllocator(.{}) = .{};
    const gpa = GPA.allocator();

    const u8List = std.ArrayList(u8);
    var list = u8List.init(gpa);
    defer list.deinit();

    while (true) {
        const b = try port.reader().readByte();

        if (b == '\n') {
            std.log.info("{s}", .{list.items});
            list.deinit();
            list = u8List.init(gpa);
        } else {
            try list.append(b);
        }
    }
}
