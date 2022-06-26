const c = @cImport({
    @cInclude("epoxy/gl.h");
});

const gl = @import("zgl.zig");

pub const Boolean = c.GLboolean;
pub const Byte = c.GLbyte;
pub const UByte = c.GLubyte;
pub const Char = c.GLchar;
pub const Short = c.GLshort;
pub const UShort = c.GLushort;
pub const Int = c.GLint;
pub const UInt = c.GLuint;
pub const Fixed = c.GLfixed;
pub const Int64 = c.GLint64;
pub const UInt64 = c.GLuint64;
pub const SizeI = c.GLsizei;
pub const Enum = c.GLenum;
pub const IntPtr = c.GLintptr;
pub const SizeIPtr = c.GLsizeiptr;
pub const Sync = c.GLsync;
pub const BitField = c.GLbitfield;
pub const Half = c.GLhalf;
pub const Float = c.GLfloat;
pub const ClampF = c.GLclampf;
pub const Double = c.GLdouble;
pub const ClampD = c.GLclampd;

pub const VertexArray = enum(UInt) {
    invalid = 0,
    _,

    pub const create = gl.createVertexArray;
    pub const delete = gl.deleteVertexArray;
    pub const gen = gl.genVertexArray;
    pub const bind = gl.bindVertexArray;
    pub const enableVertexAttribute = gl.enableVertexArrayAttrib;
    pub const disableVertexAttribute = gl.disableVertexArrayAttrib;

    pub const attribFormat = gl.vertexArrayAttribFormat;
    pub const attribIFormat = gl.vertexArrayAttribIFormat;
    pub const attribLFormat = gl.vertexArrayAttribLFormat;

    pub const attribBinding = gl.vertexArrayAttribBinding;

    pub const vertexBuffer = gl.vertexArrayVertexBuffer;
    pub const elementBuffer = gl.vertexArrayElementBuffer;
};

pub const Buffer = enum(UInt) {
    invalid = 0,
    _,

    pub const create = gl.createBuffer;
    pub const gen = gl.genBuffer;
    pub const bind = gl.bindBuffer;
    pub const delete = gl.deleteBuffer;
    pub const data = gl.namedBufferData;
    pub const storage = gl.namedBufferStorage;
    pub const mapRange = gl.mapNamedBufferRange;
    pub const unmap = gl.unmapNamedBuffer;
};

pub const Shader = enum(UInt) {
    invalid = 0,
    _,

    pub const create = gl.createShader;
    pub const delete = gl.deleteShader;

    pub const compile = gl.compileShader;
    pub const source = gl.shaderSource;

    pub const get = gl.getShader;
    pub const getCompileLog = gl.getShaderInfoLog;
};

pub const Program = enum(UInt) {
    invalid = 0,
    _,

    pub const create = gl.createProgram;
    pub const delete = gl.deleteProgram;

    pub const attach = gl.attachShader;
    pub const detach = gl.detachShader;

    pub const link = gl.linkProgram;

    pub const use = gl.useProgram;

    pub const uniform1ui = gl.programUniform1ui;
    pub const uniform1i = gl.programUniform1i;
    pub const uniform3ui = gl.programUniform3ui;
    pub const uniform3i = gl.programUniform3i;
    pub const uniform2i = gl.programUniform2i;
    pub const uniform1f = gl.programUniform1f;
    pub const uniform2f = gl.programUniform2f;
    pub const uniform3f = gl.programUniform3f;
    pub const uniform4f = gl.programUniform4f;
    pub const uniformMatrix4 = gl.programUniformMatrix4;

    pub const get = gl.getProgram;
    pub const getCompileLog = gl.getProgramInfoLog;
    pub const uniformLocation = gl.getUniformLocation;
};

pub const Texture = enum(UInt) {
    invalid = 0,
    _,

    pub const create = gl.createTexture;
    pub const gen = gl.genTexture;
    pub const delete = gl.deleteTexture;

    pub const bind = gl.bindTexture;
    pub const bindTo = gl.bindTextureUnit;

    pub const parameter = gl.textureParameter;

    pub const storage2D = gl.textureStorage2D;
    pub const storage3D = gl.textureStorage3D;

    pub const subImage2D = gl.textureSubImage2D;
    pub const subImage3D = gl.textureSubImage3D;

    pub const generateMipmap = gl.generateTextureMipmap;
};
