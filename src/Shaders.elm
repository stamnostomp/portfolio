module Shaders exposing (Uniforms, backgroundFragmentShader, vertexShader)

import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import WebGL



-- Define a record type for our uniforms to ensure consistency


type alias Uniforms =
    { time : Float
    , resolution : Vec2.Vec2
    }



-- Common vertex shader for fullscreen quads


vertexShader : WebGL.Shader { position : Vec3.Vec3 } Uniforms { vUV : Vec2.Vec2 }
vertexShader =
    [glsl|
        attribute vec3 position;
        uniform float time;
        uniform vec2 resolution;
        varying vec2 vUV;

        void main() {
            gl_Position = vec4(position, 1.0);
            vUV = position.xy * 0.5 + 0.5;
        }
    |]



-- Simple background shader with retro grid effect


backgroundFragmentShader : WebGL.Shader {} Uniforms { vUV : Vec2.Vec2 }
backgroundFragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        varying vec2 vUV;

        float grid(vec2 uv, float res) {
            vec2 grid = fract(uv * res);
            return (step(0.98, grid.x) + step(0.98, grid.y)) * 0.5;
        }

        void main() {
            // Dark background
            vec3 color = vec3(0.03, 0.04, 0.05);

            // Calculate distorted UVs for cyber effect
            vec2 uv = vUV;
            uv.y += sin(uv.x * 10.0 + time * 0.5) * 0.01;

            // Add subtle grid
            float gridVal = grid(uv, 50.0) * 0.15;
            color += vec3(gridVal);

            // Add horizontal scan lines
            float scanline = sin(uv.y * 500.0) * 0.5 + 0.5;
            color *= 0.8 + scanline * 0.2;

            // Vignette effect
            float vignette = length(vUV - 0.5) * 1.0;
            color *= 1.0 - vignette * 0.8;

            gl_FragColor = vec4(color, 1.0);
        }
    |]
