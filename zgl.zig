const std = @import("std");

const c = @cImport({
    @cInclude("epoxy/gl.h");
});

comptime {
    std.testing.refAllDecls(@This());
}

pub const VertexArray = enum(c.GLuint) {
    invalid = 0,
    _,

    pub const create = createVertexArray;
    pub const delete = deleteVertexArray;
    pub const gen = genVertexArray;
    pub const bind = bindVertexArray;
    pub const enableVertexAttribute = enableVertexArrayAttrib;
    pub const disableVertexAttribute = disableVertexArrayAttrib;

    pub const attribFormat = vertexArrayAttribFormat;
    pub const attribIFormat = vertexArrayAttribIFormat;
    pub const attribLFormat = vertexArrayAttribLFormat;

    pub const attribBinding = vertexArrayAttribBinding;

    pub const vertexBuffer = vertexArrayVertexBuffer;
    pub const elementBuffer = vertexArrayElementBuffer;
};

pub const Buffer = enum(c.GLuint) {
    invalid = 0,
    _,

    pub const create = createBuffer;
    pub const gen = genBuffer;
    pub const bind = bindBuffer;
    pub const delete = deleteBuffer;
    pub const data = namedBufferData;
};

pub const Shader = enum(c.GLuint) {
    invalid = 0,
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
    _,

    pub const create = createProgram;
    pub const delete = deleteProgram;

    pub const attach = attachShader;
    pub const detach = detachShader;

    pub const link = linkProgram;

    pub const use = useProgram;

    pub const uniform1u = programUniform1u;
    pub const uniform1i = programUniform1i;
    pub const uniform1f = programUniform1f;
    pub const uniform3f = programUniform3f;
    pub const uniform4f = programUniform4f;
    pub const uniformMatrix4 = programUniformMatrix4;

    pub const get = getProgram;
    pub const getCompileLog = getProgramInfoLog;
    pub const uniformLocation = getUniformLocation;
};

pub const Texture = enum(c.GLuint) {
    invalid = 0,
    _,

    pub const create = createTexture;
    pub const delete = deleteTexture;

    pub const bindTo = bindTextureUnit;

    pub const parameter = textureParameter;

    pub const storage2D = textureStorage2D;
    pub const storage3D = textureStorage3D;

    pub const subImage2D = textureSubImage2D;
    pub const subImage3D = textureSubImage3D;
};

pub const ErrorHandling = enum {
    /// OpenGL functions will log the error, but will not assert that no error happened
    log,

    /// Asserts that no errors will happen.
    assert,

    /// No error checking will be executed. Gotta go fast!
    none,
};

const error_handling: ErrorHandling = if (@hasDecl(@import("root"), ""))
    @import("root").opengl_error_handling
else if (std.builtin.mode == .ReleaseFast)
    .none
else
    .assert;

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
pub fn debugMessageCallback(context: anytype, comptime handler: DebugMessageCallbackHandler(@TypeOf(context))) void {
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
    c.glClear(
        (if (mask.color) c.GL_COLOR_BUFFER_BIT else @as(c.GLenum, 0)) |
            (if (mask.depth) c.GL_DEPTH_BUFFER_BIT else @as(c.GLenum, 0)) |
            (if (mask.stencil) c.GL_STENCIL_BUFFER_BIT else @as(c.GLenum, 0)),
    );
    checkError();
}

///////////////////////////////////////////////////////////////////////////////
// Vertex Arrays

pub fn createVertexArrays(items: []VertexArray) void {
    c.glCreateVertexArrays(cs2gl(items.len), @ptrCast([*]c.GLuint, items.ptr));
    checkError();
}

pub fn createVertexArray() VertexArray {
    var vao: VertexArray = undefined;
    createVertexArrays(@ptrCast([*]VertexArray, &vao)[0..1]);
    return vao;
}

pub fn genVertexArrays(items: []VertexArray) void {
    c.glGenVertexArrays(cs2gl(items.len), @ptrCast([*]c.GLuint, items.ptr));
    checkError();
}

pub fn genVertexArray() VertexArray {
    var vao: VertexArray = undefined;
    genVertexArrays(@ptrCast([*]VertexArray, &vao)[0..1]);
    return vao;
}

pub fn bindVertexArray(vao: VertexArray) void {
    c.glBindVertexArray(@enumToInt(vao));
    checkError();
}

pub fn deleteVertexArrays(items: []const VertexArray) void {
    c.glDeleteVertexArrays(cs2gl(items.len), @ptrCast([*]const c.GLuint, items.ptr));
}

pub fn deleteVertexArray(vao: VertexArray) void {
    deleteVertexArrays(@ptrCast([*]const VertexArray, &vao)[0..1]);
}

pub fn enableVertexAttribArray(index: u32) void {
    c.glEnableVertexAttribArray(index);
    checkError();
}

pub fn disableVertexAttribArray(index: u32) void {
    c.glDisableVertexAttribArray(index);
    checkError();
}

pub fn enableVertexArrayAttrib(vertexArray: VertexArray, index: u32) void {
    c.glEnableVertexArrayAttrib(@enumToInt(vertexArray), index);
    checkError();
}

pub fn disableVertexArrayAttrib(vertexArray: VertexArray, index: u32) void {
    c.glDisableVertexArrayAttrib(@enumToInt(vertexArray), index);
    checkError();
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

pub fn vertexAttribFormat(attribindex: u32, size: u32, attribute_type: Type, normalized: bool, relativeoffset: usize) void {
    c.glVertexAttribFormat(
        attribindex,
        @intCast(c.GLint, size),
        @enumToInt(attribute_type),
        b2gl(normalized),
        ui2gl(relativeoffset),
    );
    checkError();
}

pub fn vertexAttribIFormat(attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) void {
    c.glVertexAttribIFormat(
        attribindex,
        @intCast(c.GLint, size),
        @enumToInt(attribute_type),
        ui2gl(relativeoffset),
    );
    checkError();
}

pub fn vertexAttribLFormat(attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) void {
    c.glVertexAttribLFormat(
        attribindex,
        @intCast(c.GLint, size),
        @enumToInt(attribute_type),
        ui2gl(relativeoffset),
    );
    checkError();
}

pub fn vertexAttribPointer(attribindex: u32, size: u32, attribute_type: Type, normalized: bool, stride: usize, relativeoffset: ?usize) void {
    c.glVertexAttribPointer(
        attribindex,
        @intCast(c.GLint, size),
        @enumToInt(attribute_type),
        b2gl(normalized),
        @intCast(c.GLint, stride),
        if (relativeoffset != null) @intToPtr(?*c_void, relativeoffset.?) else null,
    );
    checkError();
}

pub fn vertexArrayAttribFormat(
    vertexArray: VertexArray,
    attribindex: u32,
    size: u32,
    attribute_type: Type,
    normalized: bool,
    relativeoffset: usize,
) void {
    c.glVertexArrayAttribFormat(
        @enumToInt(vertexArray),
        attribindex,
        @intCast(c.GLint, size),
        @enumToInt(attribute_type),
        b2gl(normalized),
        ui2gl(relativeoffset),
    );
    checkError();
}

pub fn vertexArrayAttribIFormat(vertexArray: VertexArray, attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) void {
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
    checkError();
}

pub fn vertexArrayAttribLFormat(vertexArray: VertexArray, attribindex: u32, size: u32, attribute_type: Type, relativeoffset: usize) void {
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
    checkError();
}

pub fn vertexAttribBinding(attribindex: u32, bindingindex: u32) void {
    c.glVertexAttribBinding(
        attribindex,
        bindingindex,
    );
    checkError();
}
pub fn vertexArrayAttribBinding(vertexArray: VertexArray, attribindex: u32, bindingindex: u32) void {
    c.glVertexArrayAttribBinding(
        @enumToInt(vertexArray),
        attribindex,
        bindingindex,
    );
    checkError();
}

pub fn bindVertexBuffer(bindingindex: u32, buffer: Buffer, offset: usize, stride: usize) void {
    c.glBindVertexBuffer(bindingindex, @enumToInt(buffer), cs2gl(offset), cs2gl(stride));
    checkError();
}

pub fn vertexArrayVertexBuffer(vertexArray: VertexArray, bindingindex: u32, buffer: Buffer, offset: usize, stride: usize) void {
    c.glVertexArrayVertexBuffer(@enumToInt(vertexArray), bindingindex, @enumToInt(buffer), cs2gl(offset), cs2gl(stride));
    checkError();
}

pub fn vertexArrayElementBuffer(vertexArray: VertexArray, buffer: Buffer) void {
    c.glVertexArrayElementBuffer(@enumToInt(vertexArray), @enumToInt(buffer));
    checkError();
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

pub fn createBuffers(items: []Buffer) void {
    c.glCreateBuffers(cs2gl(items.len), @ptrCast([*]c.GLuint, items.ptr));
    checkError();
}

pub fn createBuffer() Buffer {
    var buf: Buffer = undefined;
    createBuffers(@ptrCast([*]Buffer, &buf)[0..1]);
    return buf;
}

pub fn genBuffers(items: []Buffer) void {
    c.glGenBuffers(cs2gl(items.len), @ptrCast([*]c.GLuint, items.ptr));
    checkError();
}

pub fn genBuffer() Buffer {
    var buf: Buffer = undefined;
    genBuffers(@ptrCast([*]Buffer, &buf)[0..1]);
    return buf;
}

pub fn bindBuffer(buf: Buffer, target: BufferTarget) void {
    c.glBindBuffer(@enumToInt(target), @enumToInt(buf));
    checkError();
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

// using align(1) as we are not required to have aligned data here
pub fn namedBufferData(buf: Buffer, comptime T: type, items: []align(1) const T, usage: BufferUsage) void {
    c.glNamedBufferData(
        @enumToInt(buf),
        cs2gl(@sizeOf(T) * items.len),
        items.ptr,
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

pub fn createShader(shaderType: ShaderType) Shader {
    const shader = @intToEnum(Shader, c.glCreateShader(@enumToInt(shaderType)));
    if (shader == .invalid) {
        checkError();
        unreachable;
    }
    return shader;
}

pub fn deleteShader(shader: Shader) void {
    c.glDeleteShader(@enumToInt(shader));
    checkError();
}

pub fn compileShader(shader: Shader) void {
    c.glCompileShader(@enumToInt(shader));
    checkError();
}

pub fn shaderSource(shader: Shader, comptime N: comptime_int, sources: *const [N][]const u8) void {
    var lengths: [N]c.GLint = undefined;
    for (lengths) |*len, i| {
        len.* = @intCast(c.GLint, sources[i].len);
    }

    var ptrs: [N]*const c.GLchar = undefined;
    for (ptrs) |*ptr, i| {
        ptr.* = @ptrCast(*const c.GLchar, sources[i].ptr);
    }

    c.glShaderSource(@enumToInt(shader), N, &ptrs, &lengths);

    checkError();
}

pub const ShaderParameter = enum(c.GLenum) {
    shader_type = c.GL_SHADER_TYPE,
    delete_status = c.GL_DELETE_STATUS,
    compile_status = c.GL_COMPILE_STATUS,
    info_log_length = c.GL_INFO_LOG_LENGTH,
    shader_source_length = c.GL_SHADER_SOURCE_LENGTH,
};

pub fn getShader(shader: Shader, parameter: ShaderParameter) c.GLint {
    var value: c.GLint = undefined;
    c.glGetShaderiv(@enumToInt(shader), @enumToInt(parameter), &value);
    checkError();
    return value;
}

pub fn getShaderInfoLog(shader: Shader, allocator: *std.mem.Allocator) ![:0]const u8 {
    const length = getShader(shader, .info_log_length);
    const log = try allocator.allocWithOptions(u8, @intCast(usize, length) + 1, null, 0);
    errdefer allocator.free(log);

    var actual_length: c.GLsizei = undefined;

    c.glGetShaderInfoLog(@enumToInt(shader), cs2gl(log.len), &actual_length, log.ptr);
    checkError();

    log[@intCast(usize, actual_length)] = 0;

    return log[0..@intCast(usize, actual_length) :0];
}

///////////////////////////////////////////////////////////////////////////////
// Program

pub fn createProgram() Program {
    const program = @intToEnum(Program, c.glCreateProgram());
    if (program == .invalid) {
        checkError();
        unreachable;
    }
    return program;
}

pub fn deleteProgram(program: Program) void {
    c.glDeleteProgram(@enumToInt(program));
    checkError();
}

pub fn linkProgram(program: Program) void {
    c.glLinkProgram(@enumToInt(program));
    checkError();
}

pub fn attachShader(program: Program, shader: Shader) void {
    c.glAttachShader(@enumToInt(program), @enumToInt(shader));
    checkError();
}

pub fn detachShader(program: Program, shader: Shader) void {
    c.glDetachShader(@enumToInt(program), @enumToInt(shader));
    checkError();
}

pub fn useProgram(program: Program) void {
    c.glUseProgram(@enumToInt(program));
    checkError();
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

pub fn getProgram(program: Program, parameter: ProgramParameter) c.GLint {
    var value: c.GLint = undefined;
    c.glGetProgramiv(@enumToInt(program), @enumToInt(parameter), &value);
    checkError();
    return value;
}

pub fn getProgramInfoLog(program: Program, allocator: *std.mem.Allocator) ![:0]const u8 {
    const length = getProgram(program, .info_log_length);
    const log = try allocator.allocWithOptions(u8, @intCast(usize, length) + 1, null, 0);
    errdefer allocator.free(log);

    var actual_length: c.GLsizei = undefined;

    c.glGetProgramInfoLog(@enumToInt(program), cs2gl(log.len), &actual_length, log.ptr);
    checkError();

    log[@intCast(usize, actual_length)] = 0;

    return log[0..@intCast(usize, actual_length) :0];
}

pub fn getUniformLocation(program: Program, name: [:0]const u8) ?u32 {
    const loc = c.glGetUniformLocation(@enumToInt(program), name.ptr);
    checkError();
    if (loc < 0)
        return null;
    return @intCast(u32, loc);
}

///////////////////////////////////////////////////////////////////////////////
// Uniforms

pub fn programUniform1u(program: Program, location: ?u32, value: u32) void {
    if (location) |loc| {
        c.glProgramUniform1u(@enumToInt(program), @intCast(c.GLint, loc), value);
        checkError();
    }
}

pub fn programUniform1i(program: Program, location: ?u32, value: i32) void {
    if (location) |loc| {
        c.glProgramUniform1i(@enumToInt(program), @intCast(c.GLint, loc), value);
        checkError();
    }
}

pub fn programUniform1f(program: Program, location: ?u32, value: f32) void {
    if (location) |loc| {
        c.glProgramUniform1f(@enumToInt(program), @intCast(c.GLint, loc), value);
        checkError();
    }
}

pub fn programUniform3f(program: Program, location: ?u32, x: f32, y: f32, z: f32) void {
    if (location) |loc| {
        c.glProgramUniform3f(@enumToInt(program), @intCast(c.GLint, loc), x, y, z);
        checkError();
    }
}

pub fn programUniform4f(program: Program, location: ?u32, x: f32, y: f32, z: f32, w: f32) void {
    if (location) |loc| {
        c.glProgramUniform4f(@enumToInt(program), @intCast(c.GLint, loc), x, y, z, w);
        checkError();
    }
}

pub fn programUniformMatrix4(program: Program, location: ?u32, transpose: bool, items: []const [4][4]f32) void {
    if (location) |loc| {
        c.glProgramUniformMatrix4fv(
            @enumToInt(program),
            @intCast(c.GLint, loc),
            cs2gl(items.len),
            b2gl(transpose),

            @ptrCast(*const f32, items.ptr),
        );
        checkError();
    }
}

pub fn uniform1i(location: ?u32, value: i32) void {
    if (location) |loc| {
        c.glUniform1i(@intCast(c.GLint, loc), value);
        checkError();
    }
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

pub fn drawArrays(primitiveType: PrimitiveType, first: usize, count: usize) void {
    c.glDrawArrays(@enumToInt(primitiveType), cs2gl(first), cs2gl(count));
    checkError();
}

pub const ElementType = enum(c.GLenum) {
    u8 = c.GL_UNSIGNED_BYTE,
    u16 = c.GL_UNSIGNED_SHORT,
    u32 = c.GL_UNSIGNED_INT,
};

pub fn drawElements(primitiveType: PrimitiveType, count: usize, element_type: ElementType, indices: ?*const c_void) void {
    c.glDrawElements(
        @enumToInt(primitiveType),
        cs2gl(count),
        @enumToInt(element_type),
        indices,
    );
    checkError();
}

pub fn drawElementsInstanced(primitiveType: PrimitiveType, count: usize, element_type: ElementType, indices: ?*const c_void, instance_count: usize) void {
    c.glDrawElementsInstanced(
        @enumToInt(primitiveType),
        cs2gl(count),
        @enumToInt(element_type),
        indices,
        cs2gl(instance_count),
    );
    checkError();
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

pub fn depthMask(enabled: bool) void {
    c.glDepthMask(if (enabled) c.GL_TRUE else c.GL_FALSE);
    checkError();
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

pub fn depthFunc(func: DepthFunc) void {
    c.glDepthFunc(@enumToInt(func));
    checkError();
}

pub const BlendFactor = enum(c.GLenum) {
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
    one_minus_constant_alpha = c.GL_ONE_MINUS_CONSTANT_ALPHA
};

pub fn blendFunc(sfactor: BlendFactor, dfactor: BlendFactor) void {
    c.glBlendFunc(@enumToInt(sfactor), @enumToInt(dfactor));
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

pub const TextureTarget = enum(c.GLenum) {
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

pub fn createTexture(texture_target: TextureTarget) Texture {
    var tex_name: c.GLuint = undefined;

    c.glCreateTextures(@enumToInt(texture_target), 1, &tex_name);
    checkError();

    const texture = @intToEnum(Texture, tex_name);
    if (texture == .invalid) {
        checkError();
        unreachable;
    }
    return texture;
}

pub fn deleteTexture(texture: Texture) void {
    var id = @enumToInt(texture);
    c.glDeleteTextures(1, &id);
}

pub fn bindTextureUnit(texture: Texture, unit: u32) void {
    c.glBindTextureUnit(unit, @enumToInt(texture));
    checkError();
}

pub fn bindTexture(texture: Texture, target: TextureTarget) void {
    c.glBindTexture(@enumToInt(target), @enumToInt(texture));
    checkError();
}

pub fn activeTexture(texture_unit: TextureUnit) void {
    c.glActiveTexture(@enumToInt(texture_unit));
    checkError();
}

pub const TextureUnit = enum(c.GLenum) {
    texture_0 = c.GL_TEXTURE0,
    texture_1 = c.GL_TEXTURE1,
    texture_2 = c.GL_TEXTURE2,
};

pub const TextureParameter = enum(c.GLenum) {
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
        .wrap_s, .wrap_t, .wrap_r => enum(c.GLint) {
            clamp_to_edge = c.GL_CLAMP_TO_EDGE,
            clamp_to_border = c.GL_CLAMP_TO_BORDER,
            mirrored_repeat = c.GL_MIRRORED_REPEAT,
            repeat = c.GL_REPEAT,
            mirror_clamp_to_edge = c.GL_MIRROR_CLAMP_TO_EDGE,
        },
        .mag_filter => enum(c.GLint) {
            nearest = c.GL_NEAREST,
            linear = c.GL_LINEAR,
        },
        .min_filter => enum(c.GLint) {
            nearest = c.GL_NEAREST,
            linear = c.GL_LINEAR,
            nearest_mipmap_nearest = c.GL_NEAREST_MIPMAP_NEAREST,
            linear_mipmap_nearest = c.GL_LINEAR_MIPMAP_NEAREST,
            nearest_mipmap_linear = c.GL_NEAREST_MIPMAP_LINEAR,
            linear_mipmap_linear = c.GL_LINEAR_MIPMAP_LINEAR,
        },
        .compare_mode => enum(c.GLint) {
            none = c.GL_NONE,
        },
        else => @compileError("textureParameter not implemented yet for " ++ @tagName(param)),
    };
}

pub fn textureParameter(texture: Texture, comptime parameter: TextureParameter, value: TextureParameterType(parameter)) void {
    const T = TextureParameterType(parameter);
    const info = @typeInfo(T);

    if (info == .Enum) {
        c.glTextureParameteri(@enumToInt(texture), @enumToInt(parameter), @enumToInt(value));
    } else {
        @compileError(@tagName(info) ++ " is not supported yet by textureParameter");
    }
    checkError();
}

pub const TextureInternalFormat = enum(c.GLenum) {
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
    texture: Texture,
    levels: usize,
    internalformat: TextureInternalFormat,
    width: usize,
    height: usize,
) void {
    c.glTextureStorage2D(
        @enumToInt(texture),
        @intCast(c.GLsizei, levels),
        @enumToInt(internalformat),
        @intCast(c.GLsizei, width),
        @intCast(c.GLsizei, height),
    );
    checkError();
}

pub fn textureStorage3D(
    texture: Texture,
    levels: usize,
    internalformat: TextureInternalFormat,
    width: usize,
    height: usize,
    depth: usize,
) void {
    c.glTextureStorage3D(
        @enumToInt(texture),
        @intCast(c.GLsizei, levels),
        @enumToInt(internalformat),
        @intCast(c.GLsizei, width),
        @intCast(c.GLsizei, height),
        @intCast(c.GLsizei, depth),
    );
    checkError();
}

pub const PixelFormat = enum(c.GLenum) {
    red = c.GL_RED,
    rg = c.GL_RG,
    rgb = c.GL_RGB,
    bgr = c.GL_BGR,
    rgba = c.GL_RGBA,
    bgra = c.GL_BGRA,
    depth_component = c.GL_DEPTH_COMPONENT,
    stencil_index = c.GL_STENCIL_INDEX,
};

pub const PixelType = enum(c.GLenum) {
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
    data: [*]const u8,
) void {
    c.glTexImage2D(
        @enumToInt(texture),
        @intCast(c.GLint, level),
        @intCast(c.GLint, @enumToInt(pixel_internal_format)),
        @intCast(c.GLsizei, width),
        @intCast(c.GLsizei, height),
        0,
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        data,
    );
    checkError();
}

pub fn textureSubImage2D(
    texture: Texture,
    level: usize,
    xoffset: usize,
    yoffset: usize,
    width: usize,
    height: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    data: [*]const u8,
) void {
    c.glTextureSubImage2D(
        @enumToInt(texture),
        @intCast(c.GLint, level),
        @intCast(c.GLint, xoffset),
        @intCast(c.GLint, yoffset),
        @intCast(c.GLsizei, width),
        @intCast(c.GLsizei, height),
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        data,
    );
    checkError();
}

pub fn textureSubImage3D(
    texture: Texture,
    level: usize,
    xoffset: usize,
    yoffset: usize,
    zoffset: usize,
    width: usize,
    height: usize,
    depth: usize,
    pixel_format: PixelFormat,
    pixel_type: PixelType,
    pixels: [*]const u8,
) void {
    c.glTextureSubImage3D(
        @enumToInt(texture),
        @intCast(c.GLint, level),
        @intCast(c.GLint, xoffset),
        @intCast(c.GLint, yoffset),
        @intCast(c.GLint, zoffset),
        @intCast(c.GLsizei, width),
        @intCast(c.GLsizei, height),
        @intCast(c.GLsizei, depth),
        @enumToInt(pixel_format),
        @enumToInt(pixel_type),
        pixels,
    );
    checkError();
}

pub const PixelStoreParameter = enum(c.GLenum) {
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
    c.glPixelStorei(@enumToInt(param), @intCast(c.GLint, value));
    checkError();
}

pub fn viewport(x: i32, y: i32, width: usize, height: usize) void {
    c.glViewport(@intCast(c.GLint, x), @intCast(c.GLint, y), @intCast(c.GLsizei, width), @intCast(c.GLsizei, height));
    checkError();
}

pub const FramebufferTarget = enum(c.GLenum) {
    buffer = c.GL_FRAMEBUFFER,
};

pub const Framebuffer = enum(c.GLuint) {
    invalid = 0,
    _,

    pub const create = createFramebuffer;
    pub const bind = bindFrameBuffer;
    pub const texture = framebufferTexture;
    pub const checkStatus = checkFramebufferStatus;
};

pub fn createFramebuffer() Framebuffer {
    var fb_name: c.GLuint = undefined;
    c.glCreateFramebuffers(1, &fb_name);
    checkError();
    const framebuffer = @intToEnum(Framebuffer, fb_name);
    if (framebuffer == .invalid) {
        checkError();
        unreachable;
    }
    return framebuffer;
}

pub fn bindFrameBuffer(buf: Framebuffer, target: FramebufferTarget) void {
    c.glBindFramebuffer(@enumToInt(target), @enumToInt(buf));
    checkError();
}

const FramebufferAttachment = enum(c.GLenum) {
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

pub fn framebufferTexture(buffer: Framebuffer, target: FramebufferTarget, attachment: FramebufferAttachment, texture: Texture, level: i32) void {
    buffer.bind(.buffer);
    c.glFramebufferTexture(@enumToInt(target), @enumToInt(attachment), @intCast(c.GLuint, @enumToInt(texture)), @intCast(c.GLint, level));
    checkError();
}

const FramebufferStatus = enum(c.GLuint) {
    complete = c.GL_FRAMEBUFFER_COMPLETE,
};

pub fn checkFramebufferStatus(target: FramebufferTarget) FramebufferStatus {
    const status = @intToEnum(FramebufferStatus, c.glCheckFramebufferStatus(@enumToInt(target)));
    return status;
}

pub fn drawBuffers(bufs: []const FramebufferAttachment) void {
    c.glDrawBuffers(cs2gl(bufs.len), @ptrCast([*]const c.GLuint, bufs.ptr));
}
