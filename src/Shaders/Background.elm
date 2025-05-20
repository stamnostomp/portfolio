module Shaders.Background exposing (fragmentShader)

import Shaders.Types exposing (Uniforms)
import WebGL


fragmentShader : WebGL.Shader {} Uniforms { vUV : Vec2.Vec2 }
fragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        varying vec2 vUV;

        float hash(vec2 p) {
            return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
        }

        void main() {
            // Base dark gray color
            vec3 color = vec3(0.08, 0.09, 0.11);

            // Add scanlines
            float scanline = sin(vUV.y * resolution.y * 0.25) * 0.5 + 0.5;
            color = mix(color, vec3(0.05, 0.06, 0.08), scanline * 0.2);

            // Add subtle vignette
            float vignette = 1.0 - length(vUV - 0.5) * 1.2;
            vignette = clamp(vignette, 0.0, 1.0);
            color *= vignette;

            // Add noise
            float noise = hash(vUV * 100.0 + time * 0.1) * 0.03;
            color += vec3(noise);

            gl_FragColor = vec4(color, 1.0);
        }
    |]
