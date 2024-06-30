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

    var port = try std.fs.cwd().openFile(port_name, .{ .mode = .read_write });
    defer port.close();
    std.log.info("Connected to device", .{});

    // copied from PuTTY default values, but im not sure if those are getting used, the GUI is not intuitive
    try serial.configureSerialPort(port, .{
        .baud_rate = 9600,
        .word_size = .eight,
        .stop_bits = .one,
        .parity = .none,
        .handshake = .software,
    });

    std.log.info("Reading", .{});
    const reader = port.reader();

    const b = try reader.readByte();
    std.log.info("Read {}", .{b});
}
