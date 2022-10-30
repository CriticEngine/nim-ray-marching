import nimgl/glfw
import nimgl/opengl
import glm
import os
import glsl

var 
  cursorX: float64 = 0f
  cursorY: float64 = 0f
  window_width: int32 = 1280
  window_height: int32 = 720 


if os.getEnv("CI") != "":
  quit()

proc keyProc(window: GLFWWindow, key: int32, scancode: int32, action: int32,
    mods: int32): void {.cdecl.} =
  if key == GLFWKey.Escape and action == GLFWPress:
    window.setWindowShouldClose(true)
  if key == GLFWKey.Space:
    glPolygonMode(GL_FRONT_AND_BACK, if action !=
        GLFWRelease: GL_LINE else: GL_FILL)


proc getMouseDX(window: GLFWWindow): Vec2[GLFloat] =
  var
    posX: float64 = 0f
    posY: float64 = 0f
    d_cursorX: float64 = 0f
    d_cursorY: float64 = 0f
  window.getCursorPos(addr posX, addr posY)  
  d_cursorY = cursorY - posY
  d_cursorX = cursorX - posX
  cursorX = round(window_width/2)
  cursorY = round(window_height/2)
  #window.setCursorPos(cursorX, cursorY) # when
  result = vec2(d_cursorX.GLFloat, d_cursorY.GLFloat)

proc main =
  # GLFW
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 4)
  glfwWindowHint(GLFWContextVersionMinor, 6)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_FALSE)

  let w: GLFWWindow = glfwCreateWindow(window_width, window_height, "ray-marching", nil, nil)
  w.getCursorPos(addr cursorX, addr cursorY)
  discard w.setKeyCallback(keyProc)
  w.makeContextCurrent

  # Opengl
  doAssert glInit()

  echo "Renderer: OpenGL " & $glVersionMajor & "." & $glVersionMinor

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
  var fsrc: cstring = readShader("programs/fragments.glsl")
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
  var
    resolution: Vec2[GLFloat] = vec2(window_width.GLFloat, window_height.GLFloat)
    time: GLFloat = glfwGetTime()
    mouse: Vec2[GLFloat] = w.getMouseDX()

  while not w.windowShouldClose:
    time = glfwGetTime()
    mouse = w.getMouseDX()

    glClearColor(33f/255, 33f/255, 33f/255, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    glUseProgram(program)
    glUniform2fv(u_resolution, 1, resolution.caddr)
    glUniform1fv(u_time, 1, time.addr)
    glUniform2fv(u_mouse, 1, mouse.caddr)

    glBindVertexArray(mesh.vao)
    glDrawElements(GL_TRIANGLES, ind.len.cint, GL_UNSIGNED_INT, nil)

    w.swapBuffers
    glfwPollEvents()

  w.destroyWindow

  glfwTerminate()

  glDeleteVertexArrays(1, mesh.vao.addr)
  glDeleteBuffers(1, mesh.vbo.addr)
  glDeleteBuffers(1, mesh.ebo.addr)

main()
