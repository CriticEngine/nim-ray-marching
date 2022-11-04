import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]
import glm
import os
import src/[texture, glsl]

var 
  cursorX: float64 = 0f
  cursorY: float64 = 0f
  window_width: int32 = 1280
  window_height: int32 = 720 
  scroll: GLFloat = 3f


if os.getEnv("CI") != "":
  quit()

proc keyProc(window: GLFWWindow, key: int32, scancode: int32, action: int32,
    mods: int32): void {.cdecl.} =
  if key == GLFWKey.Escape and action == GLFWPress:
    window.setWindowShouldClose(true)
  if key == GLFWKey.LeftAlt and action == GLFWPress:
    window.setInputMode(GLFWCursorSpecial, GLFW_CURSOR_NORMAL)
  if key == GLFWKey.LeftAlt and action == GLFWRelease:
    window.setInputMode(GLFWCursorSpecial, GLFW_CURSOR_DISABLED)
    window.setCursorPos(cursorX, cursorY)

proc scrollProc(window: GLFWWindow, xoffset: float64; yoffset: float64): void {.cdecl.} =
  scroll += yoffset/20

proc getMouseDX(window: GLFWWindow): Vec2[GLFloat] =
  var
    d_cursorX: float64 = 0f
    d_cursorY: float64 = 0f
  if window.getInputMode(GLFWCursorSpecial) == GLFW_CURSOR_DISABLED:
    window.getCursorPos(addr cursorX, addr cursorY)  
  d_cursorX = cursorX    
  d_cursorY = - cursorY 
  result = vec2(d_cursorX.GLFloat, d_cursorY.GLFloat)


proc main(): void =
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 4)
  glfwWindowHint(GLFWContextVersionMinor, 6)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_FALSE)

  let w: GLFWWindow = glfwCreateWindow(window_width, window_height, "ray-marching", nil, nil)

  w.setInputMode(GLFWCursorSpecial, GLFW_CURSOR_DISABLED)
  w.getCursorPos(addr cursorX, addr cursorY)
  
  discard w.setKeyCallback(keyProc)
  discard w.setScrollCallback(scrollProc)
  w.makeContextCurrent

  echo "Vulkan supported: " & $glfwVulkanSupported()

  # Opengl
  doAssert glInit()
  echo "OpenGL " & $glVersionMajor & "." & $glVersionMinor
  # IG
  let context = igCreateContext()
  doAssert igGlfwInitForOpenGL(w, true)
  doAssert igOpenGL3Init()

  igStyleColorsCherry()

  var
    mesh: tuple[
      vbo,
      vao,
      ebo: uint32
    ]
    vertex: uint32
    fragment: uint32
    program: uint32

  var vert = @[
     1f, 1f,
    1f, -1f,
    -1f, -1f,
    -1f, 1f
  ]

  var ind = @[
    0'u32, 1'u32, 3'u32,
    1'u32, 2'u32, 3'u32
  ]

  glGenBuffers(1, mesh.vbo.addr)
  glGenBuffers(1, mesh.ebo.addr)
  glGenVertexArrays(1, mesh.vao.addr)

  glBindVertexArray(mesh.vao)

  glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ebo)

  glBufferData(GL_ARRAY_BUFFER, cint(cfloat.sizeof * vert.len), vert[0].addr, GL_STATIC_DRAW)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, cint(cuint.sizeof * ind.len), ind[
      0].addr, GL_STATIC_DRAW)

  glEnableVertexAttribArray(0)
  glVertexAttribPointer(0'u32, 2, EGL_FLOAT, false, cfloat.sizeof * 2, nil)

  vertex = glCreateShader(GL_VERTEX_SHADER)
  var vsrc: cstring = readShader("programs/vertex.glsl")
  glShaderSource(vertex, 1'i32, vsrc.addr, nil)
  glCompileShader(vertex)
  statusShader(vertex)

  fragment = glCreateShader(GL_FRAGMENT_SHADER)
  var fsrc: cstring = readShader("programs/fragment.glsl")
  glShaderSource(fragment, 1, fsrc.addr, nil)
  glCompileShader(fragment)
  statusShader(fragment)

  program = glCreateProgram()
  glAttachShader(program, vertex)
  glAttachShader(program, fragment)
  glLinkProgram(program)
  statusProgram(program)

  let
    u_resolution = glGetUniformLocation(program, "u_resolution")
    u_time = glGetUniformLocation(program, "u_time")
    u_mouse = glGetUniformLocation(program, "u_mouse")
    u_scroll = glGetUniformLocation(program, "u_scroll")
  var
    resolution: Vec2[GLFloat] = vec2(window_width.GLFloat, window_height.GLFloat)
    time: GLFloat = glfwGetTime()
    mouse: Vec2[GLFloat] = w.getMouseDX()


  var texture1 = newTexture("textures/test0.png")
  var texture2 = newTexture("textures/hex.png")  # floor 
  var texture3 = newTexture("textures/white_marble1.png")  # walls
  var texture4 = newTexture("textures/roof/texture3.jpg")  # roof
  var texture5 = newTexture("textures/black_marble1.png")  # pedestal
  var texture6 = newTexture("textures/green_marble1.png")  # sphere
  var texture7 = newTexture("textures/roof/height3.png")  # roof bump

  glUseProgram(program)

  let
    u_texture1 = glGetUniformLocation(program, "u_texture1")
    u_texture2 = glGetUniformLocation(program, "u_texture2")
    u_texture3 = glGetUniformLocation(program, "u_texture3")
    u_texture4 = glGetUniformLocation(program, "u_texture4")
    u_texture5 = glGetUniformLocation(program, "u_texture5")
    u_texture6 = glGetUniformLocation(program, "u_texture6")
    u_texture7 = glGetUniformLocation(program, "u_texture7")

  glUniform1i(u_texture1, 1)  
  glUniform1i(u_texture2, 2)  
  glUniform1i(u_texture3, 3) 
  glUniform1i(u_texture4, 4)  
  glUniform1i(u_texture5, 5) 
  glUniform1i(u_texture6, 6)  
  glUniform1i(u_texture7, 7)

  glUniform2fv(u_resolution, 1, resolution.caddr)

  glClearColor(33f/255, 33f/255, 33f/255, 1f)
  
  proc render(): void =    
    glClear(GL_COLOR_BUFFER_BIT)
    #
    texture1.`bind`
    texture2.`bind`
    texture3.`bind`
    texture4.`bind`
    texture5.`bind`
    texture6.`bind`
    texture7.`bind`
    #
    glUseProgram(program)
    glUniform1fv(u_time, 1, time.addr)
    glUniform2fv(u_mouse, 1, mouse.caddr)
    glUniform1fv(u_scroll, 1, scroll.addr) 
    #
    glBindVertexArray(mesh.vao)
    glDrawElements(GL_TRIANGLES, ind.len.cint, GL_UNSIGNED_INT, nil)

  proc imgui(): void = 
    # Simple window
    igBegin("DEBUG MENU")
    igText("OpenGL version " & $glVersionMajor & "." & $glVersionMinor) 
    igText("Time %10.3f ms ", time)
    igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / igGetIO().framerate, igGetIO().framerate)
    igEnd()
    # End simple window

  while not w.windowShouldClose:
    time = glfwGetTime()
    mouse = w.getMouseDX()

    igOpenGL3NewFrame()
    igGlfwNewFrame()
    igNewFrame()

    
    render()
    
    imgui()
    
    igRender()
    igOpenGL3RenderDrawData(igGetDrawData()) 

    w.swapBuffers
    glfwPollEvents()

  w.destroyWindow

  glfwTerminate()

  glDeleteVertexArrays(1, mesh.vao.addr)
  glDeleteBuffers(1, mesh.vbo.addr)
  glDeleteBuffers(1, mesh.ebo.addr)

# START MAIN
main()