const std = @import("std");
const binding = @import("binding.zig");

comptime {
    std.testing.refAllDecls(@This());
}

const types = @import("types.zig");
pub usingnamespace types;

pub const ErrorHandling = enum {
    /// OpenGL functions will log the error, but will not assert that no error happened
    log,

    /// Asserts that no errors will happen.
    assert,

    /// No error checking will be executed. Gotta go fast!
    none,
};

const error_handling: ErrorHandling =
    std.meta.globalOption("opengl_error_handling", ErrorHandling) orelse
    if (std.debug.runtime_safety) .assert else .none;

/// Checks if a OpenGL error happend and may yield it.
/// This function is configurable via `opengl_error_handling` in the root file.
/// In Debug mode, unexpected error codes will be unreachable, in all release modes
/// they will be safely wrapped to `error.UnexpectedError`.
fn checkError() void {
    if (error_handling == .none)
        return;

    var error_code = binding.getError();
    if (error_code == binding.NO_ERROR)
        return;
    while (error_code != binding.NO_ERROR) : (error_code = binding.getError()) {
        const name = switch (error_code) {
            binding.INVALID_ENUM => "invalid enum",
            binding.INVALID_VALUE => "invalid value",
            binding.INVALID_OPERATION => "invalid operation",
            binding.STACK_OVERFLOW => "stack overflow",
            binding.STACK_UNDERFLOW => "stack underflow",
            binding.OUT_OF_MEMORY => "out of memory",
            binding.INVALID_FRAMEBUFFER_OPERATION => "invalid framebuffer operation",
            // binding.INVALID_FRAMEBUFFER_OPERATION_EXT => Error.InvalidFramebufferOperation,
            // binding.INVALID_FRAMEBUFFER_OPERATION_OES => Error.InvalidFramebufferOperation,
            //binding.TABLE_TOO_LARGE => "Table too large",
            // binding.TABLE_TOO_LARGE_EXT => Error.TableTooLarge,
            //binding.TEXTURE_TOO_LARGE_EXT => "Texture too large",
            else => "unknown error",
        };

        std.log.scoped(.OpenGL).err("OpenGL failure: {s}\n", .{name});
        switch (error_handling) {
            .log => {},
            .assert => @panic("OpenGL error"),
            .none => unreachable,
        }
    }
}

/// Integer conversion helper.
fn cs2gl(size: usize) types.SizeI {
    return @intCast(types.SizeI, size);
}

fn ui2gl(val: usize) types.UInt {
    return @intCast(types.UInt, val);
}

fn b2gl(b: bool) types.Boolean {
    return if (b)
        binding.TRUE
    else
        binding.FALSE;
}

pub const DebugSource = enum {
    api,
    window_system,
    shader_compiler,
    third_party,
    application,
    other,
};

pub const DebugMessageType = enum {
    @"error",
    deprecated_behavior,
    undefined_behavior,
    portability,
    performance,
    other,
};

pub const DebugSeverity = enum {
    high,
    medium,
    low,
    notification,
};

fn DebugMessageCallbackHandler(comptime Context: type) type {
    return if (Context == void)
        fn (source: DebugSource, msg_type: DebugMessageType, id: usize, severity: DebugSeverity, message: []const u8) void
    else
        fn (context: Context, source: DebugSource, msg_type: DebugMessageType, id: usize, severity: DebugSeverity, message: []const u8) void;
}

/// Sets the OpenGL debug callback handler in zig style.
/// `context` may be a pointer or `{}`.
pub fn debugMessageCallback(context: anytype, comptime handler: DebugMessageCallbackHandler(@TypeOf(context))) void {
    const is_void = (@TypeOf(context) == void);
    const Context = @TypeOf(context);

    const H = struct {
        fn translateSource(source: types.UInt) DebugSource {
            return switch (source) {
                binding.DEBUG_SOURCE_API => DebugSource.api,
                // binding.DEBUG_SOURCE_API_ARB => DebugSource.api,
                // binding.DEBUG_SOURCE_API_KHR => DebugSource.api,
                binding.DEBUG_SOURCE_WINDOW_SYSTEM => DebugSource.window_system,
                // binding.DEBUG_SOURCE_WINDOW_SYSTEM_ARB => DebugSource.window_system,
                // binding.DEBUG_SOURCE_WINDOW_SYSTEM_KHR => DebugSource.window_system,
                binding.DEBUG_SOURCE_SHADER_COMPILER => DebugSource.shader_compiler,
                // binding.DEBUG_SOURCE_SHADER_COMPILER_ARB => DebugSource.shader_compiler,
                // binding.DEBUG_SOURCE_SHADER_COMPILER_KHR => DebugSource.shader_compiler,
                binding.DEBUG_SOURCE_THIRD_PARTY => DebugSource.third_party,
                // binding.DEBUG_SOURCE_THIRD_PARTY_ARB => DebugSource.third_party,
                // binding.DEBUG_SOURCE_THIRD_PARTY_KHR => DebugSource.third_party,
                binding.DEBUG_SOURCE_APPLICATION => DebugSource.application,
                // binding.DEBUG_SOURCE_APPLICATION_ARB => DebugSource.application,
                // binding.DEBUG_SOURCE_APPLICATION_KHR => DebugSource.application,
                binding.DEBUG_SOURCE_OTHER => DebugSource.other,
                // binding.DEBUG_SOURCE_OTHER_ARB => DebugSource.other,
                // binding.DEBUG_SOURCE_OTHER_KHR => DebugSource.other,
                else => DebugSource.other,
            };
        }

        fn translateMessageType(msg_type: types.UInt) DebugMessageType {
            return switch (msg_type) {
                binding.DEBUG_TYPE_ERROR => DebugMessageType.@"error",
                // binding.DEBUG_TYPE_ERROR_ARB => DebugMessageType.@"error",
                // binding.DEBUG_TYPE_ERROR_KHR => DebugMessageType.@"error",
                binding.DEBUG_TYPE_DEPRECATED_BEHAVIOR => DebugMessageType.deprecated_behavior,
                // binding.DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB => DebugMessageType.deprecated_behavior,
                // binding.DEBUG_TYPE_DEPRECATED_BEHAVIOR_KHR => DebugMessageType.deprecated_behavior,
                binding.DEBUG_TYPE_UNDEFINED_BEHAVIOR => DebugMessageType.undefined_behavior,
                // binding.DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB => DebugMessageType.undefined_behavior,
                // binding.DEBUG_TYPE_UNDEFINED_BEHAVIOR_KHR => DebugMessageType.undefined_behavior,
                binding.DEBUG_TYPE_PORTABILITY => DebugMessageType.portability,
                // binding.DEBUG_TYPE_PORTABILITY_ARB => DebugMessageType.portability,
                // binding.DEBUG_TYPE_PORTABILITY_KHR => DebugMessageType.portability,
                binding.DEBUG_TYPE_PERFORMANCE => DebugMessageType.performance,
                // binding.DEBUG_TYPE_PERFORMANCE_ARB => DebugMessageType.performance,
                // binding.DEBUG_TYPE_PERFORMANCE_KHR => DebugMessageType.performance,
                binding.DEBUG_TYPE_OTHER => DebugMessageType.other,
                // binding.DEBUG_TYPE_OTHER_ARB => DebugMessageType.other,
                // binding.DEBUG_TYPE_OTHER_KHR => DebugMessageType.other,
                else => DebugMessageType.other,
            };
        }

        fn translateSeverity(sev: types.UInt) DebugSeverity {
            return switch (sev) {
                binding.DEBUG_SEVERITY_HIGH => DebugSeverity.high,
                // binding.DEBUG_SEVERITY_HIGH_AMD => DebugSeverity.high,
                // binding.DEBUG_SEVERITY_HIGH_ARB => DebugSeverity.high,
                // binding.DEBUG_SEVERITY_HIGH_KHR => DebugSeverity.high,
                binding.DEBUG_SEVERITY_MEDIUM => DebugSeverity.medium,
                // binding.DEBUG_SEVERITY_MEDIUM_AMD => DebugSeverity.medium,
                // binding.DEBUG_SEVERITY_MEDIUM_ARB => DebugSeverity.medium,
                // binding.DEBUG_SEVERITY_MEDIUM_KHR => DebugSeverity.medium,
                binding.DEBUG_SEVERITY_LOW => DebugSeverity.low,
                // binding.DEBUG_SEVERITY_LOW_AMD => DebugSeverity.low,
                // binding.DEBUG_SEVERITY_LOW_ARB => DebugSeverity.low,
                // binding.DEBUG_SEVERITY_LOW_KHR => DebugSeverity.low,
                binding.DEBUG_SEVERITY_NOTIFICATION => DebugSeverity.notification,
                // binding.DEBUG_SEVERITY_NOTIFICATION_KHR => DebugSeverity.notification,
                else => DebugSeverity.high,
            };
        }

        fn callback(
            c_source: types.Enum,
            c_msg_type: types.Enum,
            id: types.UInt,
            c_severity: types.Enum,
            length: types.SizeI,
            c_message: [*c]const types.Char,
            userParam: ?*const anyopaque,
        ) callconv(.C) void {
            const debug_source = translateSource(c_source);
            const msg_type = translateMessageType(c_msg_type);
            const severity = translateSeverity(c_severity);

            const message = c_message[0..@intCast(usize, length)];

            if (is_void) {
                handler(debug_source, msg_type, id, severity, message);
            } else {
                handler(@intToPtr(Context, @ptrToInt(userParam)), debug_source, msg_type, id, severity, message);
            }
        }
    };

    if (is_void)
        binding.debugMessageCallback(H.callback, null)
    else
        binding.debugMessageCallback(H.callback, @ptrCast(?*const anyopaque, context));
    checkError();
}

pub fn clearColor(r: f32, g: f32, b: f32, a: f32) void {
    binding.clearColor(r, g, b, a);
    checkError();
}

pub fn clearDepth(depth: f32) void {
    binding.clearDepth(depth);
    checkError();
}

pub fn clear(mask: struct { color: bool = false, depth: bool = false, stencil: bool = false }) void {
    binding.clear(@as(types.BitField, if (mask.color) binding.COLOR_BUFFER_BIT else 0) |
        @as(types.BitField, if (mask.depth) binding.DEPTH_BUFFER_BIT else 0) |
        @as(types.BitField, if (mask.stencil) binding.STENCIL_BUFFER_BIT else 0));
    checkError();
}

pub fn flush() void {
    binding.flush();
    checkError();
}

pub fn colorMask(r: bool, g: bool, b: bool, a: bool) void {
    binding.colorMask(b2gl(r), b2gl(g), b2gl(b), b2gl(a));
}

pub const ColorBuffer = enum(types.Enum) {
    none = binding.NONE,
    front = binding.FRONT,
    back = binding.BACK,
    left = binding.LEFT,
    right = binding.RIGHT,
    front_left = binding.FRONT_LEFT,
    front_right = binding.FRONT_RIGHT,
    back_left = binding.BACK_LEFT,
    back_right = binding.BACK_RIGHT,
    color0 = binding.COLOR_ATTACHMENT0,
    color1 = binding.COLOR_ATTACHMENT1,
    color2 = binding.COLOR_ATTACHMENT2,
    color3 = binding.COLOR_ATTACHMENT3,
    color4 = binding.COLOR_ATTACHMENT4,
    color5 = binding.COLOR_ATTACHMENT5,
    color6 = binding.COLOR_ATTACHMENT6,
    color7 = binding.COLOR_ATTACHMENT7,
    color8 = binding.COLOR_ATTACHMENT8,
    color9 = binding.COLOR_ATTACHMENT9,
};

pub fn drawBuffer(buf: ColorBuffer) void {
    binding.drawBuffer(@enumToInt(buf));
}

pub fn readBuffer(buf: ColorBuffer) void {
    binding.readBuffer(@enumToInt(buf));
}

pub fn readPixels(
    x: usize,
    y: usize,
    width: usize,
    height: usize,
    format: PixelFormat,
    pixel_type: PixelType,
    data: *anyopaque,
) void {
    binding.readPixels(
        @intCast(types.Int, x),
        @intCast(types.Int, y),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
        @enumToInt(format),
        @enumToInt(pixel_type),
        data,
    );
}

///////////////////////////////////////////////////////////////////////////////
// Vertex Arrays

pub fn createVertexArrays(items: []types.VertexArray) void {
    binding.createVertexArrays(cs2gl(items.len), @ptrCast([*]types.UInt, items.ptr));
    checkError();
}

pub fn createVertexArray() types.VertexArray {
    var vao: types.VertexArray = undefined;
    createVertexArrays(@ptrCast([*]types.VertexArray, &vao)[0..1]);
    return vao;
}

pub fn genVertexArrays(items: []types.VertexArray) void {
    binding.genVertexArrays(cs2gl(items.len), @ptrCast([*]types.UInt, items.ptr));
    checkError();
}

pub fn genVertexArray() types.VertexArray {
    var vao: types.VertexArray = undefined;
    genVertexArrays(@ptrCast([*]types.VertexArray, &vao)[0..1]);
    return vao;
}

pub fn bindVertexArray(vao: types.VertexArray) void {
    binding.bindVertexArray(@enumToInt(vao));
    checkError();
}

pub fn deleteVertexArrays(items: []const types.VertexArray) void {
    binding.deleteVertexArrays(cs2gl(items.len), @ptrCast([*]const types.UInt, items.ptr));
}

pub fn deleteVertexArray(vao: types.VertexArray) void {
    deleteVertexArrays(@ptrCast([*]const types.VertexArray, &vao)[0..1]);
}

pub fn enableVertexAttribArray(index: u32) void {
    binding.enableVertexAttribArray(index);
    checkError();
}

pub fn vertexAttribDivisor(index: u32, divisor: u32) void {
    binding.vertexAttribDivisor(index, divisor);
    checkError();
}

pub fn disableVertexAttribArray(index: u32) void {
    binding.disableVertexAttribArray(index);
    checkError();
}

pub fn enableVertexArrayAttrib(vertexArray: types.VertexArray, index: u32) void {
    binding.enableVertexArrayAttrib(@enumToInt(vertexArray), index);
    checkError();
}

pub fn disableVertexArrayAttrib(vertexArray: types.VertexArray, index: u32) void {
    binding.disableVertexArrayAttrib(@enumToInt(vertexArray), index);
    checkError();
}

pub const Type = enum(types.Enum) {
    byte = binding.BYTE,
    short = binding.SHORT,
    int = binding.INT,
    fixed = binding.FIXED,
    float = binding.FLOAT,
    half_float = binding.HALF_FLOAT,
    double = binding.DOUBLE,
    unsigned_byte = binding.UNSIGNED_BYTE,
    unsigned_short = binding.UNSIGNED_SHORT,
    unsigned_int = binding.UNSIGNED_INT,
    int_2_10_10_10_rev = binding.INT_2_10_10_10_REV,
    unsigned_int_2_10_10_10_rev = binding.UNSIGNED_INT_2_10_10_10_REV,
    unsigned_int_10_f_11_f_11_f_rev = binding.UNSIGNED_INT_10F_11F_11F_REV,
};

pub fn vertexAttribFormat(attribindex: u32, size: u32, attribute_type: Type, normalized: bool, relativeoffset: usize) void {
    binding.vertexAttribFormat(
        attribindex,
        @intCast(types.Int, size),
        @enumToInt(attribute_type),
        b2gl(normalized),
        ui2gl(relativeoffset),
    );
    checkError();
}

pub fn vertexAttribIFormat(attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) void {
    binding.vertexAttribIFormat(
        attribindex,
        @intCast(types.Int, size),
        @enumToInt(attribute_type),
        ui2gl(relativeoffset),
    );
    checkError();
}

pub fn vertexAttribLFormat(attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) void {
    binding.vertexAttribLFormat(
        attribindex,
        @intCast(types.Int, size),
        @enumToInt(attribute_type),
        ui2gl(relativeoffset),
    );
    checkError();
}

/// NOTE: if you use any integer type, it will cast to a floating point, you are probably looking for vertexAttribIPointer()
pub fn vertexAttribPointer(attribindex: u32, size: u32, attribute_type: Type, normalized: bool, stride: usize, relativeoffset: usize) void {
    binding.vertexAttribPointer(
        attribindex,
        @intCast(types.Int, size),
        @enumToInt(attribute_type),
        b2gl(normalized),
        cs2gl(stride),
        @intToPtr(*allowzero const anyopaque, relativeoffset),
    );
    checkError();
}

pub fn vertexAttribIPointer(attribindex: u32, size: u32, attribute_type: Type, stride: usize, relativeoffset: usize) void {
    binding.vertexAttribIPointer(
        attribindex,
        @intCast(types.Int, size),
        @enumToInt(attribute_type),
        cs2gl(stride),
        @intToPtr(*allowzero const anyopaque, relativeoffset),
    );
    checkError();
}

pub fn vertexArrayAttribFormat(
    vertexArray: types.VertexArray,
    attribindex: u32,
    size: u32,
    attribute_type: Type,
    normalized: bool,
    relativeoffset: usize,
) void {
    binding.vertexArrayAttribFormat(
        @enumToInt(vertexArray),
        attribindex,
        @intCast(types.Int, size),
        @enumToInt(attribute_type),
        b2gl(normalized),
        ui2gl(relativeoffset),
    );
    checkError();
}

pub fn vertexArrayAttribIFormat(vertexArray: types.VertexArray, attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) void {
    binding.vertexArrayAttribIFormat(
        @enumToInt(vertexArray),
        attribindex,
        @intCast(
            types.Int,
            size,
        ),
        @enumToInt(attribute_type),
        ui2gl(relativeoffset),
    );
    checkError();
}

pub fn vertexArrayAttribLFormat(vertexArray: types.VertexArray, attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) void {
    binding.vertexArrayAttribLFormat(
        @enumToInt(vertexArray),
        attribindex,
        @intCast(
            types.Int,
            size,
        ),
        @enumToInt(attribute_type),
        @intCast(types.UInt, relativeoffset),
    );
    checkError();
}

pub fn vertexAttribBinding(attribindex: u32, bindingindex: u32) void {
    binding.vertexAttribBinding(
        attribindex,
        bindingindex,
    );
    checkError();
}
pub fn vertexArrayAttribBinding(vertexArray: types.VertexArray, attribindex: u32, bindingindex: u32) void {
    binding.vertexArrayAttribBinding(
        @enumToInt(vertexArray),
        attribindex,
        bindingindex,
    );
    checkError();
}

pub fn bindVertexBuffer(bindingindex: u32, buffer: types.Buffer, offset: usize, stride: usize) void {
    binding.bindVertexBuffer(bindingindex, @enumToInt(buffer), offset, cs2gl(stride));
    checkError();
}

pub fn vertexArrayVertexBuffer(vertexArray: types.VertexArray, bindingindex: u32, buffer: types.Buffer, offset: usize, stride: usize) void {
    binding.vertexArrayVertexBuffer(@enumToInt(vertexArray), bindingindex, @enumToInt(buffer), offset, cs2gl(stride));
    checkError();
}

pub fn vertexArrayElementBuffer(vertexArray: types.VertexArray, buffer: types.Buffer) void {
    binding.vertexArrayElementBuffer(@enumToInt(vertexArray), @enumToInt(buffer));
    checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Buffer

pub const BufferTarget = enum(types.Enum) {
    /// Vertex attributes
    array_buffer = binding.ARRAY_BUFFER,
    /// Atomic counter storage
    atomic_counter_buffer = binding.ATOMIC_COUNTER_BUFFER,
    /// Buffer copy source
    copy_read_buffer = binding.COPY_READ_BUFFER,
    /// Buffer copy destination
    copy_write_buffer = binding.COPY_WRITE_BUFFER,
    /// Indirect compute dispatch commands
    dispatch_indirect_buffer = binding.DISPATCH_INDIRECT_BUFFER,
    /// Indirect command arguments
    draw_indirect_buffer = binding.DRAW_INDIRECT_BUFFER,
    /// Vertex array indices
    element_array_buffer = binding.ELEMENT_ARRAY_BUFFER,
    /// Pixel read target
    pixel_pack_buffer = binding.PIXEL_PACK_BUFFER,
    /// Texture data source
    pixel_unpack_buffer = binding.PIXEL_UNPACK_BUFFER,
    /// Query result buffer
    query_buffer = binding.QUERY_BUFFER,
    /// Read-write storage for shaders
    shader_storage_buffer = binding.SHADER_STORAGE_BUFFER,
    /// Texture data buffer
    texture_buffer = binding.TEXTURE_BUFFER,
    /// Transform feedback buffer
    transform_feedback_buffer = binding.TRANSFORM_FEEDBACK_BUFFER,
    /// Uniform block storage
    uniform_buffer = binding.UNIFORM_BUFFER,
};

pub fn createBuffers(items: []types.Buffer) void {
    binding.createBuffers(cs2gl(items.len), @ptrCast([*]types.UInt, items.ptr));
    checkError();
}

pub fn createBuffer() types.Buffer {
    var buf: types.Buffer = undefined;
    createBuffers(@ptrCast([*]types.Buffer, &buf)[0..1]);
    return buf;
}

pub fn genBuffers(items: []types.Buffer) void {
    binding.genBuffers(cs2gl(items.len), @ptrCast([*]types.UInt, items.ptr));
    checkError();
}

pub fn genBuffer() types.Buffer {
    var buf: types.Buffer = undefined;
    genBuffers(@ptrCast([*]types.Buffer, &buf)[0..1]);
    return buf;
}

pub fn bindBuffer(buf: types.Buffer, target: BufferTarget) void {
    binding.bindBuffer(@enumToInt(target), @enumToInt(buf));
    checkError();
}

pub fn deleteBuffers(items: []const types.Buffer) void {
    binding.deleteBuffers(cs2gl(items.len), @ptrCast([*]const types.UInt, items.ptr));
}

pub fn deleteBuffer(buf: types.Buffer) void {
    deleteBuffers(@ptrCast([*]const types.Buffer, &buf)[0..1]);
}

pub const BufferUsage = enum(types.Enum) {
    stream_draw = binding.STREAM_DRAW,
    stream_read = binding.STREAM_READ,
    stream_copy = binding.STREAM_COPY,
    static_draw = binding.STATIC_DRAW,
    static_read = binding.STATIC_READ,
    static_copy = binding.STATIC_COPY,
    dynamic_draw = binding.DYNAMIC_DRAW,
    dynamic_read = binding.DYNAMIC_READ,
    dynamic_copy = binding.DYNAMIC_COPY,
};

// using align(1) as we are not required to have aligned data here
pub fn namedBufferData(buf: types.Buffer, comptime T: type, items: []align(1) const T, usage: BufferUsage) void {
    binding.namedBufferData(
        @enumToInt(buf),
        cs2gl(@sizeOf(T) * items.len),
        items.ptr,
        @enumToInt(usage),
    );
    checkError();
}

pub fn namedBufferUninitialized(buf: types.Buffer, comptime T: type, count: usize, usage: BufferUsage) void {
    binding.namedBufferData(
        @enumToInt(buf),
        cs2gl(@sizeOf(T) * count),
        null,
        @enumToInt(usage),
    );
    checkError();
}

pub fn bufferData(target: BufferTarget, comptime T: type, items: []align(1) const T, usage: BufferUsage) void {
    binding.bufferData(
        @enumToInt(target),
        cs2gl(@sizeOf(T) * items.len),
        items.ptr,
        @enumToInt(usage),
    );
    checkError();
}

pub fn bufferUninitialized(target: BufferTarget, comptime T: type, count: usize, usage: BufferUsage) void {
    binding.bufferData(
        @enumToInt(target),
        cs2gl(@sizeOf(T) * count),
        null,
        @enumToInt(usage),
    );
    checkError();
}

pub fn bufferSubData(target: BufferTarget, offset: usize, comptime T: type, items: []align(1) const T) void {
    binding.bufferSubData(
        @enumToInt(target), 
        @intCast(binding.GLintptr, offset), 
        cs2gl(@sizeOf(T) * items.len), items.ptr
    );
    checkError();
}

pub fn bindBufferBase(target: BufferTarget, index: u32, buffer: types.Buffer) void {
    binding.bindBufferBase(@enumToInt(target), index, @enumToInt(buffer));
    checkError();
}

pub fn bindBufferRange(target: BufferTarget, index: u32, buffer: types.Buffer, offset: u32, size: u32) void {
    binding.bindBufferRange(@enumToInt(target), index, @enumToInt(buffer), offset, size);
    checkError();
}

pub const BufferStorageFlags = packed struct {
    dynamic_storage: bool = false,
    map_read: bool = false,
    map_write: bool = false,
    map_persistent: bool = false,
    map_coherent: bool = false,
    client_storage: bool = false,
};

pub fn bufferStorage(target: BufferTarget, comptime T: type, count: usize, items: ?[*]align(1) const T, flags: BufferStorageFlags) void {
    var flag_bits: binding.GLbitfield = 0;
    if (flags.dynamic_storage) flag_bits |= binding.DYNAMIC_STORAGE_BIT;
    if (flags.map_read) flag_bits |= binding.MAP_READ_BIT;
    if (flags.map_write) flag_bits |= binding.MAP_WRITE_BIT;
    if (flags.map_persistent) flag_bits |= binding.MAP_PERSISTENT_BIT;
    if (flags.map_coherent) flag_bits |= binding.MAP_COHERENT_BIT;
    if (flags.client_storage) flag_bits |= binding.CLIENT_STORAGE_BIT;

    binding.bufferStorage(
        @enumToInt(target),
        cs2gl(@sizeOf(T) * count),
        items,
        flag_bits,
    );
    checkError();
}

pub fn namedBufferStorage(buf: types.Buffer, comptime T: type, count: usize, items: ?[*]align(1) const T, flags: BufferStorageFlags) void {
    var flag_bits: binding.GLbitfield = 0;
    if (flags.dynamic_storage) flag_bits |= binding.DYNAMIC_STORAGE_BIT;
    if (flags.map_read) flag_bits |= binding.MAP_READ_BIT;
    if (flags.map_write) flag_bits |= binding.MAP_WRITE_BIT;
    if (flags.map_persistent) flag_bits |= binding.MAP_PERSISTENT_BIT;
    if (flags.map_coherent) flag_bits |= binding.MAP_COHERENT_BIT;
    if (flags.client_storage) flag_bits |= binding.CLIENT_STORAGE_BIT;

    binding.namedBufferStorage(
        @enumToInt(buf),
        cs2gl(@sizeOf(T) * count),
        items,
        flag_bits,
    );
    checkError();
}

pub const BufferMapTarget = enum(types.Enum) {
    array_buffer = binding.ARRAY_BUFFER,
    atomic_counter_buffer = binding.ATOMIC_COUNTER_BUFFER,
    copy_read_buffer = binding.COPY_READ_BUFFER,
    copy_write_buffer = binding.COPY_WRITE_BUFFER,
    dispatch_indirect_buffer = binding.DISPATCH_INDIRECT_BUFFER,
    draw_indirect_buffer = binding.DRAW_INDIRECT_BUFFER,
    element_array_buffer = binding.ELEMENT_ARRAY_BUFFER,
    pixel_pack_buffer = binding.PIXEL_PACK_BUFFER,
    pixel_unpack_buffer = binding.PIXEL_UNPACK_BUFFER,
    query_buffer = binding.QUERY_BUFFER,
    shader_storage_buffer = binding.SHADER_STORAGE_BUFFER,
    texture_buffer = binding.TEXTURE_BUFFER,
    transform_feedback_buffer = binding.TRANSFORM_FEEDBACK_BUFFER,
    uniform_buffer = binding.UNIFORM_BUFFER,
};

pub const BufferMapAccess = enum(types.Enum) {
    read_only = binding.READ_ONLY,
    write_only = binding.WRITE_ONLY,
    read_write = binding.READ_WRITE,
};

pub fn mapBuffer(
    target: BufferMapTarget,
    comptime T: type,
    access: BufferMapAccess,
) [*]align(1) T {
    const ptr = binding.mapBuffer(
        @enumToInt(target),
        @enumToInt(access),
    );

    checkError();
    return @ptrCast([*]align(1) T, ptr);
}

pub fn unmapBuffer(target: BufferMapTarget) bool {
    const ok = binding.unmapBuffer(@enumToInt(target));
    checkError();
    return ok == binding.TRUE;
}

pub const BufferMapFlags = packed struct {
    read: bool = false,
    write: bool = false,
    persistent: bool = false,
    coherent: bool = false,
};

pub fn mapBufferRange(
    target: BufferTarget,
    comptime T: type,
    offset: usize,
    count: usize,
    flags: BufferMapFlags,
) []align(1) T {
    var flag_bits: binding.GLbitfield = 0;
    if (flags.read) flag_bits |= binding.MAP_READ_BIT;
    if (flags.write) flag_bits |= binding.MAP_WRITE_BIT;
    if (flags.persistent) flag_bits |= binding.MAP_PERSISTENT_BIT;
    if (flags.coherent) flag_bits |= binding.MAP_COHERENT_BIT;

    const ptr = binding.mapBufferRange(
        @enumToInt(target),
        @intCast(binding.GLintptr, offset),
        @intCast(binding.GLsizeiptr, @sizeOf(T) * count),
        flag_bits,
    );
    checkError();

    const values = @ptrCast([*]align(1) T, ptr);
    return values[0..count];
}

pub fn mapNamedBufferRange(
    buf: types.Buffer,
    comptime T: type,
    offset: usize,
    count: usize,
    flags: BufferMapFlags,
) []align(1) T {
    var flag_bits: binding.GLbitfield = 0;
    if (flags.read) flag_bits |= binding.MAP_READ_BIT;
    if (flags.write) flag_bits |= binding.MAP_WRITE_BIT;
    if (flags.persistent) flag_bits |= binding.MAP_PERSISTENT_BIT;
    if (flags.coherent) flag_bits |= binding.MAP_COHERENT_BIT;

    const ptr = binding.mapNamedBufferRange(
        @enumToInt(buf),
        @intCast(binding.GLintptr, offset),
        @intCast(binding.GLsizeiptr, @sizeOf(T) * count),
        flag_bits,
    );
    checkError();

    const values = @ptrCast([*]align(1) T, ptr);
    return values[0..count];
}

pub fn unmapNamedBuffer(buf: types.Buffer) bool {
    const ok = binding.unmapNamedBuffer(@enumToInt(buf));
    checkError();
    return ok != 0;
}

pub fn copyBufferSubData(
    read_target: BufferTarget,
    write_target: BufferTarget,
    comptime T: type,
    read_offset: usize,
    write_offset: usize,
    count: usize,
) void {
    binding.copyBufferSubData(
        @enumToInt(read_target),
        @enumToInt(write_target),
        @intCast(binding.GLintptr, read_offset),
        @intCast(binding.GLintptr, write_offset),
        @intCast(binding.GLsizeiptr, @sizeOf(T) * count),
    );
    checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Shaders

pub const ShaderType = enum(types.Enum) {
    compute = binding.COMPUTE_SHADER,
    vertex = binding.VERTEX_SHADER,
    tess_control = binding.TESS_CONTROL_SHADER,
    tess_evaluation = binding.TESS_EVALUATION_SHADER,
    geometry = binding.GEOMETRY_SHADER,
    fragment = binding.FRAGMENT_SHADER,
};

pub fn createShader(shaderType: ShaderType) types.Shader {
    const shader = @intToEnum(types.Shader, binding.createShader(@enumToInt(shaderType)));
    if (shader == .invalid) {
        checkError();
        unreachable;
    }
    return shader;
}

pub fn deleteShader(shader: types.Shader) void {
    binding.deleteShader(@enumToInt(shader));
    checkError();
}

pub fn compileShader(shader: types.Shader) void {
    binding.compileShader(@enumToInt(shader));
    checkError();
}

pub fn shaderSource(shader: types.Shader, comptime N: comptime_int, sources: *const [N][]const u8) void {
    var lengths: [N]types.Int = undefined;
    for (&lengths, sources) |*len, src| {
        len.* = @intCast(types.Int, src.len);
    }

    var ptrs: [N]*const types.Char = undefined;
    for (&ptrs, sources) |*ptr, src| {
        ptr.* = @ptrCast(*const types.Char, src.ptr);
    }

    binding.shaderSource(@enumToInt(shader), N, &ptrs, &lengths);

    checkError();
}

pub const ShaderParameter = enum(types.Enum) {
    shader_type = binding.SHADER_TYPE,
    delete_status = binding.DELETE_STATUS,
    compile_status = binding.COMPILE_STATUS,
    info_log_length = binding.INFO_LOG_LENGTH,
    shader_source_length = binding.SHADER_SOURCE_LENGTH,
};

pub fn getShader(shader: types.Shader, parameter: ShaderParameter) types.Int {
    var value: types.Int = undefined;
    binding.getShaderiv(@enumToInt(shader), @enumToInt(parameter), &value);
    checkError();
    return value;
}

pub fn getShaderInfoLog(shader: types.Shader, allocator: std.mem.Allocator) ![:0]const u8 {
    const length = getShader(shader, .info_log_length);
    const log = try allocator.allocSentinel(u8, @intCast(usize, length), 0);
    errdefer allocator.free(log);

    binding.getShaderInfoLog(@enumToInt(shader), cs2gl(log.len), null, log.ptr);
    checkError();

    return log;
}

///////////////////////////////////////////////////////////////////////////////
// Program

pub fn createProgram() types.Program {
    const program = @intToEnum(types.Program, binding.createProgram());
    if (program == .invalid) {
        checkError();
        unreachable;
    }
    return program;
}

pub fn deleteProgram(program: types.Program) void {
    binding.deleteProgram(@enumToInt(program));
    checkError();
}

pub fn linkProgram(program: types.Program) void {
    binding.linkProgram(@enumToInt(program));
    checkError();
}

pub fn attachShader(program: types.Program, shader: types.Shader) void {
    binding.attachShader(@enumToInt(program), @enumToInt(shader));
    checkError();
}

pub fn detachShader(program: types.Program, shader: types.Shader) void {
    binding.detachShader(@enumToInt(program), @enumToInt(shader));
    checkError();
}

pub fn useProgram(program: types.Program) void {
    binding.useProgram(@enumToInt(program));
    checkError();
}

pub const ProgramParameter = enum(types.Enum) {
    delete_status = binding.DELETE_STATUS,
    link_status = binding.LINK_STATUS,
    validate_status = binding.VALIDATE_STATUS,
    info_log_length = binding.INFO_LOG_LENGTH,
    attached_shaders = binding.ATTACHED_SHADERS,
    active_atomic_counter_buffers = binding.ACTIVE_ATOMIC_COUNTER_BUFFERS,
    active_attributes = binding.ACTIVE_ATTRIBUTES,
    active_attribute_max_length = binding.ACTIVE_ATTRIBUTE_MAX_LENGTH,
    active_uniforms = binding.ACTIVE_UNIFORMS,
    active_uniform_blocks = binding.ACTIVE_UNIFORM_BLOCKS,
    active_uniform_block_max_name_length = binding.ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH,
    active_uniform_max_length = binding.ACTIVE_UNIFORM_MAX_LENGTH,
    compute_work_group_size = binding.COMPUTE_WORK_GROUP_SIZE,
    program_binary_length = binding.PROGRAM_BINARY_LENGTH,
    transform_feedback_buffer_mode = binding.TRANSFORM_FEEDBACK_BUFFER_MODE,
    transform_feedback_varyings = binding.TRANSFORM_FEEDBACK_VARYINGS,
    transform_feedback_varying_max_length = binding.TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH,
    geometry_vertices_out = binding.GEOMETRY_VERTICES_OUT,
    geometry_input_type = binding.GEOMETRY_INPUT_TYPE,
    geometry_output_type = binding.GEOMETRY_OUTPUT_TYPE,
};

pub fn getProgram(program: types.Program, parameter: ProgramParameter) types.Int {
    var value: types.Int = undefined;
    binding.getProgramiv(@enumToInt(program), @enumToInt(parameter), &value);
    checkError();
    return value;
}

pub fn getProgramInfoLog(program: types.Program, allocator: std.mem.Allocator) ![:0]const u8 {
    const length = getProgram(program, .info_log_length);
    const log = try allocator.allocSentinel(u8, @intCast(usize, length), 0);
    errdefer allocator.free(log);

    binding.getProgramInfoLog(@enumToInt(program), cs2gl(log.len), null, log.ptr);
    checkError();

    return log;
}

pub fn getUniformLocation(program: types.Program, name: [:0]const u8) ?u32 {
    const loc = binding.getUniformLocation(@enumToInt(program), name.ptr);
    checkError();
    if (loc < 0)
        return null;
    return @intCast(u32, loc);
}

pub fn getAttribLocation(program: types.Program, name: [:0]const u8) ?u32 {
    const loc = binding.getAttribLocation(@enumToInt(program), name.ptr);
    checkError();
    if (loc < 0)
        return null;
    return @intCast(u32, loc);
}
pub fn bindAttribLocation(program: types.Program, attribute: u32, name: [:0]const u8) void {
    binding.bindAttribLocation(@enumToInt(program), attribute, name.ptr);
    checkError();
}

pub fn uniformBlockBinding(program: types.Program, index: u32, value: u32) void {
    binding.uniformBlockBinding(@enumToInt(program), index, value);
}

///////////////////////////////////////////////////////////////////////////////
// Uniforms

pub fn programUniform1ui(program: types.Program, location: ?u32, value: u32) void {
    if (location) |loc| {
        binding.programUniform1ui(@enumToInt(program), @intCast(types.Int, loc), value);
        checkError();
    }
}

pub fn programUniform1i(program: types.Program, location: ?u32, value: i32) void {
    if (location) |loc| {
        binding.programUniform1i(@enumToInt(program), @intCast(types.Int, loc), value);
        checkError();
    }
}

pub fn programUniform3ui(program: types.Program, location: ?u32, x: u32, y: u32, z: u32) void {
    if (location) |loc| {
        binding.programUniform3ui(@enumToInt(program), @intCast(types.Int, loc), x, y, z);
        checkError();
    }
}

pub fn programUniform3i(program: types.Program, location: ?u32, x: i32, y: i32, z: i32) void {
    if (location) |loc| {
        binding.programUniform3i(@enumToInt(program), @intCast(types.Int, loc), x, y, z);
        checkError();
    }
}

pub fn programUniform2i(program: types.Program, location: ?u32, v0: i32, v1: i32) void {
    if (location) |loc| {
        binding.programUniform2i(@enumToInt(program), @intCast(types.Int, loc), v0, v1);
        checkError();
    }
}

pub fn programUniform1f(program: types.Program, location: ?u32, value: f32) void {
    if (location) |loc| {
        binding.programUniform1f(@enumToInt(program), @intCast(types.Int, loc), value);
        checkError();
    }
}

pub fn programUniform2f(program: types.Program, location: ?u32, x: f32, y: f32) void {
    if (location) |loc| {
        binding.programUniform2f(@enumToInt(program), @intCast(types.Int, loc), x, y);
        checkError();
    }
}

pub fn programUniform3f(program: types.Program, location: ?u32, x: f32, y: f32, z: f32) void {
    if (location) |loc| {
        binding.programUniform3f(@enumToInt(program), @intCast(types.Int, loc), x, y, z);
        checkError();
    }
}

pub fn programUniform4f(program: types.Program, location: ?u32, x: f32, y: f32, z: f32, w: f32) void {
    if (location) |loc| {
        binding.programUniform4f(@enumToInt(program), @intCast(types.Int, loc), x, y, z, w);
        checkError();
    }
}

pub fn programUniformMatrix4(program: types.Program, location: ?u32, transpose: bool, items: []const [4][4]f32) void {
    if (location) |loc| {
        binding.programUniformMatrix4fv(
            @enumToInt(program),
            @intCast(types.Int, loc),
            cs2gl(items.len),
            b2gl(transpose),

            @ptrCast(*const f32, items.ptr),
        );
        checkError();
    }
}

pub fn uniform1f(location: ?u32, v0: f32) void {
    if (location) |loc| {
        binding.uniform1f(@intCast(types.Int, loc), v0);
        checkError();
    }
}

pub fn uniform2f(location: ?u32, v0: f32, v1: f32) void {
    if (location) |loc| {
        binding.uniform2f(@intCast(types.Int, loc), v0, v1);
        checkError();
    }
}

pub fn uniform3f(location: ?u32, v0: f32, v1: f32, v2: f32) void {
    if (location) |loc| {
        binding.uniform3f(@intCast(types.Int, loc), v0, v1, v2);
        checkError();
    }
}

pub fn uniform4f(location: ?u32, v0: f32, v1: f32, v2: f32, v3: f32) void {
    if (location) |loc| {
        binding.uniform4f(@intCast(types.Int, loc), v0, v1, v2, v3);
        checkError();
    }
}

pub fn uniform1i(location: ?u32, v0: i32) void {
    if (location) |loc| {
        binding.uniform1i(@intCast(types.Int, loc), v0);
        checkError();
    }
}

pub fn uniform2i(location: ?u32, v0: i32, v1: i32) void {
    if (location) |loc| {
        binding.uniform2i(@intCast(types.Int, loc), v0, v1);
        checkError();
    }
}

pub fn uniform3i(location: ?u32, v0: i32, v1: i32, v2: i32) void {
    if (location) |loc| {
        binding.uniform3i(@intCast(types.Int, loc), v0, v1, v2);
        checkError();
    }
}

pub fn uniform4i(location: ?u32, v0: i32, v1: i32, v2: i32, v3: i32) void {
    if (location) |loc| {
        binding.uniform4i(@intCast(types.Int, loc), v0, v1, v2, v3);
        checkError();
    }
}

pub fn uniform1ui(location: ?u32, v0: u32) void {
    if (location) |loc| {
        binding.uniform1ui(@intCast(types.Int, loc), v0);
        checkError();
    }
}

pub fn uniform2ui(location: ?u32, v0: u32, v1: u32) void {
    if (location) |loc| {
        binding.uniform2ui(@intCast(types.Int, loc), v0, v1);
        checkError();
    }
}

pub fn uniform3ui(location: ?u32, v0: u32, v1: u32, v2: u32) void {
    if (location) |loc| {
        binding.uniform3ui(@intCast(types.Int, loc), v0, v1, v2);
        checkError();
    }
}

pub fn uniform4ui(location: ?u32, v0: u32, v1: u32, v2: u32, v3: u32) void {
    if (location) |loc| {
        binding.uniform4ui(@intCast(types.Int, loc), v0, v1, v2, v3);
        checkError();
    }
}

pub fn uniform1fv(location: ?u32, items: []const f32) void {
    if (location) |loc| {
        binding.uniform1fv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const f32, items.ptr));
        checkError();
    }
}

pub fn uniform2fv(location: ?u32, items: []const [2]f32) void {
    if (location) |loc| {
        binding.uniform2fv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const f32, items.ptr));
        checkError();
    }
}

pub fn uniform3fv(location: ?u32, items: []const [3]f32) void {
    if (location) |loc| {
        binding.uniform3fv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const f32, items.ptr));
        checkError();
    }
}

pub fn uniform4fv(location: ?u32, items: []const [4]f32) void {
    if (location) |loc| {
        binding.uniform4fv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const f32, items.ptr));
        checkError();
    }
}

pub fn uniform1iv(location: ?u32, items: []const i32) void {
    if (location) |loc| {
        binding.uniform1iv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const i32, items.ptr));
        checkError();
    }
}

pub fn uniform2iv(location: ?u32, items: []const [2]i32) void {
    if (location) |loc| {
        binding.uniform2iv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const i32, items.ptr));
        checkError();
    }
}

pub fn uniform3iv(location: ?u32, items: []const [3]i32) void {
    if (location) |loc| {
        binding.uniform3iv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const i32, items.ptr));
        checkError();
    }
}

pub fn uniform4iv(location: ?u32, items: []const [4]i32) void {
    if (location) |loc| {
        binding.uniform4iv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const i32, items.ptr));
        checkError();
    }
}

pub fn uniform1uiv(location: ?u32, items: []const u32) void {
    if (location) |loc| {
        binding.uniform1uiv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const u32, items.ptr));
        checkError();
    }
}

pub fn uniform2uiv(location: ?u32, items: []const [2]u32) void {
    if (location) |loc| {
        binding.uniform2uiv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const u32, items.ptr));
        checkError();
    }
}

pub fn uniform3uiv(location: ?u32, items: []const [3]u32) void {
    if (location) |loc| {
        binding.uniform3uiv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const u32, items.ptr));
        checkError();
    }
}

pub fn uniform4uiv(location: ?u32, items: []const [4]u32) void {
    if (location) |loc| {
        binding.uniform4uiv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const u32, items.ptr));
        checkError();
    }
}

pub fn uniform1i64(location: ?u32, v0: i64) void {
    if (location) |loc| {
        binding.uniform1i64ARB(@intCast(types.Int, loc), v0);
        checkError();
    }
}

pub fn uniform2i64(location: ?u32, v0: i64, v1: i64) void {
    if (location) |loc| {
        binding.uniform2i64ARB(@intCast(types.Int, loc), v0, v1);
        checkError();
    }
}

pub fn uniform3i64(location: ?u32, v0: i64, v1: i64, v2: i64) void {
    if (location) |loc| {
        binding.uniform3i64ARB(@intCast(types.Int, loc), v0, v1, v2);
        checkError();
    }
}

pub fn uniform4i64(location: ?u32, v0: i64, v1: i64, v2: i64, v3: i64) void {
    if (location) |loc| {
        binding.uniform4i64ARB(@intCast(types.Int, loc), v0, v1, v2, v3);
        checkError();
    }
}

pub fn uniformMatrix4fv(location: ?u32, transpose: bool, items: []const [4][4]f32) void {
    if (location) |loc| {
        binding.uniformMatrix4fv(
            @intCast(types.Int, loc),
            cs2gl(items.len),
            b2gl(transpose),

            @ptrCast(*const f32, items.ptr),
        );
        checkError();
    }
}

///////////////////////////////////////////////////////////////////////////////
// Draw Calls

pub const PrimitiveType = enum(types.Enum) {
    points = binding.POINTS,
    line_strip = binding.LINE_STRIP,
    line_loop = binding.LINE_LOOP,
    lines = binding.LINES,
    line_strip_adjacency = binding.LINE_STRIP_ADJACENCY,
    lines_adjacency = binding.LINES_ADJACENCY,
    triangle_strip = binding.TRIANGLE_STRIP,
    triangle_fan = binding.TRIANGLE_FAN,
    triangles = binding.TRIANGLES,
    triangle_strip_adjacency = binding.TRIANGLE_STRIP_ADJACENCY,
    triangles_adjacency = binding.TRIANGLES_ADJACENCY,
    patches = binding.PATCHES,
};

pub fn drawArrays(primitiveType: PrimitiveType, first: usize, count: usize) void {
    binding.drawArrays(@enumToInt(primitiveType), cs2gl(first), cs2gl(count));
    checkError();
}

pub fn drawArraysInstanced(primitiveType: PrimitiveType, first: usize, count: usize, instanceCount: usize) void {
    binding.drawArraysInstanced(@enumToInt(primitiveType), cs2gl(first), cs2gl(count), cs2gl(instanceCount));
    checkError();
}

pub const ElementType = enum(types.Enum) {
    u8 = binding.UNSIGNED_BYTE,
    u16 = binding.UNSIGNED_SHORT,
    u32 = binding.UNSIGNED_INT,
};

pub fn drawElements(primitiveType: PrimitiveType, count: usize, element_type: ElementType, indices: usize) void {
    binding.drawElements(
        @enumToInt(primitiveType),
        cs2gl(count),
        @enumToInt(element_type),
        @intToPtr(*allowzero const anyopaque, indices),
    );
    checkError();
}

pub fn drawElementsInstanced(primitiveType: PrimitiveType, count: usize, element_type: ElementType, indices: usize, instance_count: usize) void {
    binding.drawElementsInstanced(
        @enumToInt(primitiveType),
        cs2gl(count),
        @enumToInt(element_type),
        @intToPtr(*allowzero const anyopaque, indices),
        cs2gl(instance_count),
    );
    checkError();
}

pub fn multiDrawArrays(primitiveType: PrimitiveType, first: []types.Int, count: []types.SizeI, drawcount: usize) void {
    binding.multiDrawArrays(
        @enumToInt(primitiveType),
        @ptrCast([*]const types.Int, first.ptr),
        @ptrCast([*]const types.SizeI, count.ptr),
        cs2gl(drawcount),
    );
    checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Status Control

pub const Capabilities = enum(types.Enum) {
    blend = binding.BLEND,
    // clip_distance = binding.CLIP_DISTANCE,
    color_logic_op = binding.COLOR_LOGIC_OP,
    cull_face = binding.CULL_FACE,
    debug_output = binding.DEBUG_OUTPUT,
    debug_output_synchronous = binding.DEBUG_OUTPUT_SYNCHRONOUS,
    depth_clamp = binding.DEPTH_CLAMP,
    depth_test = binding.DEPTH_TEST,
    dither = binding.DITHER,
    framebuffer_srgb = binding.FRAMEBUFFER_SRGB,
    line_smooth = binding.LINE_SMOOTH,
    multisample = binding.MULTISAMPLE,
    polygon_offset_fill = binding.POLYGON_OFFSET_FILL,
    polygon_offset_line = binding.POLYGON_OFFSET_LINE,
    polygon_offset_point = binding.POLYGON_OFFSET_POINT,
    polygon_smooth = binding.POLYGON_SMOOTH,
    primitive_restart = binding.PRIMITIVE_RESTART,
    primitive_restart_fixed_index = binding.PRIMITIVE_RESTART_FIXED_INDEX,
    rasterizer_discard = binding.RASTERIZER_DISCARD,
    sample_alpha_to_coverage = binding.SAMPLE_ALPHA_TO_COVERAGE,
    sample_alpha_to_one = binding.SAMPLE_ALPHA_TO_ONE,
    sample_coverage = binding.SAMPLE_COVERAGE,
    sample_shading = binding.SAMPLE_SHADING,
    sample_mask = binding.SAMPLE_MASK,
    scissor_test = binding.SCISSOR_TEST,
    stencil_test = binding.STENCIL_TEST,
    texture_cube_map_seamless = binding.TEXTURE_CUBE_MAP_SEAMLESS,
    program_point_size = binding.PROGRAM_POINT_SIZE,
};

pub fn enable(cap: Capabilities) void {
    binding.enable(@enumToInt(cap));
    checkError();
}

pub fn disable(cap: Capabilities) void {
    binding.disable(@enumToInt(cap));
    checkError();
}

pub fn enableI(cap: Capabilities, index: u32) void {
    binding.enablei(@enumToInt(cap), index);
    checkError();
}

pub fn disableI(cap: Capabilities, index: u32) void {
    binding.disablei(@enumToInt(cap), index);
    checkError();
}

pub const ClipOrigin = enum(types.Enum) {
    lower_left = binding.LOWER_LEFT,
    upper_left = binding.UPPER_LEFT,
};
pub const ClipDepth = enum(types.Enum) {
    negative_one_to_one = binding.NEGATIVE_ONE_TO_ONE,
    zero_to_one = binding.ZERO_TO_ONE,
};

pub fn clipControl(origin: ClipOrigin, depth: ClipDepth) void {
    binding.clipControl(@enumToInt(origin), @enumToInt(depth));
    checkError();
}

pub const CullMode = enum(types.Enum) {
    front = binding.FRONT,
    back = binding.BACK,
    front_and_back = binding.FRONT_AND_BACK,
};

pub fn cullFace(mode: CullMode) void {
    binding.cullFace(@enumToInt(mode));
    checkError();
}

pub fn depthMask(enabled: bool) void {
    binding.depthMask(if (enabled) binding.TRUE else binding.FALSE);
    checkError();
}

pub const DepthFunc = enum(types.Enum) {
    never = binding.NEVER,
    less = binding.LESS,
    equal = binding.EQUAL,
    less_or_equal = binding.LEQUAL,
    greater = binding.GREATER,
    not_equal = binding.NOTEQUAL,
    greator_or_equal = binding.GEQUAL,
    always = binding.ALWAYS,
};

pub fn depthFunc(func: DepthFunc) void {
    binding.depthFunc(@enumToInt(func));
    checkError();
}

pub const Face = enum(types.Enum) {
    cw = binding.CW,
    ccw = binding.CCW,
};

pub fn frontFace(mode: Face) void {
    binding.frontFace(@enumToInt(mode));
    checkError();
}

pub fn stencilMask(mask: u32) void {
    binding.stencilMask(mask);
    checkError();
}

pub const StencilFunc = enum(types.Enum) {
    never = binding.NEVER,
    less = binding.LESS,
    equal = binding.EQUAL,
    less_or_equal = binding.LEQUAL,
    greater = binding.GREATER,
    not_equal = binding.NOTEQUAL,
    greator_or_equal = binding.GEQUAL,
    always = binding.ALWAYS,
};

pub fn stencilFunc(func: StencilFunc, ref: i32, mask: u32) void {
    binding.stencilFunc(@enumToInt(func), ref, mask);
    checkError();
}

pub const StencilOp = enum(types.Enum) {
    keep = binding.KEEP,
    zero = binding.ZERO,
    replace = binding.REPLACE,
    incr = binding.INCR,
    incr_wrap = binding.INCR_WRAP,
    decr = binding.DECR,
    decr_wrap = binding.DECR_WRAP,
    invert = binding.INVERT,
};

pub fn stencilOp(sfail: StencilOp, dpfail: StencilOp, dppass: StencilOp) void {
    binding.stencilOp(@enumToInt(sfail), @enumToInt(dpfail), @enumToInt(dppass));
    checkError();
}

pub const BlendFactor = enum(types.Enum) {
    zero = binding.ZERO,
    one = binding.ONE,
    src_color = binding.SRC_COLOR,
    one_minus_src_color = binding.ONE_MINUS_SRC_COLOR,
    dst_color = binding.DST_COLOR,
    one_minus_dst_color = binding.ONE_MINUS_DST_COLOR,
    src_alpha = binding.SRC_ALPHA,
    one_minus_src_alpha = binding.ONE_MINUS_SRC_ALPHA,
    dst_alpha = binding.DST_ALPHA,
    one_minus_dst_alpha = binding.ONE_MINUS_DST_ALPHA,
    constant_color = binding.CONSTANT_COLOR,
    one_minus_constant_color = binding.ONE_MINUS_CONSTANT_COLOR,
    constant_alpha = binding.CONSTANT_ALPHA,
    one_minus_constant_alpha = binding.ONE_MINUS_CONSTANT_ALPHA,
};

pub fn blendFunc(sfactor: BlendFactor, dfactor: BlendFactor) void {
    binding.blendFunc(@enumToInt(sfactor), @enumToInt(dfactor));
    checkError();
}

pub fn blendFuncSeparate(srcRGB: BlendFactor, dstRGB: BlendFactor, srcAlpha: BlendFactor, dstAlpha: BlendFactor) void {
    binding.blendFuncSeparate(@enumToInt(srcRGB), @enumToInt(dstRGB), @enumToInt(srcAlpha), @enumToInt(dstAlpha));
    checkError();
}

pub const DrawMode = enum(types.Enum) {
    point = binding.POINT,
    line = binding.LINE,
    fill = binding.FILL,
};

pub fn polygonMode(face: CullMode, mode: DrawMode) void {
    binding.polygonMode(@enumToInt(face), @enumToInt(mode));
    checkError();
}

pub fn polygonOffset(factor: f32, units: f32) void {
    binding.polygonOffset(factor, units);
    checkError();
}

pub fn pointSize(size: f32) void {
    binding.pointSize(size);
    checkError();
}

pub fn lineWidth(size: f32) void {
    binding.lineWidth(size);
    checkError();
}

pub const TextureTarget = enum(types.Enum) {
    @"1d" = binding.TEXTURE_1D,
    @"2d" = binding.TEXTURE_2D,
    @"3d" = binding.TEXTURE_3D,
    @"1d_array" = binding.TEXTURE_1D_ARRAY,
    @"2d_array" = binding.TEXTURE_2D_ARRAY,
    rectangle = binding.TEXTURE_RECTANGLE,
    cube_map = binding.TEXTURE_CUBE_MAP,
    cube_map_array = binding.TEXTURE_CUBE_MAP_ARRAY,
    buffer = binding.TEXTURE_BUFFER,
    @"2d_multisample" = binding.TEXTURE_2D_MULTISAMPLE,
    @"2d_multisample_array" = binding.TEXTURE_2D_MULTISAMPLE_ARRAY,
};

pub fn genTexture() types.Texture {
    var tex_name: types.UInt = undefined;
    binding.genTextures(1, &tex_name);
    checkError();
    return @intToEnum(types.Texture, tex_name);
}

pub fn createTexture(texture_target: TextureTarget) types.Texture {
    var tex_name: types.UInt = undefined;

    binding.createTextures(@enumToInt(texture_target), 1, &tex_name);
    checkError();

    const texture = @intToEnum(types.Texture, tex_name);
    if (texture == .invalid) {
        checkError();
        unreachable;
    }
    return texture;
}

pub fn deleteTexture(texture: types.Texture) void {
    var id = @enumToInt(texture);
    binding.deleteTextures(1, &id);
}

pub fn generateMipmap(target: TextureTarget) void {
    binding.generateMipmap(@enumToInt(target));
    checkError();
}

pub fn generateTextureMipmap(texture: types.Texture) void {
    binding.generateTextureMipmap(@enumToInt(texture));
    checkError();
}

pub fn bindTextureUnit(texture: types.Texture, unit: u32) void {
    binding.bindTextureUnit(unit, @enumToInt(texture));
    checkError();
}

pub fn bindTexture(texture: types.Texture, target: TextureTarget) void {
    binding.bindTexture(@enumToInt(target), @enumToInt(texture));
    checkError();
}

pub fn activeTexture(texture_unit: TextureUnit) void {
    binding.activeTexture(@enumToInt(texture_unit));
    checkError();
}

pub const TextureUnit = enum(types.Enum) {
    texture_0 = binding.TEXTURE0,
    texture_1 = binding.TEXTURE1,
    texture_2 = binding.TEXTURE2,
    texture_3 = binding.TEXTURE3,
    texture_4 = binding.TEXTURE4,
    texture_5 = binding.TEXTURE5,
    texture_6 = binding.TEXTURE6,
    texture_7 = binding.TEXTURE7,
    _,

    pub fn unit(id: types.Enum) TextureUnit {
        return @intToEnum(TextureUnit, @enumToInt(TextureUnit.texture_0) + id);
    }
};

pub const TextureParameter = enum(types.Enum) {
    depth_stencil_texture_mode = binding.DEPTH_STENCIL_TEXTURE_MODE,
    base_level = binding.TEXTURE_BASE_LEVEL,
    compare_func = binding.TEXTURE_COMPARE_FUNC,
    compare_mode = binding.TEXTURE_COMPARE_MODE,
    lod_bias = binding.TEXTURE_LOD_BIAS,
    min_filter = binding.TEXTURE_MIN_FILTER,
    mag_filter = binding.TEXTURE_MAG_FILTER,
    min_lod = binding.TEXTURE_MIN_LOD,
    max_lod = binding.TEXTURE_MAX_LOD,
    max_level = binding.TEXTURE_MAX_LEVEL,
    swizzle_r = binding.TEXTURE_SWIZZLE_R,
    swizzle_g = binding.TEXTURE_SWIZZLE_G,
    swizzle_b = binding.TEXTURE_SWIZZLE_B,
    swizzle_a = binding.TEXTURE_SWIZZLE_A,
    wrap_s = binding.TEXTURE_WRAP_S,
    wrap_t = binding.TEXTURE_WRAP_T,
    wrap_r = binding.TEXTURE_WRAP_R,
};

pub fn TextureParameterType(comptime param: TextureParameter) type {
    // see https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glTexParameter.xhtml
    return switch (param) {
        .wrap_s, .wrap_t, .wrap_r => enum(types.Int) {
            clamp_to_edge = binding.CLAMP_TO_EDGE,
            clamp_to_border = binding.CLAMP_TO_BORDER,
            mirrored_repeat = binding.MIRRORED_REPEAT,
            repeat = binding.REPEAT,
            mirror_clamp_to_edge = binding.MIRROR_CLAMP_TO_EDGE,
        },
        .swizzle_r, .swizzle_g, .swizzle_b, .swizzle_a => enum(types.Int) {
            red = binding.RED,
            green = binding.GREEN,
            blue = binding.BLUE,
            alpha = binding.ALPHA,
            zero = binding.ZERO,
            one = binding.ONE,
        },
        .mag_filter => enum(types.Int) {
            nearest = binding.NEAREST,
            linear = binding.LINEAR,
        },
        .min_filter => enum(types.Int) {
            nearest = binding.NEAREST,
            linear = binding.LINEAR,
            nearest_mipmap_nearest = binding.NEAREST_MIPMAP_NEAREST,
            linear_mipmap_nearest = binding.LINEAR_MIPMAP_NEAREST,
            nearest_mipmap_linear = binding.NEAREST_MIPMAP_LINEAR,
            linear_mipmap_linear = binding.LINEAR_MIPMAP_LINEAR,
        },
        .compare_mode => enum(types.Int) {
            none = binding.NONE,
        },
        else => @compileError("textureParameter not implemented yet for " ++ @tagName(param)),
    };
}

pub fn texParameter(target: TextureTarget, comptime parameter: TextureParameter, value: TextureParameterType(parameter)) void {
    const T = TextureParameterType(parameter);
    const info = @typeInfo(T);
    if (info == .Enum) {
        binding.texParameteri(@enumToInt(target), @enumToInt(parameter), @enumToInt(value));
    } else {
        @compileError(@tagName(info) ++ " is not supported yet by texParameter");
    }
    checkError();
}

pub fn textureParameter(texture: types.Texture, comptime parameter: TextureParameter, value: TextureParameterType(parameter)) void {
    const T = TextureParameterType(parameter);
    const info = @typeInfo(T);

    if (info == .Enum) {
        binding.textureParameteri(@enumToInt(texture), @enumToInt(parameter), @enumToInt(value));
    } else {
        @compileError(@tagName(info) ++ " is not supported yet by textureParameter");
    }
    checkError();
}

pub const TextureInternalFormat = enum(types.Enum) {
    red = binding.RED,
    rg = binding.RG,
    rgb = binding.RGB,
    bgr = binding.BGR,
    rgba = binding.RGBA,
    bgra = binding.BGRA,
    depth_component = binding.DEPTH_COMPONENT,
    stencil_index = binding.STENCIL_INDEX,
    //luminance = binding.LUMINANCE,

    red_integer = binding.RED_INTEGER,
    rg_integer = binding.RG_INTEGER,
    rgb_integer = binding.RGB_INTEGER,
    bgr_integer = binding.BGR_INTEGER,
    rgba_integer = binding.RGBA_INTEGER,
    bgra_integer = binding.BGRA_INTEGER,

    r8 = binding.R8,
    r8_snorm = binding.R8_SNORM,
    r16 = binding.R16,
    r16_snorm = binding.R16_SNORM,
    rg8 = binding.RG8,
    rg8_snorm = binding.RG8_SNORM,
    rg16 = binding.RG16,
    rg16_snorm = binding.RG16_SNORM,
    r3_g3_b2 = binding.R3_G3_B2,
    rgb4 = binding.RGB4,
    rgb5 = binding.RGB5,
    rgb8 = binding.RGB8,
    rgb8_snorm = binding.RGB8_SNORM,
    rgb10 = binding.RGB10,
    rgb12 = binding.RGB12,
    rgb16_snorm = binding.RGB16_SNORM,
    rgba2 = binding.RGBA2,
    rgba4 = binding.RGBA4,
    rgb5_a1 = binding.RGB5_A1,
    rgba8 = binding.RGBA8,
    rgba8_snorm = binding.RGBA8_SNORM,
    rgb10_a2 = binding.RGB10_A2,
    rgb10_a2ui = binding.RGB10_A2UI,
    rgba12 = binding.RGBA12,
    rgba16 = binding.RGBA16,
    srgb8 = binding.SRGB8,
    srgb8_alpha8 = binding.SRGB8_ALPHA8,
    r16f = binding.R16F,
    rg16f = binding.RG16F,
    rgb16f = binding.RGB16F,
    rgba16f = binding.RGBA16F,
    r32f = binding.R32F,
    rg32f = binding.RG32F,
    rgb32f = binding.RGB32F,
    rgba32f = binding.RGBA32F,
    r11f_g11f_b10f = binding.R11F_G11F_B10F,
    rgb9_e5 = binding.RGB9_E5,
    r8i = binding.R8I,
    r8ui = binding.R8UI,
    r16i = binding.R16I,
    r16ui = binding.R16UI,
    r32i = binding.R32I,
    r32ui = binding.R32UI,
    rg8i = binding.RG8I,
    rg8ui = binding.RG8UI,
    rg16i = binding.RG16I,
    rg16ui = binding.RG16UI,
    rg32i = binding.RG32I,
    rg32ui = binding.RG32UI,
    rgb8i = binding.RGB8I,
    rgb8ui = binding.RGB8UI,
    rgb16i = binding.RGB16I,
    rgb16ui = binding.RGB16UI,
    rgb32i = binding.RGB32I,
    rgb32ui = binding.RGB32UI,
    rgba8i = binding.RGBA8I,
    rgba8ui = binding.RGBA8UI,
    rgba16i = binding.RGBA16I,
    rgba16ui = binding.RGBA16UI,
    rgba32i = binding.RGBA32I,
    rgba32ui = binding.RGBA32UI,
    depth_component16 = binding.DEPTH_COMPONENT16,
};

pub fn texStorage2D(
    target: TextureTarget,
    levels: usize,
    internalformat: TextureInternalFormat,
    width: usize,
    height: usize,
) void {
    binding.texStorage2D(
        @enumToInt(target),
        @intCast(types.SizeI, levels),
        @enumToInt(internalformat),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
    );
    checkError();
}

pub fn textureStorage2D(
    texture: types.Texture,
    levels: usize,
    internalformat: TextureInternalFormat,
    width: usize,
    height: usize,
) void {
    binding.textureStorage2D(
        @enumToInt(texture),
        @intCast(types.SizeI, levels),
        @enumToInt(internalformat),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
    );
    checkError();
}

pub fn texStorage3D(
    target: TextureTarget,
    levels: usize,
    internalformat: TextureInternalFormat,
    width: usize,
    height: usize,
    depth: usize
) void {
    binding.texStorage3D(
        @enumToInt(target),
        @intCast(types.SizeI, levels),
        @enumToInt(internalformat),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
        @intCast(types.SizeI, depth)
    );
    checkError();
}

pub fn textureStorage3D(
    texture: types.Texture,
    levels: usize,
    internalformat: TextureInternalFormat,
    width: usize,
    height: usize,
    depth: usize,
) void {
    binding.textureStorage3D(
        @enumToInt(texture),
        @intCast(types.SizeI, levels),
        @enumToInt(internalformat),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
        @intCast(types.SizeI, depth),
    );
    checkError();
}

pub const PixelFormat = enum(types.Enum) {
    red = binding.RED,
    green = binding.GREEN,
    blue = binding.BLUE,
    rg = binding.RG,
    rgb = binding.RGB,
    bgr = binding.BGR,
    rgba = binding.RGBA,
    bgra = binding.BGRA,
    depth_component = binding.DEPTH_COMPONENT,
    stencil_index = binding.STENCIL_INDEX,
    depth_stencil = binding.DEPTH_STENCIL,
    //luminance = binding.LUMINANCE,

    red_integer = binding.RED_INTEGER,
    rg_integer = binding.RG_INTEGER,
    rgb_integer = binding.RGB_INTEGER,
    bgr_integer = binding.BGR_INTEGER,
    rgba_integer = binding.RGBA_INTEGER,
    bgra_integer = binding.BGRA_INTEGER,
};

pub const PixelType = enum(types.Enum) {
    unsigned_byte = binding.UNSIGNED_BYTE,
    byte = binding.BYTE,
    unsigned_short = binding.UNSIGNED_SHORT,
    short = binding.SHORT,
    unsigned_int = binding.UNSIGNED_INT,
    int = binding.INT,
    float = binding.FLOAT,
    unsigned_byte_3_3_2 = binding.UNSIGNED_BYTE_3_3_2,
    unsigned_byte_2_3_3_rev = binding.UNSIGNED_BYTE_2_3_3_REV,
    unsigned_short_5_6_5 = binding.UNSIGNED_SHORT_5_6_5,
    unsigned_short_5_6_5_rev = binding.UNSIGNED_SHORT_5_6_5_REV,
    unsigned_short_4_4_4_4 = binding.UNSIGNED_SHORT_4_4_4_4,
    unsigned_short_4_4_4_4_rev = binding.UNSIGNED_SHORT_4_4_4_4_REV,
    unsigned_short_5_5_5_1 = binding.UNSIGNED_SHORT_5_5_5_1,
    unsigned_short_1_5_5_5_rev = binding.UNSIGNED_SHORT_1_5_5_5_REV,
    unsigned_int_8_8_8_8 = binding.UNSIGNED_INT_8_8_8_8,
    unsigned_int_8_8_8_8_rev = binding.UNSIGNED_INT_8_8_8_8_REV,
    unsigned_int_10_10_10_2 = binding.UNSIGNED_INT_10_10_10_2,
    unsigned_int_2_10_10_10_rev = binding.UNSIGNED_INT_2_10_10_10_REV,
};

pub fn textureImage2D(
    texture: TextureTarget,
    level: usize,
    pixel_internal_format: TextureInternalFormat,
    width: usize,
    height: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    data: ?[*]const u8,
) void {
    binding.texImage2D(
        @enumToInt(texture),
        @intCast(types.Int, level),
        @intCast(types.Int, @enumToInt(pixel_internal_format)),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
        0,
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        data,
    );
    checkError();
}

pub fn texSubImage2D(
    textureTarget: TextureTarget,
    level: usize,
    xoffset: usize,
    yoffset: usize,
    width: usize,
    height: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    data: ?[*]const u8,
) void {
    binding.texSubImage2D(
        @enumToInt(textureTarget),
        @intCast(types.Int, level),
        @intCast(types.Int, xoffset),
        @intCast(types.Int, yoffset),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        data,
    );
    checkError();
}

pub fn textureSubImage2D(
    texture: types.Texture,
    level: usize,
    xoffset: usize,
    yoffset: usize,
    width: usize,
    height: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    data: ?[*]const u8,
) void {
    binding.textureSubImage2D(
        @enumToInt(texture),
        @intCast(types.Int, level),
        @intCast(types.Int, xoffset),
        @intCast(types.Int, yoffset),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        data,
    );
    checkError();
}

pub fn textureSubImage3D(
    texture: types.Texture,
    level: usize,
    xoffset: usize,
    yoffset: usize,
    zoffset: usize,
    width: usize,
    height: usize,
    depth: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    pixels: ?[*]const u8,
) void {
    binding.textureSubImage3D(
        @enumToInt(texture),
        @intCast(types.Int, level),
        @intCast(types.Int, xoffset),
        @intCast(types.Int, yoffset),
        @intCast(types.Int, zoffset),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
        @intCast(types.SizeI, depth),
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        pixels,
    );
    checkError();
}

pub fn textureImage3D(
    texture: TextureTarget,
    level: usize,
    pixel_internal_format: TextureInternalFormat,
    width: usize,
    height: usize,
    depth: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    data: ?[*]const u8,
) void {
    binding.texImage3D(
        @enumToInt(texture),
        @intCast(types.Int, level),
        @intCast(types.Int, @enumToInt(pixel_internal_format)),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
        @intCast(types.SizeI, depth),
        0,
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        data,
    );
    checkError();
}

pub fn texSubImage3D(
    textureTarget: TextureTarget,
    level: usize,
    xoffset: usize,
    yoffset: usize,
    zoffset: usize,
    width: usize,
    height: usize,
    depth: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    data: ?[*]const u8,
) void {
    binding.texSubImage3D(
        @enumToInt(textureTarget),
        @intCast(types.Int, level),
        @intCast(types.Int, xoffset),
        @intCast(types.Int, yoffset),
        @intCast(types.Int, zoffset),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
        @intCast(types.SizeI, depth),
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        data,
    );
    checkError();
}

pub fn getTexImage(
    textureTarget: TextureTarget,
    level: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    data: [*]u8,
) void {
    binding.getTexImage(
        @enumToInt(textureTarget),
        @intCast(types.Int, level),
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        data,
    );
    checkError();
}

pub fn getTextureSubImage(
    texture: types.Texture,
    level: usize,
    xoffset: usize,
    yoffset: usize,
    zoffset: usize,
    width: usize,
    height: usize,
    depth: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    size: usize,
    data: [*]u8,
) void {
    binding.getTextureSubImage(
        @enumToInt(texture),
        @intCast(types.Int, level),
        @intCast(types.Int, xoffset),
        @intCast(types.Int, yoffset),
        @intCast(types.Int, zoffset),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
        @intCast(types.SizeI, depth),
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        @intCast(types.SizeI, size),
        data,
    );
    checkError();
}

pub fn copyTexSubImage2D(
    target: TextureTarget,
    level: usize,
    xoffset: usize,
    yoffset: usize,
    x: usize,
    y: usize,
    width: usize,
    height: usize,
) void {
    binding.copyTexSubImage2D(
        @enumToInt(target),
        @intCast(types.Int, level),
        @intCast(types.Int, xoffset),
        @intCast(types.Int, yoffset),
        @intCast(types.Int, x),
        @intCast(types.Int, y),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
    );
    checkError();
}

pub const PixelStoreParameter = enum(types.Enum) {
    pack_swap_bytes = binding.PACK_SWAP_BYTES,
    pack_lsb_first = binding.PACK_LSB_FIRST,
    pack_row_length = binding.PACK_ROW_LENGTH,
    pack_image_height = binding.PACK_IMAGE_HEIGHT,
    pack_skip_pixels = binding.PACK_SKIP_PIXELS,
    pack_skip_rows = binding.PACK_SKIP_ROWS,
    pack_skip_images = binding.PACK_SKIP_IMAGES,
    pack_alignment = binding.PACK_ALIGNMENT,

    unpack_swap_bytes = binding.UNPACK_SWAP_BYTES,
    unpack_lsb_first = binding.UNPACK_LSB_FIRST,
    unpack_row_length = binding.UNPACK_ROW_LENGTH,
    unpack_image_height = binding.UNPACK_IMAGE_HEIGHT,
    unpack_skip_pixels = binding.UNPACK_SKIP_PIXELS,
    unpack_skip_rows = binding.UNPACK_SKIP_ROWS,
    unpack_skip_images = binding.UNPACK_SKIP_IMAGES,
    unpack_alignment = binding.UNPACK_ALIGNMENT,
};

pub fn pixelStore(param: PixelStoreParameter, value: usize) void {
    binding.pixelStorei(@enumToInt(param), @intCast(types.Int, value));
    checkError();
}

pub fn viewport(x: i32, y: i32, width: usize, height: usize) void {
    binding.viewport(@intCast(types.Int, x), @intCast(types.Int, y), @intCast(types.SizeI, width), @intCast(types.SizeI, height));
    checkError();
}

pub fn scissor(x: i32, y: i32, width: usize, height: usize) void {
    binding.scissor(@intCast(types.Int, x), @intCast(types.Int, y), @intCast(types.SizeI, width), @intCast(types.SizeI, height));
    checkError();
}

pub const RenderbufferTarget = enum(types.Enum) {
    buffer = binding.RENDERBUFFER,
};

pub fn createRenderbuffer() types.Renderbuffer {
    var rb_name: types.UInt = undefined;
    binding.createRenderbuffers(1, &rb_name);
    checkError();
    const framebuffer = @intToEnum(types.Renderbuffer, rb_name);
    if (framebuffer == .invalid) {
        checkError();
        unreachable;
    }
    return framebuffer;
}

pub fn genRenderbuffer() types.Renderbuffer {
    var rb_name: types.UInt = undefined;
    binding.genRenderbuffers(1, &rb_name);
    checkError();
    const framebuffer = @intToEnum(types.Renderbuffer, rb_name);
    if (framebuffer == .invalid) unreachable;
    return framebuffer;
}

pub fn deleteRenderbuffer(buf: types.Renderbuffer) void {
    var rb_name = @enumToInt(buf);
    binding.deleteRenderbuffers(1, &rb_name);
}

pub fn bindRenderbuffer(buf: types.Renderbuffer, target: RenderbufferTarget) void {
    binding.bindRenderbuffer(@enumToInt(target), @enumToInt(buf));
    checkError();
}

pub fn renderbufferStorage(
    buf: types.Renderbuffer,
    target: RenderbufferTarget,
    pixel_internal_format: PixelFormat,
    width: usize,
    height: usize,
) void {
    buf.bind(.buffer);
    binding.renderbufferStorage(@enumToInt(target), @enumToInt(pixel_internal_format), @intCast(types.SizeI, width), @intCast(types.SizeI, height));
    checkError();
}

pub fn renderbufferStorageMultisample(
    buf: types.Renderbuffer,
    target: RenderbufferTarget,
    samples: usize,
    pixel_internal_format: PixelFormat,
    width: usize,
    height: usize,
) void {
    buf.bind(.buffer);
    binding.renderbufferStorageMultisample(@enumToInt(target), @intCast(types.SizeI, samples), @enumToInt(pixel_internal_format), @intCast(types.SizeI, width), @intCast(types.SizeI, height));
    checkError();
}

pub const FramebufferTarget = enum(types.Enum) {
    buffer = binding.FRAMEBUFFER,
    draw_buffer = binding.DRAW_FRAMEBUFFER,
    read_buffer = binding.READ_FRAMEBUFFER,
};

pub fn createFramebuffer() types.Framebuffer {
    var fb_name: types.UInt = undefined;
    binding.createFramebuffers(1, &fb_name);
    checkError();
    const framebuffer = @intToEnum(types.Framebuffer, fb_name);
    if (framebuffer == .invalid) {
        checkError();
        unreachable;
    }
    return framebuffer;
}

pub fn genFramebuffer() types.Framebuffer {
    var fb_name: types.UInt = undefined;
    binding.genFramebuffers(1, &fb_name);
    checkError();
    const framebuffer = @intToEnum(types.Framebuffer, fb_name);
    if (framebuffer == .invalid) unreachable;
    return framebuffer;
}

pub fn deleteFramebuffer(buf: types.Framebuffer) void {
    var fb_name = @enumToInt(buf);
    binding.deleteFramebuffers(1, &fb_name);
}

pub fn bindFramebuffer(buf: types.Framebuffer, target: FramebufferTarget) void {
    binding.bindFramebuffer(@enumToInt(target), @enumToInt(buf));
    checkError();
}

pub const FramebufferAttachment = enum(types.Enum) {
    color0 = binding.COLOR_ATTACHMENT0,
    color1 = binding.COLOR_ATTACHMENT1,
    color2 = binding.COLOR_ATTACHMENT2,
    color3 = binding.COLOR_ATTACHMENT3,
    color4 = binding.COLOR_ATTACHMENT4,
    color5 = binding.COLOR_ATTACHMENT5,
    color6 = binding.COLOR_ATTACHMENT6,
    color7 = binding.COLOR_ATTACHMENT7,
    depth = binding.DEPTH_ATTACHMENT,
    stencil = binding.STENCIL_ATTACHMENT,
    depth_stencil = binding.DEPTH_STENCIL_ATTACHMENT,
    max_color = binding.MAX_COLOR_ATTACHMENTS,
};

pub fn framebufferTexture(buffer: types.Framebuffer, target: FramebufferTarget, attachment: FramebufferAttachment, texture: types.Texture, level: i32) void {
    buffer.bind(.buffer);
    binding.framebufferTexture(@enumToInt(target), @enumToInt(attachment), @intCast(types.UInt, @enumToInt(texture)), @intCast(types.Int, level));
    checkError();
}

pub const FramebufferTextureTarget = enum(types.Enum) {
    @"1d" = binding.TEXTURE_1D,
    @"2d" = binding.TEXTURE_2D,
    @"3d" = binding.TEXTURE_3D,
    @"1d_array" = binding.TEXTURE_1D_ARRAY,
    @"2d_array" = binding.TEXTURE_2D_ARRAY,
    rectangle = binding.TEXTURE_RECTANGLE,
    cube_map_positive_x = binding.TEXTURE_CUBE_MAP_POSITIVE_X,
    cube_map_negative_x = binding.TEXTURE_CUBE_MAP_NEGATIVE_X,
    cube_map_positive_y = binding.TEXTURE_CUBE_MAP_POSITIVE_Y,
    cube_map_negative_y = binding.TEXTURE_CUBE_MAP_NEGATIVE_Y,
    cube_map_positive_z = binding.TEXTURE_CUBE_MAP_POSITIVE_Z,
    cube_map_negative_z = binding.TEXTURE_CUBE_MAP_NEGATIVE_Z,
    buffer = binding.TEXTURE_BUFFER,
    @"2d_multisample" = binding.TEXTURE_2D_MULTISAMPLE,
    @"2d_multisample_array" = binding.TEXTURE_2D_MULTISAMPLE_ARRAY,
};

pub fn framebufferTexture2D(buffer: types.Framebuffer, target: FramebufferTarget, attachment: FramebufferAttachment, textarget: FramebufferTextureTarget, texture: types.Texture, level: i32) void {
    buffer.bind(.buffer);
    binding.framebufferTexture2D(@enumToInt(target), @enumToInt(attachment), @enumToInt(textarget), @intCast(types.UInt, @enumToInt(texture)), @intCast(types.Int, level));
    checkError();
}

pub fn framebufferRenderbuffer(buffer: types.Framebuffer, target: FramebufferTarget, attachment: FramebufferAttachment, rbtarget: RenderbufferTarget, renderbuffer: types.Renderbuffer) void {
    buffer.bind(.buffer);
    binding.framebufferRenderbuffer(@enumToInt(target), @enumToInt(attachment), @enumToInt(rbtarget), @intCast(types.UInt, @enumToInt(renderbuffer)));
    checkError();
}

const FramebufferStatus = enum(types.UInt) {
    complete = binding.FRAMEBUFFER_COMPLETE,
};

pub fn checkFramebufferStatus(target: FramebufferTarget) FramebufferStatus {
    const status = @intToEnum(FramebufferStatus, binding.checkFramebufferStatus(@enumToInt(target)));
    return status;
}

pub fn drawBuffers(bufs: []const FramebufferAttachment) void {
    binding.drawBuffers(cs2gl(bufs.len), @ptrCast([*]const types.UInt, bufs.ptr));
}

pub fn blitFramebuffer(
    srcX0: usize,
    srcY0: usize,
    srcX1: usize,
    srcY1: usize,
    destX0: usize,
    destY0: usize,
    destX1: usize,
    destY1: usize,
    mask: struct { color: bool = false, depth: bool = false, stencil: bool = false },
    filter: enum(types.UInt) { nearest = binding.NEAREST, linear = binding.LINEAR },
) void {
    binding.blitFramebuffer(
        @intCast(types.Int, srcX0),
        @intCast(types.Int, srcY0),
        @intCast(types.Int, srcX1),
        @intCast(types.Int, srcY1),
        @intCast(types.Int, destX0),
        @intCast(types.Int, destY0),
        @intCast(types.Int, destX1),
        @intCast(types.Int, destY1),
        @as(types.BitField, if (mask.color) binding.COLOR_BUFFER_BIT else 0) |
            @as(types.BitField, if (mask.depth) binding.DEPTH_BUFFER_BIT else 0) |
            @as(types.BitField, if (mask.stencil) binding.STENCIL_BUFFER_BIT else 0),
        @enumToInt(filter),
    );
    checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Invalidation
pub fn invalidateTexImage(texture: types.Texture, level: types.Int) void {
    binding.invalidateTexImage(@enumToInt(texture), level);
    checkError();
}

pub fn invalidateFramebuffer(target: FramebufferTarget, attachments: []const FramebufferAttachment) void {
    binding.invalidateFramebuffer(@enumToInt(target), cs2gl(attachments.len), @ptrCast([*]const types.Enum, attachments.ptr));
    checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Parameters
pub const Parameter = enum(types.Enum) {
    active_texture = binding.ACTIVE_TEXTURE,
    aliased_line_width_range = binding.ALIASED_LINE_WIDTH_RANGE,
    array_buffer_binding = binding.ARRAY_BUFFER_BINDING,
    blend = binding.BLEND,
    blend_color = binding.BLEND_COLOR,
    blend_dst_alpha = binding.BLEND_DST_ALPHA,
    blend_dst_rgb = binding.BLEND_DST_RGB,
    blend_equation_alpha = binding.BLEND_EQUATION_ALPHA,
    blend_equation_rgb = binding.BLEND_EQUATION_RGB,
    blend_src_alpha = binding.BLEND_SRC_ALPHA,
    blend_src_rgb = binding.BLEND_SRC_RGB,
    color_clear_value = binding.COLOR_CLEAR_VALUE,
    color_logic_op = binding.COLOR_LOGIC_OP,
    color_writemask = binding.COLOR_WRITEMASK,
    compressed_texture_formats = binding.COMPRESSED_TEXTURE_FORMATS,
    context_flags = binding.CONTEXT_FLAGS,
    cull_face = binding.CULL_FACE,
    current_program = binding.CURRENT_PROGRAM,
    depth_clear_value = binding.DEPTH_CLEAR_VALUE,
    depth_func = binding.DEPTH_FUNC,
    depth_range = binding.DEPTH_RANGE,
    depth_test = binding.DEPTH_TEST,
    depth_writemask = binding.DEPTH_WRITEMASK,
    dither = binding.DITHER,
    doublebuffer = binding.DOUBLEBUFFER,
    draw_buffer = binding.DRAW_BUFFER,
    draw_buffer0 = binding.DRAW_BUFFER0,
    draw_buffer1 = binding.DRAW_BUFFER1,
    draw_buffer2 = binding.DRAW_BUFFER2,
    draw_buffer3 = binding.DRAW_BUFFER3,
    draw_buffer4 = binding.DRAW_BUFFER4,
    draw_buffer5 = binding.DRAW_BUFFER5,
    draw_buffer6 = binding.DRAW_BUFFER6,
    draw_buffer7 = binding.DRAW_BUFFER7,
    draw_buffer8 = binding.DRAW_BUFFER8,
    draw_buffer9 = binding.DRAW_BUFFER9,
    draw_buffer10 = binding.DRAW_BUFFER10,
    draw_buffer11 = binding.DRAW_BUFFER11,
    draw_buffer12 = binding.DRAW_BUFFER12,
    draw_buffer13 = binding.DRAW_BUFFER13,
    draw_buffer14 = binding.DRAW_BUFFER14,
    draw_buffer15 = binding.DRAW_BUFFER15,
    draw_framebuffer_binding = binding.DRAW_FRAMEBUFFER_BINDING,
    element_array_buffer_binding = binding.ELEMENT_ARRAY_BUFFER_BINDING,
    fragment_shader_derivative_hint = binding.FRAGMENT_SHADER_DERIVATIVE_HINT,
    line_smooth = binding.LINE_SMOOTH,
    line_smooth_hint = binding.LINE_SMOOTH_HINT,
    line_width = binding.LINE_WIDTH,
    logic_op_mode = binding.LOGIC_OP_MODE,
    major_version = binding.MAJOR_VERSION,
    max_3d_texture_size = binding.MAX_3D_TEXTURE_SIZE,
    max_array_texture_layers = binding.MAX_ARRAY_TEXTURE_LAYERS,
    max_clip_distances = binding.MAX_CLIP_DISTANCES,
    max_color_texture_samples = binding.MAX_COLOR_TEXTURE_SAMPLES,
    max_combined_fragment_uniform_components = binding.MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS,
    max_combined_geometry_uniform_components = binding.MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS,
    max_combined_texture_image_units = binding.MAX_COMBINED_TEXTURE_IMAGE_UNITS,
    max_combined_uniform_blocks = binding.MAX_COMBINED_UNIFORM_BLOCKS,
    max_combined_vertex_uniform_components = binding.MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS,
    max_cube_map_texture_size = binding.MAX_CUBE_MAP_TEXTURE_SIZE,
    max_depth_texture_samples = binding.MAX_DEPTH_TEXTURE_SAMPLES,
    max_draw_buffers = binding.MAX_DRAW_BUFFERS,
    max_dual_source_draw_buffers = binding.MAX_DUAL_SOURCE_DRAW_BUFFERS,
    max_elements_indices = binding.MAX_ELEMENTS_INDICES,
    max_elements_vertices = binding.MAX_ELEMENTS_VERTICES,
    max_fragment_input_components = binding.MAX_FRAGMENT_INPUT_COMPONENTS,
    max_fragment_uniform_blocks = binding.MAX_FRAGMENT_UNIFORM_BLOCKS,
    max_fragment_uniform_components = binding.MAX_FRAGMENT_UNIFORM_COMPONENTS,
    max_geometry_input_components = binding.MAX_GEOMETRY_INPUT_COMPONENTS,
    max_geometry_output_components = binding.MAX_GEOMETRY_OUTPUT_COMPONENTS,
    max_geometry_texture_image_units = binding.MAX_GEOMETRY_TEXTURE_IMAGE_UNITS,
    max_geometry_uniform_blocks = binding.MAX_GEOMETRY_UNIFORM_BLOCKS,
    max_geometry_uniform_components = binding.MAX_GEOMETRY_UNIFORM_COMPONENTS,
    max_integer_samples = binding.MAX_INTEGER_SAMPLES,
    max_program_texel_offset = binding.MAX_PROGRAM_TEXEL_OFFSET,
    max_rectangle_texture_size = binding.MAX_RECTANGLE_TEXTURE_SIZE,
    max_renderbuffer_size = binding.MAX_RENDERBUFFER_SIZE,
    max_sample_mask_words = binding.MAX_SAMPLE_MASK_WORDS,
    max_server_wait_timeout = binding.MAX_SERVER_WAIT_TIMEOUT,
    max_texture_buffer_size = binding.MAX_TEXTURE_BUFFER_SIZE,
    max_texture_image_units = binding.MAX_TEXTURE_IMAGE_UNITS,
    max_texture_lod_bias = binding.MAX_TEXTURE_LOD_BIAS,
    max_texture_size = binding.MAX_TEXTURE_SIZE,
    max_uniform_block_size = binding.MAX_UNIFORM_BLOCK_SIZE,
    max_uniform_buffer_bindings = binding.MAX_UNIFORM_BUFFER_BINDINGS,
    max_varying_components = binding.MAX_VARYING_COMPONENTS,
    // max_varying_floats = binding.MAX_VARYING_FLOATS,
    max_vertex_attribs = binding.MAX_VERTEX_ATTRIBS,
    max_vertex_output_components = binding.MAX_VERTEX_OUTPUT_COMPONENTS,
    max_vertex_texture_image_units = binding.MAX_VERTEX_TEXTURE_IMAGE_UNITS,
    max_vertex_uniform_blocks = binding.MAX_VERTEX_UNIFORM_BLOCKS,
    max_vertex_uniform_components = binding.MAX_VERTEX_UNIFORM_COMPONENTS,
    max_viewport_dims = binding.MAX_VIEWPORT_DIMS,
    min_program_texel_offset = binding.MIN_PROGRAM_TEXEL_OFFSET,
    minor_version = binding.MINOR_VERSION,
    num_compressed_texture_formats = binding.NUM_COMPRESSED_TEXTURE_FORMATS,
    num_extensions = binding.NUM_EXTENSIONS,
    pack_alignment = binding.PACK_ALIGNMENT,
    pack_image_height = binding.PACK_IMAGE_HEIGHT,
    pack_lsb_first = binding.PACK_LSB_FIRST,
    pack_row_length = binding.PACK_ROW_LENGTH,
    pack_skip_images = binding.PACK_SKIP_IMAGES,
    pack_skip_pixels = binding.PACK_SKIP_PIXELS,
    pack_skip_rows = binding.PACK_SKIP_ROWS,
    pack_swap_bytes = binding.PACK_SWAP_BYTES,
    pixel_pack_buffer_binding = binding.PIXEL_PACK_BUFFER_BINDING,
    pixel_unpack_buffer_binding = binding.PIXEL_UNPACK_BUFFER_BINDING,
    point_fade_threshold_size = binding.POINT_FADE_THRESHOLD_SIZE,
    point_size = binding.POINT_SIZE,
    point_size_granularity = binding.POINT_SIZE_GRANULARITY,
    point_size_range = binding.POINT_SIZE_RANGE,
    polygon_mode = binding.POLYGON_MODE,
    polygon_offset_factor = binding.POLYGON_OFFSET_FACTOR,
    polygon_offset_fill = binding.POLYGON_OFFSET_FILL,
    polygon_offset_line = binding.POLYGON_OFFSET_LINE,
    polygon_offset_point = binding.POLYGON_OFFSET_POINT,
    polygon_offset_units = binding.POLYGON_OFFSET_UNITS,
    polygon_smooth = binding.POLYGON_SMOOTH,
    polygon_smooth_hint = binding.POLYGON_SMOOTH_HINT,
    primitive_restart_index = binding.PRIMITIVE_RESTART_INDEX,
    program_point_size = binding.PROGRAM_POINT_SIZE,
    provoking_vertex = binding.PROVOKING_VERTEX,
    read_buffer = binding.READ_BUFFER,
    read_framebuffer_binding = binding.READ_FRAMEBUFFER_BINDING,
    renderbuffer_binding = binding.RENDERBUFFER_BINDING,
    sample_buffers = binding.SAMPLE_BUFFERS,
    sample_coverage_invert = binding.SAMPLE_COVERAGE_INVERT,
    sample_coverage_value = binding.SAMPLE_COVERAGE_VALUE,
    sampler_binding = binding.SAMPLER_BINDING,
    samples = binding.SAMPLES,
    scissor_box = binding.SCISSOR_BOX,
    scissor_test = binding.SCISSOR_TEST,
    smooth_line_width_granularity = binding.SMOOTH_LINE_WIDTH_GRANULARITY,
    smooth_line_width_range = binding.SMOOTH_LINE_WIDTH_RANGE,
    stencil_back_fail = binding.STENCIL_BACK_FAIL,
    stencil_back_func = binding.STENCIL_BACK_FUNC,
    stencil_back_pass_depth_fail = binding.STENCIL_BACK_PASS_DEPTH_FAIL,
    stencil_back_pass_depth_pass = binding.STENCIL_BACK_PASS_DEPTH_PASS,
    stencil_back_ref = binding.STENCIL_BACK_REF,
    stencil_back_value_mask = binding.STENCIL_BACK_VALUE_MASK,
    stencil_back_writemask = binding.STENCIL_BACK_WRITEMASK,
    stencil_clear_value = binding.STENCIL_CLEAR_VALUE,
    stencil_fail = binding.STENCIL_FAIL,
    stencil_func = binding.STENCIL_FUNC,
    stencil_pass_depth_fail = binding.STENCIL_PASS_DEPTH_FAIL,
    stencil_pass_depth_pass = binding.STENCIL_PASS_DEPTH_PASS,
    stencil_ref = binding.STENCIL_REF,
    stencil_test = binding.STENCIL_TEST,
    stencil_value_mask = binding.STENCIL_VALUE_MASK,
    stencil_writemask = binding.STENCIL_WRITEMASK,
    stereo = binding.STEREO,
    subpixel_bits = binding.SUBPIXEL_BITS,
    texture_binding_1d = binding.TEXTURE_BINDING_1D,
    texture_binding_1d_array = binding.TEXTURE_BINDING_1D_ARRAY,
    texture_binding_2d = binding.TEXTURE_BINDING_2D,
    texture_binding_2d_array = binding.TEXTURE_BINDING_2D_ARRAY,
    texture_binding_2d_multisample = binding.TEXTURE_BINDING_2D_MULTISAMPLE,
    texture_binding_2d_multisample_array = binding.TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY,
    texture_binding_3d = binding.TEXTURE_BINDING_3D,
    texture_binding_buffer = binding.TEXTURE_BINDING_BUFFER,
    texture_binding_cube_map = binding.TEXTURE_BINDING_CUBE_MAP,
    texture_binding_rectangle = binding.TEXTURE_BINDING_RECTANGLE,
    texture_compression_hint = binding.TEXTURE_COMPRESSION_HINT,
    timestamp = binding.TIMESTAMP,
    transform_feedback_buffer_binding = binding.TRANSFORM_FEEDBACK_BUFFER_BINDING,
    transform_feedback_buffer_size = binding.TRANSFORM_FEEDBACK_BUFFER_SIZE,
    transform_feedback_buffer_start = binding.TRANSFORM_FEEDBACK_BUFFER_START,
    uniform_buffer_binding = binding.UNIFORM_BUFFER_BINDING,
    uniform_buffer_offset_alignment = binding.UNIFORM_BUFFER_OFFSET_ALIGNMENT,
    uniform_buffer_size = binding.UNIFORM_BUFFER_SIZE,
    uniform_buffer_start = binding.UNIFORM_BUFFER_START,
    unpack_alignment = binding.UNPACK_ALIGNMENT,
    unpack_image_height = binding.UNPACK_IMAGE_HEIGHT,
    unpack_lsb_first = binding.UNPACK_LSB_FIRST,
    unpack_row_length = binding.UNPACK_ROW_LENGTH,
    unpack_skip_images = binding.UNPACK_SKIP_IMAGES,
    unpack_skip_pixels = binding.UNPACK_SKIP_PIXELS,
    unpack_skip_rows = binding.UNPACK_SKIP_ROWS,
    unpack_swap_bytes = binding.UNPACK_SWAP_BYTES,
    viewport = binding.VIEWPORT,
};

pub fn getInteger(parameter: Parameter) i32 {
    var value: types.Int = undefined;
    binding.getIntegerv(@enumToInt(parameter), &value);
    checkError();
    return value;
}

pub const StringParameter = enum(types.Enum) {
    vendor = binding.VENDOR,
    renderer = binding.RENDERER,
    version = binding.VERSION,
    shading_language_version = binding.SHADING_LANGUAGE_VERSION,
    extensions = binding.EXTENSIONS,
};

pub fn getStringi(parameter: StringParameter, index: u32) ?[:0]const u8 {
    return std.mem.span(binding.getStringi(@enumToInt(parameter), index));
}
pub fn getString(parameter: StringParameter) ?[:0]const u8 {
    return std.mem.span(binding.getString(@enumToInt(parameter)));
}

pub fn hasExtension(extension: [:0]const u8) bool {
    const count = @intCast(usize, getInteger(.num_extensions));
    for (0..count) |i| {
        const ext = getStringi(.extensions, @intCast(u32, i)) orelse return false;
        if (std.mem.eql(u8, ext, extension)) {
            return true;
        }
    }
    return false;
}

pub fn loadExtensions(load_ctx: anytype, get_proc_address: fn (@TypeOf(load_ctx), [:0]const u8) ?binding.FunctionPointer) !void {
    return binding.load(load_ctx, get_proc_address);
}
