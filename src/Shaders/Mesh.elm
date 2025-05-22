module Shaders.Mesh exposing (fullscreenMesh, vertexShader)

import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import Shaders.Types exposing (Uniforms)
import WebGL



-- Common vertex shader for all fragments


vertexShader : WebGL.Shader { position : Vec3.Vec3 } Uniforms { vUV : Vec2.Vec2 }
vertexShader =
    [glsl|
        attribute vec3 position;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        uniform float hoveredBranch;
        uniform vec2 centerPosition;
        varying vec2 vUV;

        void main() {
            gl_Position = vec4(position, 1.0);
            vUV = position.xy * 0.5 + 0.5;
        }
    |]



-- Fullscreen quad mesh


fullscreenMesh : WebGL.Mesh { position : Vec3.Vec3 }
fullscreenMesh =
    WebGL.triangles
        [ ( { position = Vec3.vec3 -1 -1 0 }
          , { position = Vec3.vec3 1 -1 0 }
          , { position = Vec3.vec3 1 1 0 }
          )
        , ( { position = Vec3.vec3 -1 -1 0 }
          , { position = Vec3.vec3 1 1 0 }
          , { position = Vec3.vec3 -1 1 0 }
          )
        ]
