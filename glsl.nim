import os, system/io, std/re, strutils
import nimgl/opengl

## Compose shader file with dependencies
proc readShader*(filepath: string): cstring =
    var
        source = splitLines(readFile(filepath))
    let
        path = splitFile(filepath)
        reg = re(s = """^(\s*)?(#include)\s*\S+(\s*)?$""", flags = {reMultiLine})

    for line in 0..source.len-1:
        if source[line].find(reg) != -1:
            let file = source[line].splitWhitespace()
            source[line] = $readShader(path.dir & "/" & file[1])

    return join(source, "\n\r")

## (ECHO ERROR) 
proc statusShader*(shader: GLuint) =
    var status: int32
    glGetShaderiv(shader, GL_COMPILE_STATUS, status.addr);
    if status != GL_TRUE.ord:
        var
            log_length: int32
            message = newSeq[char](1024)
            res: string
        glGetShaderInfoLog(shader, 1024, log_length.addr, message[0].addr);
        for i in message:
            res &= i
        echo res

## (ECHO ERROR)
proc statusProgram*(program: GLuint) =
    var
        log_length: int32
        message = newSeq[char](1024)
        pLinked: int32
        res: string
    glGetProgramiv(program, GL_LINK_STATUS, pLinked.addr);
    if pLinked != GL_TRUE.ord:
        glGetProgramInfoLog(program, 1024, log_length.addr, message[0].addr);
        for i in message:
            res &= i
        echo res
