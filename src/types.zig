const binding = @import("binding.zig");
const gl = @import("zgl.zig");

pub const Boolean = binding.GLboolean;
pub const Byte = binding.GLbyte;
pub const UByte = binding.GLubyte;
pub const Char = binding.GLchar;
pub const Short = binding.GLshort;
pub const UShort = binding.GLushort;
pub const Int = binding.GLint;
pub const UInt = binding.GLuint;
pub const Fixed = binding.GLfixed;
pub const Int64 = binding.GLint64;
pub const UInt64 = binding.GLuint64;
pub const SizeI = binding.GLsizei;
pub const Enum = binding.GLenum;
pub const IntPtr = binding.GLintptr;
pub const SizeIPtr = binding.GLsizeiptr;
pub const Sync = binding.GLsync;
pub const BitField = binding.GLbitfield;
pub const Half = binding.GLhalf;
pub const Float = binding.GLfloat;
pub const ClampF = binding.GLclampf;
pub const Double = binding.GLdouble;
pub const ClampD = binding.GLclampd;

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
    pub const subData = gl.namedBufferSubData;
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
    pub const uniformBlockIndex = gl.getUniformBlockIndex;
};

pub const ProgramPipeline = enum(UInt) {
    invalid = 0,
    _,
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

pub const Renderbuffer = enum(UInt) {
    invalid = 0,
    _,

    pub const gen = gl.genRenderbuffer;
    pub const create = gl.createRenderbuffer;
    pub const delete = gl.deleteRenderbuffer;
    pub const bind = gl.bindRenderbuffer;
    pub const storage = gl.renderbufferStorage;
    pub const storageMultisample = gl.renderbufferStorageMultisample;
};

pub const Framebuffer = enum(UInt) {
    invalid = 0,
    _,

    pub const gen = gl.genFramebuffer;
    pub const create = gl.createFramebuffer;
    pub const delete = gl.deleteFramebuffer;
    pub const bind = gl.bindFramebuffer;
    pub const texture = gl.framebufferTexture;
    pub const texture2D = gl.framebufferTexture2D;
    pub const renderbuffer = gl.framebufferRenderbuffer;
    pub const checkStatus = gl.checkFramebufferStatus;
};
