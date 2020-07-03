# ZGL – Zig OpenGL Bindings

This library provides a thin, type safe binding for OpenGL functions on top of `libepoxy`.

## Example

```zig
// Use classic OpenGL flavour
var vao = try gl.createVertexArray();
defer gl.deleteVertexArray(vao);

// Use object oriented flavour
var vertex_buffer = try gl.createBuffer();
defer vertex_buffer.delete();
```

## Development Philosophy

This libary is developed incremental. This means that functions will be included on-demand and not just for the sake of completeness.

If you think a function is missing, fork the library, implement the missing function similar to the other functions and make a pull request. Issues that request implementation of missing functions will be closed immediatly.