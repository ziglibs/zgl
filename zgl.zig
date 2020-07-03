const std = @import("std");

const c = @cImport({
    @cInclude("epoxy/gl.h");
});

pub const VertexArray = enum(c.GLuint) {
    _,

    pub const create = createVertexArray;
    pub const delete = deleteVertexArray;
    pub const bind = bindVertexArray;
};

pub const Buffer = enum(c.GLuint) {
    _,

    pub const create = createBuffer;
    pub const bind = bindBuffer;
    pub const delete = deleteBuffer;
};

pub const Shader = enum(c.GLuint) { _ };
pub const Program = enum(c.GLuint) { _ };

pub const ErrorHandling = enum {
    /// OpenGL functions will return a error code matching the error that happend
    default,

    /// OpenGL functions will log the error and return success.
    log,

    /// No error checking will be executed. Gotta go fast!
    none,
};

const error_handling: ErrorHandling = if (@hasDecl(@import("root"), ""))
    @import("root").opengl_error_handling
else if (std.builtin.mode == .ReleaseFast)
    .none
else
    .default;

pub const Error = error{
    InvalidEnum,
    InvalidValue,
    InvalidOperation,
    StackOverflow,
    StackUnderflow,
    OutOfMemory,
    InvalidFramebufferOperation,
    TableTooLarge,
    TextureTooLarge,
};

/// Checks if a OpenGL error happend and may yield it.
/// This function is configurable via `opengl_error_handling` in the root file.
/// In Debug mode, unexpected error codes will be unreachable, in all release modes
/// they will be safely wrapped to `error.UnexpectedError`.
fn checkError() !void {
    if (error_handling == .none)
        return;

    const error_code = c.glGetError();
    if (error_code == c.GL_NO_ERROR)
        return;

    const LocalError = if (std.builtin.mode == .Debug)
        Error
    else
        Error || error{UnexpectedError};

    var err: Error = switch (error_code) {
        c.GL_INVALID_ENUM => Error.InvalidEnum,
        c.GL_INVALID_VALUE => Error.InvalidValue,
        c.GL_INVALID_OPERATION => Error.InvalidOperation,
        c.GL_STACK_OVERFLOW => Error.StackOverflow,
        c.GL_STACK_UNDERFLOW => Error.StackUnderflow,
        c.GL_OUT_OF_MEMORY => Error.OutOfMemory,
        c.GL_INVALID_FRAMEBUFFER_OPERATION => Error.InvalidFramebufferOperation,
        // c.GL_INVALID_FRAMEBUFFER_OPERATION_EXT => Error.InvalidFramebufferOperation,
        // c.GL_INVALID_FRAMEBUFFER_OPERATION_OES => Error.InvalidFramebufferOperation,
        c.GL_TABLE_TOO_LARGE => Error.TableTooLarge,
        // c.GL_TABLE_TOO_LARGE_EXT => Error.TableTooLarge,
        c.GL_TEXTURE_TOO_LARGE_EXT => Error.TextureTooLarge,
        else => if (std.builtin.mode == .Debug)
            unreachable
        else blk: {
            std.log.crit(.OpenGL, "Unhandled OpenGL error code: 0x{X:0>4}", .{error_code});
            break :blk LocalError.UnexpectedError;
        },
    };

    switch (error_handling) {
        .log => std.log.err(.OpenGL, "OpenGL failure: {}\n", .{err}),
        .default => return err,
        .none => unreachable,
    }
}

/// Integer conversion helper.
fn cs2gl(size: usize) c.GLsizei {
    return @intCast(c.GLsizei, size);
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
pub fn debugMessageCallback(context: var, comptime handler: DebugMessageCallbackHandler(@TypeOf(context))) !void {
    const is_void = (@TypeOf(context) == void);

    const H = struct {
        fn translateSource(source: c.GLuint) DebugSource {
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

        fn translateMessageType(msg_type: c.GLuint) DebugMessageType {
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

        fn translateSeverity(sev: c.GLuint) DebugSeverity {
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
            c_source: c.GLenum,
            c_msg_type: c.GLenum,
            id: c.GLuint,
            c_severity: c.GLenum,
            length: c.GLsizei,
            c_message: [*c]const c.GLchar,
            userParam: ?*const c_void,
        ) callconv(.C) void {
            const debug_source = translateSource(c_source);
            const msg_type = translateMessageType(c_msg_type);
            const severity = translateSeverity(c_severity);

            const message = c_message[0..@intCast(usize, length)];

            if (is_void) {
                handler(debug_source, msg_type, id, severity, message);
            } else {
                handler(@ptrCast(@TypeOf(context), userParam), debug_source, msg_type, id, severity, message);
            }
        }
    };

    if (is_void)
        c.glDebugMessageCallback(H.callback, null)
    else
        c.glDebugMessageCallback(H.callback, @ptrCast(?*const c_void, context));
    try checkError();
}

pub fn clearColor(r: f32, g: f32, b: f32, a: f32) !void {
    c.glClearColor(r, g, b, a);
    try checkError();
}

pub fn clear(mask: struct { color: bool = false, depth: bool = false, stencil: bool = false }) !void {
    c.glClear(
        0 |
            if (mask.color) c.GL_COLOR_BUFFER_BIT else @as(c.GLenum, 0) |
            if (mask.depth) c.GL_DEPTH_BUFFER_BIT else @as(c.GLenum, 0) |
            if (mask.stencil) c.GL_STENCIL_BUFFER_BIT else @as(c.GLenum, 0),
    );
    try checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Vertex Arrays

pub fn createVertexArrays(items: []VertexArray) !void {
    c.glCreateVertexArrays(cs2gl(items.len), @ptrCast([*]c.GLuint, items.ptr));
    try checkError();
}

pub fn createVertexArray() !VertexArray {
    var vao: VertexArray = undefined;
    try createVertexArrays(@ptrCast([*]VertexArray, &vao)[0..1]);
    return vao;
}

pub fn bindVertexArray(vao: VertexArray) !void {
    c.glBindVertexArray(@enumToInt(vao));
    try checkError();
}

pub fn deleteVertexArrays(items: []const VertexArray) void {
    c.glDeleteVertexArrays(cs2gl(items.len), @ptrCast([*]const c.GLuint, items.ptr));
}

pub fn deleteVertexArray(vao: VertexArray) void {
    deleteVertexArrays(@ptrCast([*]const VertexArray, &vao)[0..1]);
}

///////////////////////////////////////////////////////////////////////////////
// Buffer

pub const BufferTarget = enum(c.GLenum) {
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

pub fn createBuffers(items: []Buffer) !void {
    c.glCreateBuffers(cs2gl(items.len), @ptrCast([*]c.GLuint, items.ptr));
    try checkError();
}

pub fn createBuffer() !Buffer {
    var buf: Buffer = undefined;
    try createBuffers(@ptrCast([*]Buffer, &buf)[0..1]);
    return buf;
}

pub fn bindBuffer(buf: Buffer, target: BufferTarget) !void {
    c.glBindBuffer(@enumToInt(target), @enumToInt(vao));
    try checkError();
}

pub fn deleteBuffers(items: []const Buffer) void {
    c.glDeleteBuffers(cs2gl(items.len), @ptrCast([*]const c.GLuint, items.ptr));
}

pub fn deleteBuffer(buf: Buffer) void {
    deleteBuffers(@ptrCast([*]const Buffer, &buf)[0..1]);
}
