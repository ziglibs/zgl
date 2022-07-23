const root = @import("root");

pub usingnamespace if (@hasDecl(root, "gl"))
    root.gl
else
    @cImport({
        @cInclude("epoxy/gl.h");
    });
