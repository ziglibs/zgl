const std = @import("std");

const c = @cImport({
    @cInclude("epoxy/gl.h");
});

comptime {
    std.meta.refAllDecls(@This());
}

pub const VertexArray = enum(c.GLuint) {
    invalid = 0,
    one = 1, // bugfix: #5314,
    _,

    pub const create = createVertexArray;
    pub const delete = deleteVertexArray;
    pub const bind = bindVertexArray;
    pub const enableVertexAttribute = enableVertexArrayAttrib;
    pub const disableVertexAttribute = disableVertexArrayAttrib;

    pub const attribFormat = vertexArrayAttribFormat;
    pub const attribIFormat = vertexArrayAttribIFormat;
    pub const attribLFormat = vertexArrayAttribLFormat;

    pub const attribBinding = vertexArrayAttribBinding;

    pub const vertexBuffer = glVertexArrayVertexBuffer;
};

pub const Buffer = enum(c.GLuint) {
    invalid = 0,
    one = 1, // bugfix: #5314,
    _,

    pub const create = createBuffer;
    pub const bind = bindBuffer;
    pub const delete = deleteBuffer;
    pub const data = namedBufferData;
};

pub const Shader = enum(c.GLuint) {
    invalid = 0,
    one = 1, // bugfix: #5314,
    _,

    pub const create = createShader;
    pub const delete = deleteShader;

    pub const compile = compileShader;
    pub const source = shaderSource;

    pub const get = getShader;
    pub const getCompileLog = getShaderInfoLog;
};
pub const Program = enum(c.GLuint) {
    invalid = 0,
    one = 1, // bugfix: #5314,
    _,

    pub const create = createProgram;
    pub const delete = deleteProgram;

    pub const attach = attachShader;
    pub const detach = detachShader;

    pub const link = linkProgram;

    pub const use = useProgram;

    pub const get = getProgram;
    pub const getCompileLog = getProgramInfoLog;
    pub const uniformLocation = getUniformLocation;
};

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

    while (c.glGetError() != c.GL_NO_ERROR) {
        // consume them all!
    }

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

fn ui2gl(val: usize) c.GLuint {
    return @intCast(c.GLuint, val);
}

fn b2gl(b: bool) c.GLboolean {
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

pub fn clearDepth(depth: f32) !void {
    c.glClearDepth(depth);
    try checkError();
}

pub fn clear(mask: struct { color: bool = false, depth: bool = false, stencil: bool = false }) !void {
    c.glClear(
        (if (mask.color) c.GL_COLOR_BUFFER_BIT else @as(c.GLenum, 0)) |
            (if (mask.depth) c.GL_DEPTH_BUFFER_BIT else @as(c.GLenum, 0)) |
            (if (mask.stencil) c.GL_STENCIL_BUFFER_BIT else @as(c.GLenum, 0)),
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

pub fn enableVertexAttribArray(index: u32) !void {
    c.glEnableVertexAttribArray(index);
    try checkError();
}

pub fn disableVertexAttribArray(index: u32) !void {
    c.glDisableVertexAttribArray(index);
    try checkError();
}

pub fn enableVertexArrayAttrib(vertexArray: VertexArray, index: u32) !void {
    c.glEnableVertexArrayAttrib(@enumToInt(vertexArray), index);
    try checkError();
}

pub fn disableVertexArrayAttrib(vertexArray: VertexArray, index: u32) !void {
    c.glDisableVertexArrayAttrib(@enumToInt(vertexArray), index);
    try checkError();
}

pub const Type = enum(c.GLenum) {
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

pub fn vertexAttribFormat(attribindex: u32, size: u32, attribute_type: Type, normalized: bool, relativeoffset: usize) !void {
    c.glVertexAttribFormat(
        attribindex,
        @intCast(c.GLint, size),
        @enumToInt(attribute_type),
        b2gl(normalized),
        ui2gl(relativeoffset),
    );
    try checkError();
}

pub fn vertexAttribIFormat(attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) !void {
    c.glVertexAttribIFormat(
        attribindex,
        @intCast(c.GLint, size),
        @enumToInt(attribute_type),
        ui2gl(relativeoffset),
    );
    try checkError();
}

pub fn vertexAttribLFormat(attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) !void {
    c.glVertexAttribLFormat(
        attribindex,
        @intCast(c.GLint, size),
        @enumToInt(attribute_type),
        ui2gl(relativeoffset),
    );
    try checkError();
}

pub fn vertexArrayAttribFormat(vertexArray: VertexArray, attribindex: u32, size: u32, attribute_type: Type, normalized: bool, relativeoffset: usize) !void {
    c.glVertexArrayAttribFormat(
        @enumToInt(vertexArray),
        attribindex,
        @intCast(c.GLint, size),
        @enumToInt(attribute_type),
        b2gl(normalized),
        ui2gl(relativeoffset),
    );
    try checkError();
}

pub fn vertexArrayAttribIFormat(vertexArray: VertexArray, attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) !void {
    c.glVertexArrayAttribIFormat(
        @enumToInt(vertexArray),
        attribindex,
        @intCast(
            c.GLint,
            size,
        ),
        @enumToInt(attribute_type),
        ui2gl(relativeoffset),
    );
    try checkError();
}

pub fn vertexArrayAttribLFormat(vertexArray: VertexArray, attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) !void {
    c.glVertexArrayAttribLFormat(
        @enumToInt(vertexArray),
        attribindex,
        @intCast(
            c.GLint,
            size,
        ),
        @enumToInt(attribute_type),
        relativeoffset,
    );
    try checkError();
}

pub fn vertexAttribBinding(attribindex: u32, bindingindex: u32) !void {
    c.glVertexAttribBinding(
        attribindex,
        bindingindex,
    );
    try checkError();
}
pub fn vertexArrayAttribBinding(vertexArray: VertexArray, attribindex: u32, bindingindex: u32) !void {
    c.glVertexArrayAttribBinding(
        @enumToInt(vertexArray),
        attribindex,
        bindingindex,
    );
    try checkError();
}

pub fn glBindVertexBuffer(bindingindex: u32, buffer: Buffer, offset: usize, stride: usize) !void {
    c.glBindVertexBuffer(bindingindex, @enumToInt(buffer), cs2gl(offset), cs2gl(stride));
    try checkError();
}

pub fn glVertexArrayVertexBuffer(vertexArray: VertexArray, bindingindex: u32, buffer: Buffer, offset: usize, stride: usize) !void {
    c.glVertexArrayVertexBuffer(@enumToInt(vertexArray), bindingindex, @enumToInt(buffer), cs2gl(offset), cs2gl(stride));
    try checkError();
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

pub const BufferUsage = enum(c.GLenum) {
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

pub fn namedBufferData(buf: Buffer, comptime T: type, items: []const T, usage: BufferUsage) !void {
    c.glNamedBufferData(
        @enumToInt(buf),
        cs2gl(@sizeOf(T) * items.len),
        items.ptr,
        @enumToInt(usage),
    );
    try checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Shaders

pub const ShaderType = enum(c.GLenum) {
    compute = c.GL_COMPUTE_SHADER,
    vertex = c.GL_VERTEX_SHADER,
    tess_control = c.GL_TESS_CONTROL_SHADER,
    tess_evaluation = c.GL_TESS_EVALUATION_SHADER,
    geometry = c.GL_GEOMETRY_SHADER,
    fragment = c.GL_FRAGMENT_SHADER,
};

pub fn createShader(shaderType: ShaderType) !Shader {
    const shader = @intToEnum(Shader, c.glCreateShader(@enumToInt(shaderType)));
    if (shader == .invalid) {
        try checkError();
        unreachable;
    }
    return shader;
}

pub fn deleteShader(shader: Shader) void {
    c.glDeleteShader(@enumToInt(shader));
    checkError() catch {};
}

pub fn compileShader(shader: Shader) !void {
    c.glCompileShader(@enumToInt(shader));
    try checkError();
}

pub fn shaderSource(shader: Shader, comptime N: comptime_int, sources: *const [N][]const u8) !void {
    var lengths: [N]c.GLint = undefined;
    for (lengths) |*len, i| {
        len.* = @intCast(c.GLint, sources[i].len);
    }

    var ptrs: [N]*const c.GLchar = undefined;
    for (ptrs) |*ptr, i| {
        ptr.* = @ptrCast(*const c.GLchar, sources[i].ptr);
    }

    c.glShaderSource(@enumToInt(shader), N, &ptrs, &lengths);

    try checkError();
}

pub const ShaderParameter = enum(c.GLenum) {
    shader_type = c.GL_SHADER_TYPE,
    delete_status = c.GL_DELETE_STATUS,
    compile_status = c.GL_COMPILE_STATUS,
    info_log_length = c.GL_INFO_LOG_LENGTH,
    shader_source_length = c.GL_SHADER_SOURCE_LENGTH,
};

pub fn getShader(shader: Shader, parameter: ShaderParameter) !c.GLint {
    var value: c.GLint = undefined;
    c.glGetShaderiv(@enumToInt(shader), @enumToInt(parameter), &value);
    try checkError();
    return value;
}

pub fn getShaderInfoLog(shader: Shader, allocator: *std.mem.Allocator) ![:0]const u8 {
    const length = try getShader(shader, .info_log_length);
    const log = try allocator.allocWithOptions(u8, @intCast(usize, length) + 1, null, 0);
    errdefer allocator.free(log);

    var actual_length: c.GLsizei = undefined;

    c.glGetShaderInfoLog(@enumToInt(shader), cs2gl(log.len), &actual_length, log.ptr);
    try checkError();

    log[@intCast(usize, actual_length)] = 0;

    return log[0..@intCast(usize, actual_length) :0];
}

///////////////////////////////////////////////////////////////////////////////
// Program

pub fn createProgram() !Program {
    const program = @intToEnum(Program, c.glCreateProgram());
    if (program == .invalid) {
        try checkError();
        unreachable;
    }
    return program;
}

pub fn deleteProgram(program: Program) void {
    c.glDeleteProgram(@enumToInt(program));
    checkError() catch {};
}

pub fn linkProgram(program: Program) !void {
    c.glLinkProgram(@enumToInt(program));
    try checkError();
}

pub fn attachShader(program: Program, shader: Shader) !void {
    c.glAttachShader(@enumToInt(program), @enumToInt(shader));
    try checkError();
}

pub fn detachShader(program: Program, shader: Shader) void {
    c.glDetachShader(@enumToInt(program), @enumToInt(shader));
    checkError() catch {};
}

pub fn useProgram(program: Program) !void {
    c.glUseProgram(@enumToInt(program));
    try checkError();
}

pub const ProgramParameter = enum(c.GLenum) {
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

pub fn getProgram(program: Program, parameter: ProgramParameter) !c.GLint {
    var value: c.GLint = undefined;
    c.glGetProgramiv(@enumToInt(program), @enumToInt(parameter), &value);
    try checkError();
    return value;
}

pub fn getProgramInfoLog(program: Program, allocator: *std.mem.Allocator) ![:0]const u8 {
    const length = try getProgram(program, .info_log_length);
    const log = try allocator.allocWithOptions(u8, @intCast(usize, length) + 1, null, 0);
    errdefer allocator.free(log);

    var actual_length: c.GLsizei = undefined;

    c.glGetProgramInfoLog(@enumToInt(program), cs2gl(log.len), &actual_length, log.ptr);
    try checkError();

    log[@intCast(usize, actual_length)] = 0;

    return log[0..@intCast(usize, actual_length) :0];
}

pub fn getUniformLocation(program: Program, name: [:0]const u8) !?u32 {
    const loc = c.glGetUniformLocation(@enumToInt(program), name.ptr);
    try checkError();
    if (loc < 0)
        return null;
    return @intCast(u32, loc);
}

///////////////////////////////////////////////////////////////////////////////
// Uniforms

pub fn programUniform1f(program: Program, location: u32, value: f32) !void {
    c.glProgramUniform1f(@enumToInt(program), @intCast(c.GLint, location), value);
    try checkError();
}

pub fn programUniformMatrix4(program: Program, location: u32, transpose: bool, items: []const [4][4]f32) !void {
    c.glProgramUniformMatrix4fv(
        @enumToInt(program),
        @intCast(c.GLint, location),
        cs2gl(items.len),
        b2gl(transpose),

        @ptrCast(*const f32, items.ptr),
    );
    try checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Draw Calls

pub const PrimitiveType = enum(c.GLenum) {
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

pub fn drawArrays(primitiveType: PrimitiveType, first: usize, count: usize) !void {
    c.glDrawArrays(@enumToInt(primitiveType), cs2gl(first), cs2gl(count));
    try checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Status Control

pub const Capabilities = enum(c.GLenum) {
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

pub fn enable(cap: Capabilities) !void {
    c.glEnable(@enumToInt(cap));
    try checkError();
}

pub fn disable(cap: Capabilities) !void {
    c.glDisable(@enumToInt(cap));
    try checkError();
}

pub fn enableI(cap: Capabilities, index: u32) !void {
    c.glEnablei(@enumToInt(cap), index);
    try checkError();
}

pub fn disableI(cap: Capabilities, index: u32) !void {
    c.glDisablei(@enumToInt(cap), index);
    try checkError();
}

pub const DepthFunc = enum(c.GLenum) {
    never = c.GL_NEVER,
    less = c.GL_LESS,
    equal = c.GL_EQUAL,
    less_or_equal = c.GL_LEQUAL,
    greater = c.GL_GREATER,
    not_equal = c.GL_NOTEQUAL,
    greator_or_equal = c.GL_GEQUAL,
    always = c.GL_ALWAYS,
};

pub fn depthFunc(func: DepthFunc) !void {
    c.glDepthFunc(@enumToInt(func));
    try checkError();
}

pub fn polygonOffset(factor: f32, units: f32) !void {
    c.glPolygonOffset(factor, units);
    try checkError();
}

pub fn pointSize(size: f32) !void {
    c.glPointSize(size);
    try checkError();
}
