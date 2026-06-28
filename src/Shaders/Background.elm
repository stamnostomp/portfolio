module Shaders.Background exposing (fragmentShader)

import Math.Vector2 as Vec2
import Shaders.Types exposing (Uniforms)
import WebGL


fragmentShader : WebGL.Shader {} Uniforms { vUV : Vec2.Vec2 }
fragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        uniform float hoveredBranch;
        uniform vec2 centerPosition;
        varying vec2 vUV;

        float hash(vec2 p) {
            return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
        }

        void main() {
            // Base dark gray color
            vec3 color = vec3(0.08, 0.09, 0.11);

            // Add wavy scanlines
            float waveFrequency = 0.25 * resolution.y;
            float waveAmplitude = 0.5;
            float waveSpeed = 0.5;

            // Create wavy pattern - the x position affects the phase of the y-based scanline
            float waveOffset = sin(vUV.x * 20.0 + time * waveSpeed) * waveAmplitude;
            float scanline = sin((vUV.y + waveOffset) * waveFrequency) * 0.5 + 0.5;

            // Add a second layer of waves with different frequency for more organic look
            float waveOffset2 = sin(vUV.x * 15.0 - time * waveSpeed * 0.7) * waveAmplitude * 0.7;
            float scanline2 = sin((vUV.y + waveOffset2) * waveFrequency * 1.3) * 0.5 + 0.5;

            // Combine both scanline patterns
            float combinedScanline = mix(scanline, scanline2, 0.5);
            color = mix(color, vec3(0.05, 0.06, 0.08), combinedScanline * 0.1);

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
