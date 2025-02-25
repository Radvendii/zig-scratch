## Open tabs

- https://learnopengl.com/Getting-started/Textures
- https://interplayoflight.wordpress.com/2021/04/18/how-to-read-shader-assembly/
- https://www.khronos.org/opengl/wiki/Shader_Compilation#Shader_object_compilation
- https://github.com/nolanderc/glsl_analyzer

## TODO

- look into looping over all shader attributes and uniforms
  - SEE: https://stackoverflow.com/questions/440144/in-opengl-is-there-a-way-to-get-a-list-of-all-uniforms-attribs-used-by-a-shade
- can we compile glsl at compile time?
  - the issue is that it has to be compiled for the specific GPU
- combining thoes two ideas, can we have compile-time resolution of attributes and uniforms so they can be set with `prog.setFoo()`
