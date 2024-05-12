const std = @import("std");
const c = @cImport({
    @cInclude("c_code.h");
});

extern var b: bool;
extern var foo: c.MyStruct;

pub fn main() !void {
    // None of these work.
    c.b = c.true;
    c.foo = c.constant_struct;
    b = c.true;
    foo = c.constant_struct;
}
