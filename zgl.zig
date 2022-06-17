const std = @import("std");

const c = @cImport({
    @cInclude("epoxy/gl.h");
});

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

    var error_code = c.glGetError();
    if (error_code == c.GL_NO_ERROR)
        return;
    while (error_code != c.GL_NO_ERROR) : (error_code = c.glGetError()) {
        const name = switch (error_code) {
            c.GL_INVALID_ENUM => "invalid enum",
            c.GL_INVALID_VALUE => "invalid value",
            c.GL_INVALID_OPERATION => "invalid operation",
            c.GL_STACK_OVERFLOW => "stack overflow",
            c.GL_STACK_UNDERFLOW => "stack underflow",
            c.GL_OUT_OF_MEMORY => "out of memory",
            c.GL_INVALID_FRAMEBUFFER_OPERATION => "invalid framebuffer operation",
            // c.GL_INVALID_FRAMEBUFFER_OPERATION_EXT => Error.InvalidFramebufferOperation,
            // c.GL_INVALID_FRAMEBUFFER_OPERATION_OES => Error.InvalidFramebufferOperation,
            c.GL_TABLE_TOO_LARGE => "Table too large",
            // c.GL_TABLE_TOO_LARGE_EXT => Error.TableTooLarge,
            c.GL_TEXTURE_TOO_LARGE_EXT => "Texture too large",
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
        c.GL_TRUE
    else
        c.GL_FALSE;
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
                c.GL_DEBUG_SOURCE_API => DebugSource.api,
                // c.GL_DEBUG_SOURCE_API_ARB => DebugSource.api,
                // c.GL_DEBUG_SOURCE_API_KHR => DebugSource.api,
                c.GL_DEBUG_SOURCE_WINDOW_SYSTEM => DebugSource.window_system,
                // c.GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB => DebugSource.window_system,
                // c.GL_DEBUG_SOURCE_WINDOW_SYSTEM_KHR => DebugSource.window_system,
                c.GL_DEBUG_SOURCE_SHADER_COMPILER => DebugSource.shader_compiler,
                // c.GL_DEBUG_SOURCE_SHADER_COMPILER_ARB => DebugSource.shader_compiler,
                // c.GL_DEBUG_SOURCE_SHADER_COMPILER_KHR => DebugSource.shader_compiler,
                c.GL_DEBUG_SOURCE_THIRD_PARTY => DebugSource.third_party,
                // c.GL_DEBUG_SOURCE_THIRD_PARTY_ARB => DebugSource.third_party,
                // c.GL_DEBUG_SOURCE_THIRD_PARTY_KHR => DebugSource.third_party,
                c.GL_DEBUG_SOURCE_APPLICATION => DebugSource.application,
                // c.GL_DEBUG_SOURCE_APPLICATION_ARB => DebugSource.application,
                // c.GL_DEBUG_SOURCE_APPLICATION_KHR => DebugSource.application,
                c.GL_DEBUG_SOURCE_OTHER => DebugSource.other,
                // c.GL_DEBUG_SOURCE_OTHER_ARB => DebugSource.other,
                // c.GL_DEBUG_SOURCE_OTHER_KHR => DebugSource.other,
                else => DebugSource.other,
            };
        }

        fn translateMessageType(msg_type: types.UInt) DebugMessageType {
            return switch (msg_type) {
                c.GL_DEBUG_TYPE_ERROR => DebugMessageType.@"error",
                // c.GL_DEBUG_TYPE_ERROR_ARB => DebugMessageType.@"error",
                // c.GL_DEBUG_TYPE_ERROR_KHR => DebugMessageType.@"error",
                c.GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR => DebugMessageType.deprecated_behavior,
                // c.GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB => DebugMessageType.deprecated_behavior,
                // c.GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_KHR => DebugMessageType.deprecated_behavior,
                c.GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR => DebugMessageType.undefined_behavior,
                // c.GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB => DebugMessageType.undefined_behavior,
                // c.GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_KHR => DebugMessageType.undefined_behavior,
                c.GL_DEBUG_TYPE_PORTABILITY => DebugMessageType.portability,
                // c.GL_DEBUG_TYPE_PORTABILITY_ARB => DebugMessageType.portability,
                // c.GL_DEBUG_TYPE_PORTABILITY_KHR => DebugMessageType.portability,
                c.GL_DEBUG_TYPE_PERFORMANCE => DebugMessageType.performance,
                // c.GL_DEBUG_TYPE_PERFORMANCE_ARB => DebugMessageType.performance,
                // c.GL_DEBUG_TYPE_PERFORMANCE_KHR => DebugMessageType.performance,
                c.GL_DEBUG_TYPE_OTHER => DebugMessageType.other,
                // c.GL_DEBUG_TYPE_OTHER_ARB => DebugMessageType.other,
                // c.GL_DEBUG_TYPE_OTHER_KHR => DebugMessageType.other,
                else => DebugMessageType.other,
            };
        }

        fn translateSeverity(sev: types.UInt) DebugSeverity {
            return switch (sev) {
                c.GL_DEBUG_SEVERITY_HIGH => DebugSeverity.high,
                // c.GL_DEBUG_SEVERITY_HIGH_AMD => DebugSeverity.high,
                // c.GL_DEBUG_SEVERITY_HIGH_ARB => DebugSeverity.high,
                // c.GL_DEBUG_SEVERITY_HIGH_KHR => DebugSeverity.high,
                c.GL_DEBUG_SEVERITY_MEDIUM => DebugSeverity.medium,
                // c.GL_DEBUG_SEVERITY_MEDIUM_AMD => DebugSeverity.medium,
                // c.GL_DEBUG_SEVERITY_MEDIUM_ARB => DebugSeverity.medium,
                // c.GL_DEBUG_SEVERITY_MEDIUM_KHR => DebugSeverity.medium,
                c.GL_DEBUG_SEVERITY_LOW => DebugSeverity.low,
                // c.GL_DEBUG_SEVERITY_LOW_AMD => DebugSeverity.low,
                // c.GL_DEBUG_SEVERITY_LOW_ARB => DebugSeverity.low,
                // c.GL_DEBUG_SEVERITY_LOW_KHR => DebugSeverity.low,
                c.GL_DEBUG_SEVERITY_NOTIFICATION => DebugSeverity.notification,
                // c.GL_DEBUG_SEVERITY_NOTIFICATION_KHR => DebugSeverity.notification,
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
        c.glDebugMessageCallback(H.callback, null)
    else
        c.glDebugMessageCallback(H.callback, @ptrCast(?*const anyopaque, context));
    checkError();
}

pub fn clearColor(r: f32, g: f32, b: f32, a: f32) void {
    c.glClearColor(r, g, b, a);
    checkError();
}

pub fn clearDepth(depth: f32) void {
    c.glClearDepth(depth);
    checkError();
}

pub fn clear(mask: struct { color: bool = false, depth: bool = false, stencil: bool = false }) void {
    c.glClear(@as(types.BitField, if (mask.color) c.GL_COLOR_BUFFER_BIT else 0) |
        @as(types.BitField, if (mask.depth) c.GL_DEPTH_BUFFER_BIT else 0) |
        @as(types.BitField, if (mask.stencil) c.GL_STENCIL_BUFFER_BIT else 0));
    checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Vertex Arrays

pub fn createVertexArrays(items: []types.VertexArray) void {
    c.glCreateVertexArrays(cs2gl(items.len), @ptrCast([*]types.UInt, items.ptr));
    checkError();
}

pub fn createVertexArray() types.VertexArray {
    var vao: types.VertexArray = undefined;
    createVertexArrays(@ptrCast([*]types.VertexArray, &vao)[0..1]);
    return vao;
}

pub fn genVertexArrays(items: []types.VertexArray) void {
    c.glGenVertexArrays(cs2gl(items.len), @ptrCast([*]types.UInt, items.ptr));
    checkError();
}

pub fn genVertexArray() types.VertexArray {
    var vao: types.VertexArray = undefined;
    genVertexArrays(@ptrCast([*]types.VertexArray, &vao)[0..1]);
    return vao;
}

pub fn bindVertexArray(vao: types.VertexArray) void {
    c.glBindVertexArray(@enumToInt(vao));
    checkError();
}

pub fn deleteVertexArrays(items: []const types.VertexArray) void {
    c.glDeleteVertexArrays(cs2gl(items.len), @ptrCast([*]const types.UInt, items.ptr));
}

pub fn deleteVertexArray(vao: types.VertexArray) void {
    deleteVertexArrays(@ptrCast([*]const types.VertexArray, &vao)[0..1]);
}

pub fn enableVertexAttribArray(index: u32) void {
    c.glEnableVertexAttribArray(index);
    checkError();
}

pub fn vertexAttribDivisor(index: u32, divisor: u32) void {
    c.glVertexAttribDivisor(index, divisor);
    checkError();
}

pub fn disableVertexAttribArray(index: u32) void {
    c.glDisableVertexAttribArray(index);
    checkError();
}

pub fn enableVertexArrayAttrib(vertexArray: types.VertexArray, index: u32) void {
    c.glEnableVertexArrayAttrib(@enumToInt(vertexArray), index);
    checkError();
}

pub fn disableVertexArrayAttrib(vertexArray: types.VertexArray, index: u32) void {
    c.glDisableVertexArrayAttrib(@enumToInt(vertexArray), index);
    checkError();
}

pub const Type = enum(types.Enum) {
    byte = c.GL_BYTE,
    short = c.GL_SHORT,
    int = c.GL_INT,
    fixed = c.GL_FIXED,
    float = c.GL_FLOAT,
    half_float = c.GL_HALF_FLOAT,
    double = c.GL_DOUBLE,
    unsigned_byte = c.GL_UNSIGNED_BYTE,
    unsigned_short = c.GL_UNSIGNED_SHORT,
    unsigned_int = c.GL_UNSIGNED_INT,
    int_2_10_10_10_rev = c.GL_INT_2_10_10_10_REV,
    unsigned_int_2_10_10_10_rev = c.GL_UNSIGNED_INT_2_10_10_10_REV,
    unsigned_int_10_f_11_f_11_f_rev = c.GL_UNSIGNED_INT_10F_11F_11F_REV,
};

pub fn vertexAttribFormat(attribindex: u32, size: u32, attribute_type: Type, normalized: bool, relativeoffset: usize) void {
    c.glVertexAttribFormat(
        attribindex,
        @intCast(types.Int, size),
        @enumToInt(attribute_type),
        b2gl(normalized),
        ui2gl(relativeoffset),
    );
    checkError();
}

pub fn vertexAttribIFormat(attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) void {
    c.glVertexAttribIFormat(
        attribindex,
        @intCast(types.Int, size),
        @enumToInt(attribute_type),
        ui2gl(relativeoffset),
    );
    checkError();
}

pub fn vertexAttribLFormat(attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) void {
    c.glVertexAttribLFormat(
        attribindex,
        @intCast(types.Int, size),
        @enumToInt(attribute_type),
        ui2gl(relativeoffset),
    );
    checkError();
}

/// NOTE: if you use any integer type, it will cast to a floating point, you are probably looking for vertexAttribIPointer()
pub fn vertexAttribPointer(attribindex: u32, size: u32, attribute_type: Type, normalized: bool, stride: usize, relativeoffset: usize) void {
    c.glVertexAttribPointer(
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
    c.glVertexAttribIPointer(
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
    c.glVertexArrayAttribFormat(
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
    c.glVertexArrayAttribIFormat(
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
    c.glVertexArrayAttribLFormat(
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
    c.glVertexAttribBinding(
        attribindex,
        bindingindex,
    );
    checkError();
}
pub fn vertexArrayAttribBinding(vertexArray: types.VertexArray, attribindex: u32, bindingindex: u32) void {
    c.glVertexArrayAttribBinding(
        @enumToInt(vertexArray),
        attribindex,
        bindingindex,
    );
    checkError();
}

pub fn bindVertexBuffer(bindingindex: u32, buffer: types.Buffer, offset: usize, stride: usize) void {
    c.glBindVertexBuffer(bindingindex, @enumToInt(buffer), cs2gl(offset), cs2gl(stride));
    checkError();
}

pub fn vertexArrayVertexBuffer(vertexArray: types.VertexArray, bindingindex: u32, buffer: types.Buffer, offset: usize, stride: usize) void {
    c.glVertexArrayVertexBuffer(@enumToInt(vertexArray), bindingindex, @enumToInt(buffer), cs2gl(offset), cs2gl(stride));
    checkError();
}

pub fn vertexArrayElementBuffer(vertexArray: types.VertexArray, buffer: types.Buffer) void {
    c.glVertexArrayElementBuffer(@enumToInt(vertexArray), @enumToInt(buffer));
    checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Buffer

pub const BufferTarget = enum(types.Enum) {
    /// Vertex attributes
    array_buffer = c.GL_ARRAY_BUFFER,
    /// Atomic counter storage
    atomic_counter_buffer = c.GL_ATOMIC_COUNTER_BUFFER,
    /// Buffer copy source
    copy_read_buffer = c.GL_COPY_READ_BUFFER,
    /// Buffer copy destination
    copy_write_buffer = c.GL_COPY_WRITE_BUFFER,
    /// Indirect compute dispatch commands
    dispatch_indirect_buffer = c.GL_DISPATCH_INDIRECT_BUFFER,
    /// Indirect command arguments
    draw_indirect_buffer = c.GL_DRAW_INDIRECT_BUFFER,
    /// Vertex array indices
    element_array_buffer = c.GL_ELEMENT_ARRAY_BUFFER,
    /// Pixel read target
    pixel_pack_buffer = c.GL_PIXEL_PACK_BUFFER,
    /// Texture data source
    pixel_unpack_buffer = c.GL_PIXEL_UNPACK_BUFFER,
    /// Query result buffer
    query_buffer = c.GL_QUERY_BUFFER,
    /// Read-write storage for shaders
    shader_storage_buffer = c.GL_SHADER_STORAGE_BUFFER,
    /// Texture data buffer
    texture_buffer = c.GL_TEXTURE_BUFFER,
    /// Transform feedback buffer
    transform_feedback_buffer = c.GL_TRANSFORM_FEEDBACK_BUFFER,
    /// Uniform block storage
    uniform_buffer = c.GL_UNIFORM_BUFFER,
};

pub fn createBuffers(items: []types.Buffer) void {
    c.glCreateBuffers(cs2gl(items.len), @ptrCast([*]types.UInt, items.ptr));
    checkError();
}

pub fn createBuffer() types.Buffer {
    var buf: types.Buffer = undefined;
    createBuffers(@ptrCast([*]types.Buffer, &buf)[0..1]);
    return buf;
}

pub fn genBuffers(items: []types.Buffer) void {
    c.glGenBuffers(cs2gl(items.len), @ptrCast([*]types.UInt, items.ptr));
    checkError();
}

pub fn genBuffer() types.Buffer {
    var buf: types.Buffer = undefined;
    genBuffers(@ptrCast([*]types.Buffer, &buf)[0..1]);
    return buf;
}

pub fn bindBuffer(buf: types.Buffer, target: BufferTarget) void {
    c.glBindBuffer(@enumToInt(target), @enumToInt(buf));
    checkError();
}

pub fn deleteBuffers(items: []const types.Buffer) void {
    c.glDeleteBuffers(cs2gl(items.len), @ptrCast([*]const types.UInt, items.ptr));
}

pub fn deleteBuffer(buf: types.Buffer) void {
    deleteBuffers(@ptrCast([*]const types.Buffer, &buf)[0..1]);
}

pub const BufferUsage = enum(types.Enum) {
    stream_draw = c.GL_STREAM_DRAW,
    stream_read = c.GL_STREAM_READ,
    stream_copy = c.GL_STREAM_COPY,
    static_draw = c.GL_STATIC_DRAW,
    static_read = c.GL_STATIC_READ,
    static_copy = c.GL_STATIC_COPY,
    dynamic_draw = c.GL_DYNAMIC_DRAW,
    dynamic_read = c.GL_DYNAMIC_READ,
    dynamic_copy = c.GL_DYNAMIC_COPY,
};

// using align(1) as we are not required to have aligned data here
pub fn namedBufferData(buf: types.Buffer, comptime T: type, items: []align(1) const T, usage: BufferUsage) void {
    c.glNamedBufferData(
        @enumToInt(buf),
        cs2gl(@sizeOf(T) * items.len),
        items.ptr,
        @enumToInt(usage),
    );
    checkError();
}

pub fn namedBufferUninitialized(buf: types.Buffer, comptime T: type, count: usize, usage: BufferUsage) void {
    c.glNamedBufferData(
        @enumToInt(buf),
        cs2gl(@sizeOf(T) * count),
        null,
        @enumToInt(usage),
    );
    checkError();
}

pub fn bufferData(target: BufferTarget, comptime T: type, items: []align(1) const T, usage: BufferUsage) void {
    c.glBufferData(
        @enumToInt(target),
        cs2gl(@sizeOf(T) * items.len),
        items.ptr,
        @enumToInt(usage),
    );
    checkError();
}

pub fn bufferUninitialized(target: BufferTarget, comptime T: type, count: usize, usage: BufferUsage) void {
    c.glBufferData(
        @enumToInt(target),
        cs2gl(@sizeOf(T) * count),
        null,
        @enumToInt(usage),
    );
    checkError();
}

pub fn bufferSubData(target: BufferTarget, offset: usize, comptime T: type, items: []align(1) const T) void {
    c.glBufferSubData(@enumToInt(target), cs2gl(offset), cs2gl(@sizeOf(T) * items.len), items.ptr);
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

pub fn namedBufferStorage(buf: types.Buffer, comptime T: type, count: usize, items: ?[*]align(1) const T, flags: BufferStorageFlags) void {
    var flag_bits: c.GLbitfield = 0;
    if (flags.dynamic_storage) flag_bits |= c.GL_DYNAMIC_STORAGE_BIT;
    if (flags.map_read) flag_bits |= c.GL_MAP_READ_BIT;
    if (flags.map_write) flag_bits |= c.GL_MAP_WRITE_BIT;
    if (flags.map_persistent) flag_bits |= c.GL_MAP_PERSISTENT_BIT;
    if (flags.map_coherent) flag_bits |= c.GL_MAP_COHERENT_BIT;
    if (flags.client_storage) flag_bits |= c.GL_CLIENT_STORAGE_BIT;

    c.glNamedBufferStorage(
        @enumToInt(buf),
        cs2gl(@sizeOf(T) * count),
        items,
        flag_bits,
    );
    checkError();
}

pub const BufferMapTarget = enum(types.Enum) {
    array_buffer = c.GL_ARRAY_BUFFER,
    atomic_counter_buffer = c.GL_ATOMIC_COUNTER_BUFFER,
    copy_read_buffer = c.GL_COPY_READ_BUFFER,
    copy_write_buffer = c.GL_COPY_WRITE_BUFFER,
    dispatch_indirect_buffer = c.GL_DISPATCH_INDIRECT_BUFFER,
    draw_indirect_buffer = c.GL_DRAW_INDIRECT_BUFFER,
    element_array_buffer = c.GL_ELEMENT_ARRAY_BUFFER,
    pixel_pack_buffer = c.GL_PIXEL_PACK_BUFFER,
    pixel_unpack_buffer = c.GL_PIXEL_UNPACK_BUFFER,
    query_buffer = c.GL_QUERY_BUFFER,
    shader_storage_buffer = c.GL_SHADER_STORAGE_BUFFER,
    texture_buffer = c.GL_TEXTURE_BUFFER,
    transform_feedback_buffer = c.GL_TRANSFORM_FEEDBACK_BUFFER,
    uniform_buffer = c.GL_UNIFORM_BUFFER,
};

pub const BufferMapAccess = enum(types.Enum) {
    read_only = c.GL_READ_ONLY,
    write_only = c.GL_WRITE_ONLY,
    read_write = c.GL_READ_WRITE,
};

pub fn mapBuffer(
    target: BufferMapTarget,
    comptime T: type,
    access: BufferMapAccess,
) [*]align(1) T {
    const ptr = c.glMapBuffer(
        @enumToInt(target),
        @enumToInt(access),
    );

    checkError();
    return @ptrCast([*]align(1) T, ptr);
}

pub fn unmapBuffer(target: BufferMapTarget) bool {
    const ok = c.glUnmapBuffer(@enumToInt(target));
    checkError();
    return ok == c.GL_TRUE;
}

pub const BufferMapFlags = packed struct {
    read: bool = false,
    write: bool = false,
    persistent: bool = false,
    coherent: bool = false,
};

pub fn mapNamedBufferRange(
    buf: types.Buffer,
    comptime T: type,
    offset: usize,
    count: usize,
    flags: BufferMapFlags,
) []align(1) T {
    var flag_bits: c.GLbitfield = 0;
    if (flags.read) flag_bits |= c.GL_MAP_READ_BIT;
    if (flags.write) flag_bits |= c.GL_MAP_WRITE_BIT;
    if (flags.persistent) flag_bits |= c.GL_MAP_PERSISTENT_BIT;
    if (flags.coherent) flag_bits |= c.GL_MAP_COHERENT_BIT;

    const ptr = c.glMapNamedBufferRange(
        @enumToInt(buf),
        @intCast(c.GLintptr, offset),
        @intCast(c.GLsizeiptr, @sizeOf(T) * count),
        flag_bits,
    );
    checkError();

    const values = @ptrCast([*]align(1) T, ptr);
    return values[0..count];
}

pub fn unmapNamedBuffer(buf: types.Buffer) bool {
    const ok = c.glUnmapNamedBuffer(@enumToInt(buf));
    checkError();
    return ok != 0;
}

///////////////////////////////////////////////////////////////////////////////
// Shaders

pub const ShaderType = enum(types.Enum) {
    compute = c.GL_COMPUTE_SHADER,
    vertex = c.GL_VERTEX_SHADER,
    tess_control = c.GL_TESS_CONTROL_SHADER,
    tess_evaluation = c.GL_TESS_EVALUATION_SHADER,
    geometry = c.GL_GEOMETRY_SHADER,
    fragment = c.GL_FRAGMENT_SHADER,
};

pub fn createShader(shaderType: ShaderType) types.Shader {
    const shader = @intToEnum(types.Shader, c.glCreateShader(@enumToInt(shaderType)));
    if (shader == .invalid) {
        checkError();
        unreachable;
    }
    return shader;
}

pub fn deleteShader(shader: types.Shader) void {
    c.glDeleteShader(@enumToInt(shader));
    checkError();
}

pub fn compileShader(shader: types.Shader) void {
    c.glCompileShader(@enumToInt(shader));
    checkError();
}

pub fn shaderSource(shader: types.Shader, comptime N: comptime_int, sources: *const [N][]const u8) void {
    var lengths: [N]types.Int = undefined;
    for (lengths) |*len, i| {
        len.* = @intCast(types.Int, sources[i].len);
    }

    var ptrs: [N]*const types.Char = undefined;
    for (ptrs) |*ptr, i| {
        ptr.* = @ptrCast(*const types.Char, sources[i].ptr);
    }

    c.glShaderSource(@enumToInt(shader), N, &ptrs, &lengths);

    checkError();
}

pub const ShaderParameter = enum(types.Enum) {
    shader_type = c.GL_SHADER_TYPE,
    delete_status = c.GL_DELETE_STATUS,
    compile_status = c.GL_COMPILE_STATUS,
    info_log_length = c.GL_INFO_LOG_LENGTH,
    shader_source_length = c.GL_SHADER_SOURCE_LENGTH,
};

pub fn getShader(shader: types.Shader, parameter: ShaderParameter) types.Int {
    var value: types.Int = undefined;
    c.glGetShaderiv(@enumToInt(shader), @enumToInt(parameter), &value);
    checkError();
    return value;
}

pub fn getShaderInfoLog(shader: types.Shader, allocator: std.mem.Allocator) ![:0]const u8 {
    const length = getShader(shader, .info_log_length);
    const log = try allocator.allocSentinel(u8, @intCast(usize, length), 0);
    errdefer allocator.free(log);

    c.glGetShaderInfoLog(@enumToInt(shader), cs2gl(log.len), null, log.ptr);
    checkError();

    return log;
}

///////////////////////////////////////////////////////////////////////////////
// Program

pub fn createProgram() types.Program {
    const program = @intToEnum(types.Program, c.glCreateProgram());
    if (program == .invalid) {
        checkError();
        unreachable;
    }
    return program;
}

pub fn deleteProgram(program: types.Program) void {
    c.glDeleteProgram(@enumToInt(program));
    checkError();
}

pub fn linkProgram(program: types.Program) void {
    c.glLinkProgram(@enumToInt(program));
    checkError();
}

pub fn attachShader(program: types.Program, shader: types.Shader) void {
    c.glAttachShader(@enumToInt(program), @enumToInt(shader));
    checkError();
}

pub fn detachShader(program: types.Program, shader: types.Shader) void {
    c.glDetachShader(@enumToInt(program), @enumToInt(shader));
    checkError();
}

pub fn useProgram(program: types.Program) void {
    c.glUseProgram(@enumToInt(program));
    checkError();
}

pub const ProgramParameter = enum(types.Enum) {
    delete_status = c.GL_DELETE_STATUS,
    link_status = c.GL_LINK_STATUS,
    validate_status = c.GL_VALIDATE_STATUS,
    info_log_length = c.GL_INFO_LOG_LENGTH,
    attached_shaders = c.GL_ATTACHED_SHADERS,
    active_atomic_counter_buffers = c.GL_ACTIVE_ATOMIC_COUNTER_BUFFERS,
    active_attributes = c.GL_ACTIVE_ATTRIBUTES,
    active_attribute_max_length = c.GL_ACTIVE_ATTRIBUTE_MAX_LENGTH,
    active_uniforms = c.GL_ACTIVE_UNIFORMS,
    active_uniform_blocks = c.GL_ACTIVE_UNIFORM_BLOCKS,
    active_uniform_block_max_name_length = c.GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH,
    active_uniform_max_length = c.GL_ACTIVE_UNIFORM_MAX_LENGTH,
    compute_work_group_size = c.GL_COMPUTE_WORK_GROUP_SIZE,
    program_binary_length = c.GL_PROGRAM_BINARY_LENGTH,
    transform_feedback_buffer_mode = c.GL_TRANSFORM_FEEDBACK_BUFFER_MODE,
    transform_feedback_varyings = c.GL_TRANSFORM_FEEDBACK_VARYINGS,
    transform_feedback_varying_max_length = c.GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH,
    geometry_vertices_out = c.GL_GEOMETRY_VERTICES_OUT,
    geometry_input_type = c.GL_GEOMETRY_INPUT_TYPE,
    geometry_output_type = c.GL_GEOMETRY_OUTPUT_TYPE,
};

pub fn getProgram(program: types.Program, parameter: ProgramParameter) types.Int {
    var value: types.Int = undefined;
    c.glGetProgramiv(@enumToInt(program), @enumToInt(parameter), &value);
    checkError();
    return value;
}

pub fn getProgramInfoLog(program: types.Program, allocator: std.mem.Allocator) ![:0]const u8 {
    const length = getProgram(program, .info_log_length);
    const log = try allocator.allocSentinel(u8, @intCast(usize, length), 0);
    errdefer allocator.free(log);

    c.glGetProgramInfoLog(@enumToInt(program), cs2gl(log.len), null, log.ptr);
    checkError();

    return log;
}

pub fn getUniformLocation(program: types.Program, name: [:0]const u8) ?u32 {
    const loc = c.glGetUniformLocation(@enumToInt(program), name.ptr);
    checkError();
    if (loc < 0)
        return null;
    return @intCast(u32, loc);
}

pub fn getAttribLocation(program: types.Program, name: [:0]const u8) ?u32 {
    const loc = c.glGetAttribLocation(@enumToInt(program), name.ptr);
    checkError();
    if (loc < 0)
        return null;
    return @intCast(u32, loc);
}

///////////////////////////////////////////////////////////////////////////////
// Uniforms

pub fn programUniform1ui(program: types.Program, location: ?u32, value: u32) void {
    if (location) |loc| {
        c.glProgramUniform1ui(@enumToInt(program), @intCast(types.Int, loc), value);
        checkError();
    }
}

pub fn programUniform1i(program: types.Program, location: ?u32, value: i32) void {
    if (location) |loc| {
        c.glProgramUniform1i(@enumToInt(program), @intCast(types.Int, loc), value);
        checkError();
    }
}

pub fn programUniform3ui(program: types.Program, location: ?u32, x: u32, y: u32, z: u32) void {
    if (location) |loc| {
        c.glProgramUniform3ui(@enumToInt(program), @intCast(types.Int, loc), x, y, z);
        checkError();
    }
}

pub fn programUniform3i(program: types.Program, location: ?u32, x: i32, y: i32, z: i32) void {
    if (location) |loc| {
        c.glProgramUniform3i(@enumToInt(program), @intCast(types.Int, loc), x, y, z);
        checkError();
    }
}

pub fn programUniform2i(program: types.Program, location: ?u32, v0: i32, v1: i32) void {
    if (location) |loc| {
        c.glProgramUniform2i(@enumToInt(program), @intCast(types.Int, loc), v0, v1);
        checkError();
    }
}

pub fn programUniform1f(program: types.Program, location: ?u32, value: f32) void {
    if (location) |loc| {
        c.glProgramUniform1f(@enumToInt(program), @intCast(types.Int, loc), value);
        checkError();
    }
}

pub fn programUniform2f(program: types.Program, location: ?u32, x: f32, y: f32) void {
    if (location) |loc| {
        c.glProgramUniform2f(@enumToInt(program), @intCast(types.Int, loc), x, y);
        checkError();
    }
}

pub fn programUniform3f(program: types.Program, location: ?u32, x: f32, y: f32, z: f32) void {
    if (location) |loc| {
        c.glProgramUniform3f(@enumToInt(program), @intCast(types.Int, loc), x, y, z);
        checkError();
    }
}

pub fn programUniform4f(program: types.Program, location: ?u32, x: f32, y: f32, z: f32, w: f32) void {
    if (location) |loc| {
        c.glProgramUniform4f(@enumToInt(program), @intCast(types.Int, loc), x, y, z, w);
        checkError();
    }
}

pub fn programUniformMatrix4(program: types.Program, location: ?u32, transpose: bool, items: []const [4][4]f32) void {
    if (location) |loc| {
        c.glProgramUniformMatrix4fv(
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
        c.glUniform1f(@intCast(types.Int, loc), v0);
        checkError();
    }
}

pub fn uniform2f(location: ?u32, v0: f32, v1: f32) void {
    if (location) |loc| {
        c.glUniform2f(@intCast(types.Int, loc), v0, v1);
        checkError();
    }
}

pub fn uniform3f(location: ?u32, v0: f32, v1: f32, v2: f32) void {
    if (location) |loc| {
        c.glUniform3f(@intCast(types.Int, loc), v0, v1, v2);
        checkError();
    }
}

pub fn uniform4f(location: ?u32, v0: f32, v1: f32, v2: f32, v3: f32) void {
    if (location) |loc| {
        c.glUniform4f(@intCast(types.Int, loc), v0, v1, v2, v3);
        checkError();
    }
}

pub fn uniform1i(location: ?u32, v0: i32) void {
    if (location) |loc| {
        c.glUniform1i(@intCast(types.Int, loc), v0);
        checkError();
    }
}

pub fn uniform2i(location: ?u32, v0: i32, v1: i32) void {
    if (location) |loc| {
        c.glUniform2i(@intCast(types.Int, loc), v0, v1);
        checkError();
    }
}

pub fn uniform3i(location: ?u32, v0: i32, v1: i32, v2: i32) void {
    if (location) |loc| {
        c.glUniform3i(@intCast(types.Int, loc), v0, v1, v2);
        checkError();
    }
}

pub fn uniform4i(location: ?u32, v0: i32, v1: i32, v2: i32, v3: i32) void {
    if (location) |loc| {
        c.glUniform4i(@intCast(types.Int, loc), v0, v1, v2, v3);
        checkError();
    }
}

pub fn uniform1ui(location: ?u32, v0: u32) void {
    if (location) |loc| {
        c.glUniform1ui(@intCast(types.Int, loc), v0);
        checkError();
    }
}

pub fn uniform2ui(location: ?u32, v0: u32, v1: u32) void {
    if (location) |loc| {
        c.glUniform2ui(@intCast(types.Int, loc), v0, v1);
        checkError();
    }
}

pub fn uniform3ui(location: ?u32, v0: u32, v1: u32, v2: u32) void {
    if (location) |loc| {
        c.glUniform3ui(@intCast(types.Int, loc), v0, v1, v2);
        checkError();
    }
}

pub fn uniform4ui(location: ?u32, v0: u32, v1: u32, v2: u32, v3: u32) void {
    if (location) |loc| {
        c.glUniform4ui(@intCast(types.Int, loc), v0, v1, v2, v3);
        checkError();
    }
}

pub fn uniform1fv(location: ?u32, items: []const f32) void {
    if (location) |loc| {
        c.glUniform1fv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const f32, items.ptr));
        checkError();
    }
}

pub fn uniform2fv(location: ?u32, items: []const [2]f32) void {
    if (location) |loc| {
        c.glUniform2fv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const f32, items.ptr));
        checkError();
    }
}

pub fn uniform3fv(location: ?u32, items: []const [3]f32) void {
    if (location) |loc| {
        c.glUniform3fv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const f32, items.ptr));
        checkError();
    }
}

pub fn uniform4fv(location: ?u32, items: []const [4]f32) void {
    if (location) |loc| {
        c.glUniform4fv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const f32, items.ptr));
        checkError();
    }
}

pub fn uniform1iv(location: ?u32, items: []const i32) void {
    if (location) |loc| {
        c.glUniform1iv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const i32, items.ptr));
        checkError();
    }
}

pub fn uniform2iv(location: ?u32, items: []const [2]i32) void {
    if (location) |loc| {
        c.glUniform2iv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const i32, items.ptr));
        checkError();
    }
}

pub fn uniform3iv(location: ?u32, items: []const [3]i32) void {
    if (location) |loc| {
        c.glUniform3iv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const i32, items.ptr));
        checkError();
    }
}

pub fn uniform4iv(location: ?u32, items: []const [4]i32) void {
    if (location) |loc| {
        c.glUniform4iv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const i32, items.ptr));
        checkError();
    }
}

pub fn uniform1uiv(location: ?u32, items: []const u32) void {
    if (location) |loc| {
        c.glUniform1uiv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const u32, items.ptr));
        checkError();
    }
}

pub fn uniform2uiv(location: ?u32, items: []const [2]u32) void {
    if (location) |loc| {
        c.glUniform2uiv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const u32, items.ptr));
        checkError();
    }
}

pub fn uniform3uiv(location: ?u32, items: []const [3]u32) void {
    if (location) |loc| {
        c.glUniform3uiv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const u32, items.ptr));
        checkError();
    }
}

pub fn uniform4uiv(location: ?u32, items: []const [4]u32) void {
    if (location) |loc| {
        c.glUniform4uiv(@intCast(types.Int, loc), cs2gl(items.len), @ptrCast(*const u32, items.ptr));
        checkError();
    }
}

pub fn uniform1i64(location: ?u32, v0: i64) void {
    if (location) |loc| {
        c.glUniform1i64ARB(@intCast(types.Int, loc), v0);
        checkError();
    }
}

pub fn uniform2i64(location: ?u32, v0: i64, v1: i64) void {
    if (location) |loc| {
        c.glUniform2i64ARB(@intCast(types.Int, loc), v0, v1);
        checkError();
    }
}

pub fn uniform3i64(location: ?u32, v0: i64, v1: i64, v2: i64) void {
    if (location) |loc| {
        c.glUniform3i64ARB(@intCast(types.Int, loc), v0, v1, v2);
        checkError();
    }
}

pub fn uniform4i64(location: ?u32, v0: i64, v1: i64, v2: i64, v3: i64) void {
    if (location) |loc| {
        c.glUniform4i64ARB(@intCast(types.Int, loc), v0, v1, v2, v3);
        checkError();
    }
}

pub fn uniformMatrix4fv(location: ?u32, transpose: bool, items: []const [4][4]f32) void {
    if (location) |loc| {
        c.glUniformMatrix4fv(
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
    points = c.GL_POINTS,
    line_strip = c.GL_LINE_STRIP,
    line_loop = c.GL_LINE_LOOP,
    lines = c.GL_LINES,
    line_strip_adjacency = c.GL_LINE_STRIP_ADJACENCY,
    lines_adjacency = c.GL_LINES_ADJACENCY,
    triangle_strip = c.GL_TRIANGLE_STRIP,
    triangle_fan = c.GL_TRIANGLE_FAN,
    triangles = c.GL_TRIANGLES,
    triangle_strip_adjacency = c.GL_TRIANGLE_STRIP_ADJACENCY,
    triangles_adjacency = c.GL_TRIANGLES_ADJACENCY,
    patches = c.GL_PATCHES,
};

pub fn drawArrays(primitiveType: PrimitiveType, first: usize, count: usize) void {
    c.glDrawArrays(@enumToInt(primitiveType), cs2gl(first), cs2gl(count));
    checkError();
}

pub fn drawArraysInstanced(primitiveType: PrimitiveType, first: usize, count: usize, instanceCount: usize) void {
    c.glDrawArraysInstanced(@enumToInt(primitiveType), cs2gl(first), cs2gl(count), cs2gl(instanceCount));
    checkError();
}

pub const ElementType = enum(types.Enum) {
    u8 = c.GL_UNSIGNED_BYTE,
    u16 = c.GL_UNSIGNED_SHORT,
    u32 = c.GL_UNSIGNED_INT,
};

pub fn drawElements(primitiveType: PrimitiveType, count: usize, element_type: ElementType, indices: usize) void {
    c.glDrawElements(
        @enumToInt(primitiveType),
        cs2gl(count),
        @enumToInt(element_type),
        @intToPtr(*allowzero const anyopaque, indices),
    );
    checkError();
}

pub fn drawElementsInstanced(primitiveType: PrimitiveType, count: usize, element_type: ElementType, indices: usize, instance_count: usize) void {
    c.glDrawElementsInstanced(
        @enumToInt(primitiveType),
        cs2gl(count),
        @enumToInt(element_type),
        @intToPtr(*allowzero const anyopaque, indices),
        cs2gl(instance_count),
    );
    checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Status Control

pub const Capabilities = enum(types.Enum) {
    blend = c.GL_BLEND,
    // clip_distance = c.GL_CLIP_DISTANCE,
    color_logic_op = c.GL_COLOR_LOGIC_OP,
    cull_face = c.GL_CULL_FACE,
    debug_output = c.GL_DEBUG_OUTPUT,
    debug_output_synchronous = c.GL_DEBUG_OUTPUT_SYNCHRONOUS,
    depth_clamp = c.GL_DEPTH_CLAMP,
    depth_test = c.GL_DEPTH_TEST,
    dither = c.GL_DITHER,
    framebuffer_srgb = c.GL_FRAMEBUFFER_SRGB,
    line_smooth = c.GL_LINE_SMOOTH,
    multisample = c.GL_MULTISAMPLE,
    polygon_offset_fill = c.GL_POLYGON_OFFSET_FILL,
    polygon_offset_line = c.GL_POLYGON_OFFSET_LINE,
    polygon_offset_point = c.GL_POLYGON_OFFSET_POINT,
    polygon_smooth = c.GL_POLYGON_SMOOTH,
    primitive_restart = c.GL_PRIMITIVE_RESTART,
    primitive_restart_fixed_index = c.GL_PRIMITIVE_RESTART_FIXED_INDEX,
    rasterizer_discard = c.GL_RASTERIZER_DISCARD,
    sample_alpha_to_coverage = c.GL_SAMPLE_ALPHA_TO_COVERAGE,
    sample_alpha_to_one = c.GL_SAMPLE_ALPHA_TO_ONE,
    sample_coverage = c.GL_SAMPLE_COVERAGE,
    sample_shading = c.GL_SAMPLE_SHADING,
    sample_mask = c.GL_SAMPLE_MASK,
    scissor_test = c.GL_SCISSOR_TEST,
    stencil_test = c.GL_STENCIL_TEST,
    texture_cube_map_seamless = c.GL_TEXTURE_CUBE_MAP_SEAMLESS,
    program_point_size = c.GL_PROGRAM_POINT_SIZE,
};

pub fn enable(cap: Capabilities) void {
    c.glEnable(@enumToInt(cap));
    checkError();
}

pub fn disable(cap: Capabilities) void {
    c.glDisable(@enumToInt(cap));
    checkError();
}

pub fn enableI(cap: Capabilities, index: u32) void {
    c.glEnablei(@enumToInt(cap), index);
    checkError();
}

pub fn disableI(cap: Capabilities, index: u32) void {
    c.glDisablei(@enumToInt(cap), index);
    checkError();
}

pub const ClipOrigin = enum(types.Enum) {
    lower_left = c.GL_LOWER_LEFT,
    upper_left = c.GL_UPPER_LEFT,
};
pub const ClipDepth = enum(types.Enum) {
    negative_one_to_one = c.GL_NEGATIVE_ONE_TO_ONE,
    zero_to_one = c.GL_ZERO_TO_ONE,
};

pub fn clipControl(origin: ClipOrigin, depth: ClipDepth) void {
    c.glClipControl(@enumToInt(origin), @enumToInt(depth));
    checkError();
}

pub const CullMode = enum(types.Enum) {
    front = c.GL_FRONT,
    back = c.GL_BACK,
    front_and_back = c.GL_FRONT_AND_BACK,
};

pub fn cullFace(mode: CullMode) void {
    c.glCullFace(@enumToInt(mode));
    checkError();
}

pub fn depthMask(enabled: bool) void {
    c.glDepthMask(if (enabled) c.GL_TRUE else c.GL_FALSE);
    checkError();
}

pub const DepthFunc = enum(types.Enum) {
    never = c.GL_NEVER,
    less = c.GL_LESS,
    equal = c.GL_EQUAL,
    less_or_equal = c.GL_LEQUAL,
    greater = c.GL_GREATER,
    not_equal = c.GL_NOTEQUAL,
    greator_or_equal = c.GL_GEQUAL,
    always = c.GL_ALWAYS,
};

pub fn depthFunc(func: DepthFunc) void {
    c.glDepthFunc(@enumToInt(func));
    checkError();
}

pub fn stencilMask(mask: u32) void {
    c.glStencilMask(mask);
    checkError();
}

pub const StencilFunc = enum(types.Enum) {
    never = c.GL_NEVER,
    less = c.GL_LESS,
    equal = c.GL_EQUAL,
    less_or_equal = c.GL_LEQUAL,
    greater = c.GL_GREATER,
    not_equal = c.GL_NOTEQUAL,
    greator_or_equal = c.GL_GEQUAL,
    always = c.GL_ALWAYS,
};

pub fn stencilFunc(func: StencilFunc, ref: i32, mask: u32) void {
    c.glStencilFunc(@enumToInt(func), ref, mask);
    checkError();
}

pub const StencilOp = enum(types.Enum) {
    keep = c.GL_KEEP,
    zero = c.GL_ZERO,
    replace = c.GL_REPLACE,
    incr = c.GL_INCR,
    incr_wrap = c.GL_INCR_WRAP,
    decr = c.GL_DECR,
    decr_wrap = c.GL_DECR_WRAP,
    invert = c.GL_INVERT,
};

pub fn stencilOp(sfail: StencilOp, dpfail: StencilOp, dppass: StencilOp) void {
    c.glStencilOp(@enumToInt(sfail), @enumToInt(dpfail), @enumToInt(dppass));
    checkError();
}

pub const BlendFactor = enum(types.Enum) {
    zero = c.GL_ZERO,
    one = c.GL_ONE,
    src_color = c.GL_SRC_COLOR,
    one_minus_src_color = c.GL_ONE_MINUS_SRC_COLOR,
    dst_color = c.GL_DST_COLOR,
    one_minus_dst_color = c.GL_ONE_MINUS_DST_COLOR,
    src_alpha = c.GL_SRC_ALPHA,
    one_minus_src_alpha = c.GL_ONE_MINUS_SRC_ALPHA,
    dst_alpha = c.GL_DST_ALPHA,
    one_minus_dst_alpha = c.GL_ONE_MINUS_DST_ALPHA,
    constant_color = c.GL_CONSTANT_COLOR,
    one_minus_constant_color = c.GL_ONE_MINUS_CONSTANT_COLOR,
    constant_alpha = c.GL_CONSTANT_ALPHA,
    one_minus_constant_alpha = c.GL_ONE_MINUS_CONSTANT_ALPHA,
};

pub fn blendFunc(sfactor: BlendFactor, dfactor: BlendFactor) void {
    c.glBlendFunc(@enumToInt(sfactor), @enumToInt(dfactor));
    checkError();
}

pub fn blendFuncSeparate(srcRGB: BlendFactor, dstRGB: BlendFactor, srcAlpha: BlendFactor, dstAlpha: BlendFactor) void {
    c.glBlendFuncSeparate(@enumToInt(srcRGB), @enumToInt(dstRGB), @enumToInt(srcAlpha), @enumToInt(dstAlpha));
    checkError();
}

pub const DrawMode = enum(types.Enum) {
    point = c.GL_POINT,
    line = c.GL_LINE,
    fill = c.GL_FILL,
};

pub fn polygonMode(face: CullMode, mode: DrawMode) void {
    c.glPolygonMode(@enumToInt(face), @enumToInt(mode));
    checkError();
}

pub fn polygonOffset(factor: f32, units: f32) void {
    c.glPolygonOffset(factor, units);
    checkError();
}

pub fn pointSize(size: f32) void {
    c.glPointSize(size);
    checkError();
}

pub fn lineWidth(size: f32) void {
    c.glLineWidth(size);
    checkError();
}

pub const TextureTarget = enum(types.Enum) {
    @"1d" = c.GL_TEXTURE_1D,
    @"2d" = c.GL_TEXTURE_2D,
    @"3d" = c.GL_TEXTURE_3D,
    @"1d_array" = c.GL_TEXTURE_1D_ARRAY,
    @"2d_array" = c.GL_TEXTURE_2D_ARRAY,
    rectangle = c.GL_TEXTURE_RECTANGLE,
    cube_map = c.GL_TEXTURE_CUBE_MAP,
    cube_map_array = c.GL_TEXTURE_CUBE_MAP_ARRAY,
    buffer = c.GL_TEXTURE_BUFFER,
    @"2d_multisample" = c.GL_TEXTURE_2D_MULTISAMPLE,
    @"2d_multisample_array" = c.GL_TEXTURE_2D_MULTISAMPLE_ARRAY,
};

pub fn genTexture() types.Texture {
    var tex_name: types.UInt = undefined;
    c.glGenTextures(1, &tex_name);
    checkError();
    return @intToEnum(types.Texture, tex_name);
}

pub fn createTexture(texture_target: TextureTarget) types.Texture {
    var tex_name: types.UInt = undefined;

    c.glCreateTextures(@enumToInt(texture_target), 1, &tex_name);
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
    c.glDeleteTextures(1, &id);
}

pub fn generateMipmap(target: TextureTarget) void {
    c.glGenerateMipmap(@enumToInt(target));
    checkError();
}

pub fn generateTextureMipmap(texture: types.Texture) void {
    c.glGenerateTextureMipmap(@enumToInt(texture));
    checkError();
}

pub fn bindTextureUnit(texture: types.Texture, unit: u32) void {
    c.glBindTextureUnit(unit, @enumToInt(texture));
    checkError();
}

pub fn bindTexture(texture: types.Texture, target: TextureTarget) void {
    c.glBindTexture(@enumToInt(target), @enumToInt(texture));
    checkError();
}

pub fn activeTexture(texture_unit: TextureUnit) void {
    c.glActiveTexture(@enumToInt(texture_unit));
    checkError();
}

pub const TextureUnit = enum(types.Enum) {
    texture_0 = c.GL_TEXTURE0,
    texture_1 = c.GL_TEXTURE1,
    texture_2 = c.GL_TEXTURE2,
    texture_3 = c.GL_TEXTURE3,
    texture_4 = c.GL_TEXTURE4,
    texture_5 = c.GL_TEXTURE5,
    texture_6 = c.GL_TEXTURE6,
    texture_7 = c.GL_TEXTURE7,
    _,

    pub fn unit(id: types.Enum) TextureUnit {
        return @intToEnum(TextureUnit, @enumToInt(TextureUnit.texture_0) + id);
    }
};

pub const TextureParameter = enum(types.Enum) {
    depth_stencil_texture_mode = c.GL_DEPTH_STENCIL_TEXTURE_MODE,
    base_level = c.GL_TEXTURE_BASE_LEVEL,
    compare_func = c.GL_TEXTURE_COMPARE_FUNC,
    compare_mode = c.GL_TEXTURE_COMPARE_MODE,
    lod_bias = c.GL_TEXTURE_LOD_BIAS,
    min_filter = c.GL_TEXTURE_MIN_FILTER,
    mag_filter = c.GL_TEXTURE_MAG_FILTER,
    min_lod = c.GL_TEXTURE_MIN_LOD,
    max_lod = c.GL_TEXTURE_MAX_LOD,
    max_level = c.GL_TEXTURE_MAX_LEVEL,
    swizzle_r = c.GL_TEXTURE_SWIZZLE_R,
    swizzle_g = c.GL_TEXTURE_SWIZZLE_G,
    swizzle_b = c.GL_TEXTURE_SWIZZLE_B,
    swizzle_a = c.GL_TEXTURE_SWIZZLE_A,
    wrap_s = c.GL_TEXTURE_WRAP_S,
    wrap_t = c.GL_TEXTURE_WRAP_T,
    wrap_r = c.GL_TEXTURE_WRAP_R,
};

pub fn TextureParameterType(comptime param: TextureParameter) type {
    // see https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glTexParameter.xhtml
    return switch (param) {
        .wrap_s, .wrap_t, .wrap_r => enum(types.Int) {
            clamp_to_edge = c.GL_CLAMP_TO_EDGE,
            clamp_to_border = c.GL_CLAMP_TO_BORDER,
            mirrored_repeat = c.GL_MIRRORED_REPEAT,
            repeat = c.GL_REPEAT,
            mirror_clamp_to_edge = c.GL_MIRROR_CLAMP_TO_EDGE,
        },
        .mag_filter => enum(types.Int) {
            nearest = c.GL_NEAREST,
            linear = c.GL_LINEAR,
        },
        .min_filter => enum(types.Int) {
            nearest = c.GL_NEAREST,
            linear = c.GL_LINEAR,
            nearest_mipmap_nearest = c.GL_NEAREST_MIPMAP_NEAREST,
            linear_mipmap_nearest = c.GL_LINEAR_MIPMAP_NEAREST,
            nearest_mipmap_linear = c.GL_NEAREST_MIPMAP_LINEAR,
            linear_mipmap_linear = c.GL_LINEAR_MIPMAP_LINEAR,
        },
        .compare_mode => enum(types.Int) {
            none = c.GL_NONE,
        },
        else => @compileError("textureParameter not implemented yet for " ++ @tagName(param)),
    };
}

pub fn texParameter(target: TextureTarget, comptime parameter: TextureParameter, value: TextureParameterType(parameter)) void {
    const T = TextureParameterType(parameter);
    const info = @typeInfo(T);
    if (info == .Enum) {
        c.glTexParameteri(@enumToInt(target), @enumToInt(parameter), @enumToInt(value));
    } else {
        @compileError(@tagName(info) ++ " is not supported yet by texParameter");
    }
    checkError();
}

pub fn textureParameter(texture: types.Texture, comptime parameter: TextureParameter, value: TextureParameterType(parameter)) void {
    const T = TextureParameterType(parameter);
    const info = @typeInfo(T);

    if (info == .Enum) {
        c.glTextureParameteri(@enumToInt(texture), @enumToInt(parameter), @enumToInt(value));
    } else {
        @compileError(@tagName(info) ++ " is not supported yet by textureParameter");
    }
    checkError();
}

pub const TextureInternalFormat = enum(types.Enum) {
    r8 = c.GL_R8,
    r8_snorm = c.GL_R8_SNORM,
    r16 = c.GL_R16,
    r16_snorm = c.GL_R16_SNORM,
    rg8 = c.GL_RG8,
    rg8_snorm = c.GL_RG8_SNORM,
    rg16 = c.GL_RG16,
    rg16_snorm = c.GL_RG16_SNORM,
    r3_g3_b2 = c.GL_R3_G3_B2,
    rgb4 = c.GL_RGB4,
    rgb5 = c.GL_RGB5,
    rgb8 = c.GL_RGB8,
    rgb8_snorm = c.GL_RGB8_SNORM,
    rgb10 = c.GL_RGB10,
    rgb12 = c.GL_RGB12,
    rgb16_snorm = c.GL_RGB16_SNORM,
    rgba2 = c.GL_RGBA2,
    rgba4 = c.GL_RGBA4,
    rgb5_a1 = c.GL_RGB5_A1,
    rgba8 = c.GL_RGBA8,
    rgba8_snorm = c.GL_RGBA8_SNORM,
    rgb10_a2 = c.GL_RGB10_A2,
    rgb10_a2ui = c.GL_RGB10_A2UI,
    rgba12 = c.GL_RGBA12,
    rgba16 = c.GL_RGBA16,
    srgb8 = c.GL_SRGB8,
    srgb8_alpha8 = c.GL_SRGB8_ALPHA8,
    r16f = c.GL_R16F,
    rg16f = c.GL_RG16F,
    rgb16f = c.GL_RGB16F,
    rgba16f = c.GL_RGBA16F,
    r32f = c.GL_R32F,
    rg32f = c.GL_RG32F,
    rgb32f = c.GL_RGB32F,
    rgba32f = c.GL_RGBA32F,
    r11f_g11f_b10f = c.GL_R11F_G11F_B10F,
    rgb9_e5 = c.GL_RGB9_E5,
    r8i = c.GL_R8I,
    r8ui = c.GL_R8UI,
    r16i = c.GL_R16I,
    r16ui = c.GL_R16UI,
    r32i = c.GL_R32I,
    r32ui = c.GL_R32UI,
    rg8i = c.GL_RG8I,
    rg8ui = c.GL_RG8UI,
    rg16i = c.GL_RG16I,
    rg16ui = c.GL_RG16UI,
    rg32i = c.GL_RG32I,
    rg32ui = c.GL_RG32UI,
    rgb8i = c.GL_RGB8I,
    rgb8ui = c.GL_RGB8UI,
    rgb16i = c.GL_RGB16I,
    rgb16ui = c.GL_RGB16UI,
    rgb32i = c.GL_RGB32I,
    rgb32ui = c.GL_RGB32UI,
    rgba8i = c.GL_RGBA8I,
    rgba8ui = c.GL_RGBA8UI,
    rgba16i = c.GL_RGBA16I,
    rgba16ui = c.GL_RGBA16UI,
    rgba32i = c.GL_RGBA32I,
    rgba32ui = c.GL_RGBA32UI,
    depth_component16 = c.GL_DEPTH_COMPONENT16,
};

pub fn textureStorage2D(
    texture: types.Texture,
    levels: usize,
    internalformat: TextureInternalFormat,
    width: usize,
    height: usize,
) void {
    c.glTextureStorage2D(
        @enumToInt(texture),
        @intCast(types.SizeI, levels),
        @enumToInt(internalformat),
        @intCast(types.SizeI, width),
        @intCast(types.SizeI, height),
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
    c.glTextureStorage3D(
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
    red = c.GL_RED,
    rg = c.GL_RG,
    rgb = c.GL_RGB,
    bgr = c.GL_BGR,
    rgba = c.GL_RGBA,
    bgra = c.GL_BGRA,
    depth_component = c.GL_DEPTH_COMPONENT,
    stencil_index = c.GL_STENCIL_INDEX,
    luminance = c.GL_LUMINANCE,

    red_integer = c.GL_RED_INTEGER,
    rg_integer = c.GL_RG_INTEGER,
    rgb_integer = c.GL_RGB_INTEGER,
    bgr_integer = c.GL_BGR_INTEGER,
    rgba_integer = c.GL_RGBA_INTEGER,
    bgra_integer = c.GL_BGRA_INTEGER,
};

pub const PixelType = enum(types.Enum) {
    unsigned_byte = c.GL_UNSIGNED_BYTE,
    byte = c.GL_BYTE,
    unsigned_short = c.GL_UNSIGNED_SHORT,
    short = c.GL_SHORT,
    unsigned_int = c.GL_UNSIGNED_INT,
    int = c.GL_INT,
    float = c.GL_FLOAT,
    unsigned_byte_3_3_2 = c.GL_UNSIGNED_BYTE_3_3_2,
    unsigned_byte_2_3_3_rev = c.GL_UNSIGNED_BYTE_2_3_3_REV,
    unsigned_short_5_6_5 = c.GL_UNSIGNED_SHORT_5_6_5,
    unsigned_short_5_6_5_rev = c.GL_UNSIGNED_SHORT_5_6_5_REV,
    unsigned_short_4_4_4_4 = c.GL_UNSIGNED_SHORT_4_4_4_4,
    unsigned_short_4_4_4_4_rev = c.GL_UNSIGNED_SHORT_4_4_4_4_REV,
    unsigned_short_5_5_5_1 = c.GL_UNSIGNED_SHORT_5_5_5_1,
    unsigned_short_1_5_5_5_rev = c.GL_UNSIGNED_SHORT_1_5_5_5_REV,
    unsigned_int_8_8_8_8 = c.GL_UNSIGNED_INT_8_8_8_8,
    unsigned_int_8_8_8_8_rev = c.GL_UNSIGNED_INT_8_8_8_8_REV,
    unsigned_int_10_10_10_2 = c.GL_UNSIGNED_INT_10_10_10_2,
    unsigned_int_2_10_10_10_rev = c.GL_UNSIGNED_INT_2_10_10_10_REV,
};

pub fn textureImage2D(
    texture: TextureTarget,
    level: usize,
    pixel_internal_format: PixelFormat,
    width: usize,
    height: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    data: ?[*]const u8,
) void {
    c.glTexImage2D(
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
    c.glTexSubImage2D(
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
    c.glTextureSubImage2D(
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
    c.glTextureSubImage3D(
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

pub const PixelStoreParameter = enum(types.Enum) {
    pack_swap_bytes = c.GL_PACK_SWAP_BYTES,
    pack_lsb_first = c.GL_PACK_LSB_FIRST,
    pack_row_length = c.GL_PACK_ROW_LENGTH,
    pack_image_height = c.GL_PACK_IMAGE_HEIGHT,
    pack_skip_pixels = c.GL_PACK_SKIP_PIXELS,
    pack_skip_rows = c.GL_PACK_SKIP_ROWS,
    pack_skip_images = c.GL_PACK_SKIP_IMAGES,
    pack_alignment = c.GL_PACK_ALIGNMENT,

    unpack_swap_bytes = c.GL_UNPACK_SWAP_BYTES,
    unpack_lsb_first = c.GL_UNPACK_LSB_FIRST,
    unpack_row_length = c.GL_UNPACK_ROW_LENGTH,
    unpack_image_height = c.GL_UNPACK_IMAGE_HEIGHT,
    unpack_skip_pixels = c.GL_UNPACK_SKIP_PIXELS,
    unpack_skip_rows = c.GL_UNPACK_SKIP_ROWS,
    unpack_skip_images = c.GL_UNPACK_SKIP_IMAGES,
    unpack_alignment = c.GL_UNPACK_ALIGNMENT,
};

pub fn pixelStore(param: PixelStoreParameter, value: usize) void {
    c.glPixelStorei(@enumToInt(param), @intCast(types.Int, value));
    checkError();
}

pub fn viewport(x: i32, y: i32, width: usize, height: usize) void {
    c.glViewport(@intCast(types.Int, x), @intCast(types.Int, y), @intCast(types.SizeI, width), @intCast(types.SizeI, height));
    checkError();
}

pub fn scissor(x: i32, y: i32, width: usize, height: usize) void {
    c.glScissor(@intCast(types.Int, x), @intCast(types.Int, y), @intCast(types.SizeI, width), @intCast(types.SizeI, height));
    checkError();
}

pub const FramebufferTarget = enum(types.Enum) {
    buffer = c.GL_FRAMEBUFFER,
};

pub const Framebuffer = enum(types.UInt) {
    invalid = 0,
    _,

    pub const gen = genFramebuffer;
    pub const create = createFramebuffer;
    pub const delete = deleteFramebuffer;
    pub const bind = bindFrameBuffer;
    pub const texture = framebufferTexture;
    pub const texture2D = framebufferTexture2D;
    pub const checkStatus = checkFramebufferStatus;
};

pub fn createFramebuffer() Framebuffer {
    var fb_name: types.UInt = undefined;
    c.glCreateFramebuffers(1, &fb_name);
    checkError();
    const framebuffer = @intToEnum(Framebuffer, fb_name);
    if (framebuffer == .invalid) {
        checkError();
        unreachable;
    }
    return framebuffer;
}

pub fn genFramebuffer() Framebuffer {
    var fb_name: types.UInt = undefined;
    c.glGenFramebuffers(1, &fb_name);
    checkError();
    const framebuffer = @intToEnum(Framebuffer, fb_name);
    if (framebuffer == .invalid) unreachable;
    return framebuffer;
}

pub fn deleteFramebuffer(buf: Framebuffer) void {
    var fb_name = @enumToInt(buf);
    c.glDeleteFramebuffers(1, &fb_name);
}

pub fn bindFrameBuffer(buf: Framebuffer, target: FramebufferTarget) void {
    c.glBindFramebuffer(@enumToInt(target), @enumToInt(buf));
    checkError();
}

pub const FramebufferAttachment = enum(types.Enum) {
    color0 = c.GL_COLOR_ATTACHMENT0,
    color1 = c.GL_COLOR_ATTACHMENT1,
    color2 = c.GL_COLOR_ATTACHMENT2,
    color3 = c.GL_COLOR_ATTACHMENT3,
    color4 = c.GL_COLOR_ATTACHMENT4,
    color5 = c.GL_COLOR_ATTACHMENT5,
    color6 = c.GL_COLOR_ATTACHMENT6,
    color7 = c.GL_COLOR_ATTACHMENT7,
    depth = c.GL_DEPTH_ATTACHMENT,
    stencil = c.GL_STENCIL_ATTACHMENT,
    depth_stencil = c.GL_DEPTH_STENCIL_ATTACHMENT,
    max_color = c.GL_MAX_COLOR_ATTACHMENTS,
};

pub fn framebufferTexture(buffer: Framebuffer, target: FramebufferTarget, attachment: FramebufferAttachment, texture: types.Texture, level: i32) void {
    buffer.bind(.buffer);
    c.glFramebufferTexture(@enumToInt(target), @enumToInt(attachment), @intCast(types.UInt, @enumToInt(texture)), @intCast(types.Int, level));
    checkError();
}

pub const FramebufferTextureTarget = enum(types.Enum) {
    @"1d" = c.GL_TEXTURE_1D,
    @"2d" = c.GL_TEXTURE_2D,
    @"3d" = c.GL_TEXTURE_3D,
    @"1d_array" = c.GL_TEXTURE_1D_ARRAY,
    @"2d_array" = c.GL_TEXTURE_2D_ARRAY,
    rectangle = c.GL_TEXTURE_RECTANGLE,
    cube_map_positive_x = c.GL_TEXTURE_CUBE_MAP_POSITIVE_X,
    cube_map_negative_x = c.GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
    cube_map_positive_y = c.GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
    cube_map_negative_y = c.GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
    cube_map_positive_z = c.GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
    cube_map_negative_z = c.GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
    buffer = c.GL_TEXTURE_BUFFER,
    @"2d_multisample" = c.GL_TEXTURE_2D_MULTISAMPLE,
    @"2d_multisample_array" = c.GL_TEXTURE_2D_MULTISAMPLE_ARRAY,
};

pub fn framebufferTexture2D(buffer: Framebuffer, target: FramebufferTarget, attachment: FramebufferAttachment, textarget: FramebufferTextureTarget, texture: types.Texture, level: i32) void {
    buffer.bind(.buffer);
    c.glFramebufferTexture2D(@enumToInt(target), @enumToInt(attachment), @enumToInt(textarget), @intCast(types.UInt, @enumToInt(texture)), @intCast(types.Int, level));
    checkError();
}

const FramebufferStatus = enum(types.UInt) {
    complete = c.GL_FRAMEBUFFER_COMPLETE,
};

pub fn checkFramebufferStatus(target: FramebufferTarget) FramebufferStatus {
    const status = @intToEnum(FramebufferStatus, c.glCheckFramebufferStatus(@enumToInt(target)));
    return status;
}

pub fn drawBuffers(bufs: []const FramebufferAttachment) void {
    c.glDrawBuffers(cs2gl(bufs.len), @ptrCast([*]const types.UInt, bufs.ptr));
}

///////////////////////////////////////////////////////////////////////////////
// Parameters
pub const Parameter = enum(types.Enum) {
    active_texture = c.GL_ACTIVE_TEXTURE,
    aliased_line_width_range = c.GL_ALIASED_LINE_WIDTH_RANGE,
    array_buffer_binding = c.GL_ARRAY_BUFFER_BINDING,
    blend = c.GL_BLEND,
    blend_color = c.GL_BLEND_COLOR,
    blend_dst_alpha = c.GL_BLEND_DST_ALPHA,
    blend_dst_rgb = c.GL_BLEND_DST_RGB,
    blend_equation_alpha = c.GL_BLEND_EQUATION_ALPHA,
    blend_equation_rgb = c.GL_BLEND_EQUATION_RGB,
    blend_src_alpha = c.GL_BLEND_SRC_ALPHA,
    blend_src_rgb = c.GL_BLEND_SRC_RGB,
    color_clear_value = c.GL_COLOR_CLEAR_VALUE,
    color_logic_op = c.GL_COLOR_LOGIC_OP,
    color_writemask = c.GL_COLOR_WRITEMASK,
    compressed_texture_formats = c.GL_COMPRESSED_TEXTURE_FORMATS,
    context_flags = c.GL_CONTEXT_FLAGS,
    cull_face = c.GL_CULL_FACE,
    current_program = c.GL_CURRENT_PROGRAM,
    depth_clear_value = c.GL_DEPTH_CLEAR_VALUE,
    depth_func = c.GL_DEPTH_FUNC,
    depth_range = c.GL_DEPTH_RANGE,
    depth_test = c.GL_DEPTH_TEST,
    depth_writemask = c.GL_DEPTH_WRITEMASK,
    dither = c.GL_DITHER,
    doublebuffer = c.GL_DOUBLEBUFFER,
    draw_buffer = c.GL_DRAW_BUFFER,
    draw_buffer0 = c.GL_DRAW_BUFFER0,
    draw_buffer1 = c.GL_DRAW_BUFFER1,
    draw_buffer2 = c.GL_DRAW_BUFFER2,
    draw_buffer3 = c.GL_DRAW_BUFFER3,
    draw_buffer4 = c.GL_DRAW_BUFFER4,
    draw_buffer5 = c.GL_DRAW_BUFFER5,
    draw_buffer6 = c.GL_DRAW_BUFFER6,
    draw_buffer7 = c.GL_DRAW_BUFFER7,
    draw_buffer8 = c.GL_DRAW_BUFFER8,
    draw_buffer9 = c.GL_DRAW_BUFFER9,
    draw_buffer10 = c.GL_DRAW_BUFFER10,
    draw_buffer11 = c.GL_DRAW_BUFFER11,
    draw_buffer12 = c.GL_DRAW_BUFFER12,
    draw_buffer13 = c.GL_DRAW_BUFFER13,
    draw_buffer14 = c.GL_DRAW_BUFFER14,
    draw_buffer15 = c.GL_DRAW_BUFFER15,
    draw_framebuffer_binding = c.GL_DRAW_FRAMEBUFFER_BINDING,
    element_array_buffer_binding = c.GL_ELEMENT_ARRAY_BUFFER_BINDING,
    fragment_shader_derivative_hint = c.GL_FRAGMENT_SHADER_DERIVATIVE_HINT,
    line_smooth = c.GL_LINE_SMOOTH,
    line_smooth_hint = c.GL_LINE_SMOOTH_HINT,
    line_width = c.GL_LINE_WIDTH,
    logic_op_mode = c.GL_LOGIC_OP_MODE,
    major_version = c.GL_MAJOR_VERSION,
    max_3d_texture_size = c.GL_MAX_3D_TEXTURE_SIZE,
    max_array_texture_layers = c.GL_MAX_ARRAY_TEXTURE_LAYERS,
    max_clip_distances = c.GL_MAX_CLIP_DISTANCES,
    max_color_texture_samples = c.GL_MAX_COLOR_TEXTURE_SAMPLES,
    max_combined_fragment_uniform_components = c.GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS,
    max_combined_geometry_uniform_components = c.GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS,
    max_combined_texture_image_units = c.GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,
    max_combined_uniform_blocks = c.GL_MAX_COMBINED_UNIFORM_BLOCKS,
    max_combined_vertex_uniform_components = c.GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS,
    max_cube_map_texture_size = c.GL_MAX_CUBE_MAP_TEXTURE_SIZE,
    max_depth_texture_samples = c.GL_MAX_DEPTH_TEXTURE_SAMPLES,
    max_draw_buffers = c.GL_MAX_DRAW_BUFFERS,
    max_dual_source_draw_buffers = c.GL_MAX_DUAL_SOURCE_DRAW_BUFFERS,
    max_elements_indices = c.GL_MAX_ELEMENTS_INDICES,
    max_elements_vertices = c.GL_MAX_ELEMENTS_VERTICES,
    max_fragment_input_components = c.GL_MAX_FRAGMENT_INPUT_COMPONENTS,
    max_fragment_uniform_blocks = c.GL_MAX_FRAGMENT_UNIFORM_BLOCKS,
    max_fragment_uniform_components = c.GL_MAX_FRAGMENT_UNIFORM_COMPONENTS,
    max_geometry_input_components = c.GL_MAX_GEOMETRY_INPUT_COMPONENTS,
    max_geometry_output_components = c.GL_MAX_GEOMETRY_OUTPUT_COMPONENTS,
    max_geometry_texture_image_units = c.GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS,
    max_geometry_uniform_blocks = c.GL_MAX_GEOMETRY_UNIFORM_BLOCKS,
    max_geometry_uniform_components = c.GL_MAX_GEOMETRY_UNIFORM_COMPONENTS,
    max_integer_samples = c.GL_MAX_INTEGER_SAMPLES,
    max_program_texel_offset = c.GL_MAX_PROGRAM_TEXEL_OFFSET,
    max_rectangle_texture_size = c.GL_MAX_RECTANGLE_TEXTURE_SIZE,
    max_renderbuffer_size = c.GL_MAX_RENDERBUFFER_SIZE,
    max_sample_mask_words = c.GL_MAX_SAMPLE_MASK_WORDS,
    max_server_wait_timeout = c.GL_MAX_SERVER_WAIT_TIMEOUT,
    max_texture_buffer_size = c.GL_MAX_TEXTURE_BUFFER_SIZE,
    max_texture_image_units = c.GL_MAX_TEXTURE_IMAGE_UNITS,
    max_texture_lod_bias = c.GL_MAX_TEXTURE_LOD_BIAS,
    max_texture_size = c.GL_MAX_TEXTURE_SIZE,
    max_uniform_block_size = c.GL_MAX_UNIFORM_BLOCK_SIZE,
    max_uniform_buffer_bindings = c.GL_MAX_UNIFORM_BUFFER_BINDINGS,
    max_varying_components = c.GL_MAX_VARYING_COMPONENTS,
    // max_varying_floats = c.GL_MAX_VARYING_FLOATS,
    max_vertex_attribs = c.GL_MAX_VERTEX_ATTRIBS,
    max_vertex_output_components = c.GL_MAX_VERTEX_OUTPUT_COMPONENTS,
    max_vertex_texture_image_units = c.GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
    max_vertex_uniform_blocks = c.GL_MAX_VERTEX_UNIFORM_BLOCKS,
    max_vertex_uniform_components = c.GL_MAX_VERTEX_UNIFORM_COMPONENTS,
    max_viewport_dims = c.GL_MAX_VIEWPORT_DIMS,
    min_program_texel_offset = c.GL_MIN_PROGRAM_TEXEL_OFFSET,
    minor_version = c.GL_MINOR_VERSION,
    num_compressed_texture_formats = c.GL_NUM_COMPRESSED_TEXTURE_FORMATS,
    num_extensions = c.GL_NUM_EXTENSIONS,
    pack_alignment = c.GL_PACK_ALIGNMENT,
    pack_image_height = c.GL_PACK_IMAGE_HEIGHT,
    pack_lsb_first = c.GL_PACK_LSB_FIRST,
    pack_row_length = c.GL_PACK_ROW_LENGTH,
    pack_skip_images = c.GL_PACK_SKIP_IMAGES,
    pack_skip_pixels = c.GL_PACK_SKIP_PIXELS,
    pack_skip_rows = c.GL_PACK_SKIP_ROWS,
    pack_swap_bytes = c.GL_PACK_SWAP_BYTES,
    pixel_pack_buffer_binding = c.GL_PIXEL_PACK_BUFFER_BINDING,
    pixel_unpack_buffer_binding = c.GL_PIXEL_UNPACK_BUFFER_BINDING,
    point_fade_threshold_size = c.GL_POINT_FADE_THRESHOLD_SIZE,
    point_size = c.GL_POINT_SIZE,
    point_size_granularity = c.GL_POINT_SIZE_GRANULARITY,
    point_size_range = c.GL_POINT_SIZE_RANGE,
    polygon_mode = c.GL_POLYGON_MODE,
    polygon_offset_factor = c.GL_POLYGON_OFFSET_FACTOR,
    polygon_offset_fill = c.GL_POLYGON_OFFSET_FILL,
    polygon_offset_line = c.GL_POLYGON_OFFSET_LINE,
    polygon_offset_point = c.GL_POLYGON_OFFSET_POINT,
    polygon_offset_units = c.GL_POLYGON_OFFSET_UNITS,
    polygon_smooth = c.GL_POLYGON_SMOOTH,
    polygon_smooth_hint = c.GL_POLYGON_SMOOTH_HINT,
    primitive_restart_index = c.GL_PRIMITIVE_RESTART_INDEX,
    program_point_size = c.GL_PROGRAM_POINT_SIZE,
    provoking_vertex = c.GL_PROVOKING_VERTEX,
    read_buffer = c.GL_READ_BUFFER,
    read_framebuffer_binding = c.GL_READ_FRAMEBUFFER_BINDING,
    renderbuffer_binding = c.GL_RENDERBUFFER_BINDING,
    sample_buffers = c.GL_SAMPLE_BUFFERS,
    sample_coverage_invert = c.GL_SAMPLE_COVERAGE_INVERT,
    sample_coverage_value = c.GL_SAMPLE_COVERAGE_VALUE,
    sampler_binding = c.GL_SAMPLER_BINDING,
    samples = c.GL_SAMPLES,
    scissor_box = c.GL_SCISSOR_BOX,
    scissor_test = c.GL_SCISSOR_TEST,
    smooth_line_width_granularity = c.GL_SMOOTH_LINE_WIDTH_GRANULARITY,
    smooth_line_width_range = c.GL_SMOOTH_LINE_WIDTH_RANGE,
    stencil_back_fail = c.GL_STENCIL_BACK_FAIL,
    stencil_back_func = c.GL_STENCIL_BACK_FUNC,
    stencil_back_pass_depth_fail = c.GL_STENCIL_BACK_PASS_DEPTH_FAIL,
    stencil_back_pass_depth_pass = c.GL_STENCIL_BACK_PASS_DEPTH_PASS,
    stencil_back_ref = c.GL_STENCIL_BACK_REF,
    stencil_back_value_mask = c.GL_STENCIL_BACK_VALUE_MASK,
    stencil_back_writemask = c.GL_STENCIL_BACK_WRITEMASK,
    stencil_clear_value = c.GL_STENCIL_CLEAR_VALUE,
    stencil_fail = c.GL_STENCIL_FAIL,
    stencil_func = c.GL_STENCIL_FUNC,
    stencil_pass_depth_fail = c.GL_STENCIL_PASS_DEPTH_FAIL,
    stencil_pass_depth_pass = c.GL_STENCIL_PASS_DEPTH_PASS,
    stencil_ref = c.GL_STENCIL_REF,
    stencil_test = c.GL_STENCIL_TEST,
    stencil_value_mask = c.GL_STENCIL_VALUE_MASK,
    stencil_writemask = c.GL_STENCIL_WRITEMASK,
    stereo = c.GL_STEREO,
    subpixel_bits = c.GL_SUBPIXEL_BITS,
    texture_binding_1d = c.GL_TEXTURE_BINDING_1D,
    texture_binding_1d_array = c.GL_TEXTURE_BINDING_1D_ARRAY,
    texture_binding_2d = c.GL_TEXTURE_BINDING_2D,
    texture_binding_2d_array = c.GL_TEXTURE_BINDING_2D_ARRAY,
    texture_binding_2d_multisample = c.GL_TEXTURE_BINDING_2D_MULTISAMPLE,
    texture_binding_2d_multisample_array = c.GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY,
    texture_binding_3d = c.GL_TEXTURE_BINDING_3D,
    texture_binding_buffer = c.GL_TEXTURE_BINDING_BUFFER,
    texture_binding_cube_map = c.GL_TEXTURE_BINDING_CUBE_MAP,
    texture_binding_rectangle = c.GL_TEXTURE_BINDING_RECTANGLE,
    texture_compression_hint = c.GL_TEXTURE_COMPRESSION_HINT,
    timestamp = c.GL_TIMESTAMP,
    transform_feedback_buffer_binding = c.GL_TRANSFORM_FEEDBACK_BUFFER_BINDING,
    transform_feedback_buffer_size = c.GL_TRANSFORM_FEEDBACK_BUFFER_SIZE,
    transform_feedback_buffer_start = c.GL_TRANSFORM_FEEDBACK_BUFFER_START,
    uniform_buffer_binding = c.GL_UNIFORM_BUFFER_BINDING,
    uniform_buffer_offset_alignment = c.GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT,
    uniform_buffer_size = c.GL_UNIFORM_BUFFER_SIZE,
    uniform_buffer_start = c.GL_UNIFORM_BUFFER_START,
    unpack_alignment = c.GL_UNPACK_ALIGNMENT,
    unpack_image_height = c.GL_UNPACK_IMAGE_HEIGHT,
    unpack_lsb_first = c.GL_UNPACK_LSB_FIRST,
    unpack_row_length = c.GL_UNPACK_ROW_LENGTH,
    unpack_skip_images = c.GL_UNPACK_SKIP_IMAGES,
    unpack_skip_pixels = c.GL_UNPACK_SKIP_PIXELS,
    unpack_skip_rows = c.GL_UNPACK_SKIP_ROWS,
    unpack_swap_bytes = c.GL_UNPACK_SWAP_BYTES,
    viewport = c.GL_VIEWPORT,
};

pub fn getInteger(parameter: Parameter) i32 {
    var value: types.Int = undefined;
    c.glGetIntegerv(@enumToInt(parameter), &value);
    checkError();
    return value;
}

pub const StringParameter = enum(types.Enum) {
    vendor = c.GL_VENDOR,
    renderer = c.GL_RENDERER,
    version = c.GL_VERSION,
    shading_language_version = c.GL_SHADING_LANGUAGE_VERSION,
    extensions = c.GL_EXTENSIONS,
};

pub fn getStringi(parameter: StringParameter, index: u32) ?[:0]const u8 {
    return std.mem.span(c.glGetStringi(@enumToInt(parameter), index));
}
pub fn getString(parameter: StringParameter) ?[:0]const u8 {
    return std.mem.span(c.glGetString(@enumToInt(parameter)));
}

pub fn hasExtension(extension: [:0]const u8) bool {
    const count = getInteger(.num_extensions);
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const ext = getStringi(.extensions, i) orelse return false;
        if (std.mem.eql(u8, ext, extension)) {
            return true;
        }
    }
    return false;
}
