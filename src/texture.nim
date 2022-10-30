import nimgl/opengl
import ../vendor/stb_image/read as stbi
import os

type
  Texture* = ref object
    rendererId*: uint32
    filepath*: string
    localBuffer*: seq[byte]
    width*: int
    height*: int
    bpp*: int


proc newTexture*(filepath: string): Texture =
  result = Texture(filepath: filepath)
  stbi.setFlipVerticallyOnLoad(true)
  result.localBuffer = stbi.load(filepath, result.width, result.height, result.bpp, 4)
  glGenTextures(1, result.rendererId.addr)
  glBindTexture(GL_TEXTURE_2D, result.rendererId)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.int32)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.int32)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.int32)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.int32)

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8.int32, result.width.int32, result.height.int32, 0,
               GL_RGBA, GL_UNSIGNED_BYTE, result.localBuffer[0].addr)
  glGenerateMipmap(GL_TEXTURE_2D)

  result.localBuffer = @[]

proc `bind`*(texture: Texture, offset: uint32 = 0) =
  if texture.rendererId + offset < 16:
    glActiveTexture(GLenum(GL_TEXTURE0.ord + offset + texture.rendererId))
  glBindTexture(GL_TEXTURE_2D, texture.rendererId)

proc unbind*(texture: Texture) =
  glBindTexture(GL_TEXTURE_2D, 0)
