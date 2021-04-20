const c = @cImport({
    @cInclude("epoxy/gl.h");
});

const gl = @import("zgl.zig");

pub const VertexArray = enum(c.GLuint) {
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

pub const Buffer = enum(c.GLuint) {
    invalid = 0,
    _,

    pub const create = gl.createBuffer;
    pub const gen = gl.genBuffer;
    pub const bind = gl.bindBuffer;
    pub const delete = gl.deleteBuffer;
    pub const data = gl.namedBufferData;
};

pub const Shader = enum(c.GLuint) {
    invalid = 0,
    _,

    pub const create = gl.createShader;
    pub const delete = gl.deleteShader;

    pub const compile = gl.compileShader;
    pub const source = gl.shaderSource;

    pub const get = gl.getShader;
    pub const getCompileLog = gl.getShaderInfoLog;
};

pub const Program = enum(c.GLuint) {
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
    pub const uniform1f = gl.programUniform1f;
    pub const uniform3f = gl.programUniform3f;
    pub const uniform4f = gl.programUniform4f;
    pub const uniformMatrix4 = gl.programUniformMatrix4;

    pub const get = gl.getProgram;
    pub const getCompileLog = gl.getProgramInfoLog;
    pub const uniformLocation = gl.getUniformLocation;
};

pub const Texture = enum(c.GLuint) {
    invalid = 0,
    _,

    pub const create = gl.createTexture;
    pub const delete = gl.deleteTexture;

    pub const bindTo = gl.bindTextureUnit;

    pub const parameter = gl.textureParameter;

    pub const storage2D = gl.textureStorage2D;
    pub const storage3D = gl.textureStorage3D;

    pub const subImage2D = gl.textureSubImage2D;
    pub const subImage3D = gl.textureSubImage3D;
};
