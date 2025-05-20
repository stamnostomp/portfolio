module Shaders exposing (Uniforms, backgroundShader, glitchShader, gridShader, terminalShader)

import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import WebGL



-- UNIFORM TYPES


type alias Uniforms =
    { time : Float
    , resolution : Vec2.Vec2
    , mousePosition : Vec2.Vec2
    }



-- VERTEX SHADER
-- Common vertex shader for all full-screen effects


vertexShader : WebGL.Shader { position : Vec3.Vec3 } Uniforms { vUV : Vec2.Vec2 }
vertexShader =
    [glsl|
        attribute vec3 position;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        varying vec2 vUV;

        void main() {
            gl_Position = vec4(position, 1.0);
            vUV = position.xy * 0.5 + 0.5;
        }
    |]



-- BACKGROUND SHADER
-- Dark background with subtle CRT scanlines


backgroundShader : WebGL.Shader {} Uniforms { vUV : Vec2.Vec2 }
backgroundShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        varying vec2 vUV;

        void main() {
            // Base dark color
            vec3 color = vec3(0.06, 0.06, 0.08);

            // Add subtle scan lines
            float scanline = sin(vUV.y * resolution.y * 0.5) * 0.03;
            color -= vec3(scanline);

            // Add vignette effect for CRT look
            float vignette = length(vUV - 0.5) * 1.2;
            color = mix(color, vec3(0.02, 0.02, 0.04), vignette);

            // Add subtle flicker
            float flicker = sin(time * 5.0) * 0.01;
            color += vec3(flicker);

            gl_FragColor = vec4(color, 1.0);
        }
    |]



-- GRID SHADER
-- Creates a Y2K-style grid overlay


gridShader : WebGL.Shader {} Uniforms { vUV : Vec2.Vec2 }
gridShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        varying vec2 vUV;

        float grid(vec2 uv, float res) {
            vec2 grid = fract(uv * res);
            return (step(0.98, grid.x) + step(0.98, grid.y)) * 0.4;
        }

        void main() {
            // Create distorted UVs for cyber effect
            vec2 uv = vUV;
            uv.y += sin(uv.x * 10.0 + time * 0.2) * 0.01;

            // Create grid pattern
            float smallGrid = grid(uv, 40.0);
            float largeGrid = grid(uv, 10.0) * 0.3;

            // Combine grids
            float gridPattern = smallGrid + largeGrid;
            vec3 gridColor = vec3(0.2, 0.2, 0.25) * gridPattern;

            // Add mouse highlight
            vec2 mouseUV = mousePosition / resolution;
            float mouseDistance = length(uv - mouseUV) * 3.0;
            float mouseMask = smoothstep(0.4, 1.0, mouseDistance);
            gridColor = mix(vec3(0.3, 0.3, 0.4) * gridPattern, gridColor, mouseMask);

            gl_FragColor = vec4(gridColor, gridPattern * 0.7);
        }
    |]



-- GLITCH SHADER
-- Creates digital glitch/distortion effects for text


glitchShader : WebGL.Shader {} Uniforms { vUV : Vec2.Vec2 }
glitchShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        varying vec2 vUV;

        // Hash function for noise
        float hash(vec2 p) {
            return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
        }

        void main() {
            vec2 uv = vUV;
            vec3 color = vec3(0.0);

            // Apply horizontal glitch slices
            float sliceY = floor(uv.y * 20.0) / 20.0;
            float sliceH = 1.0 / 20.0;

            // Only apply glitch to some slices
            float sliceGlitch = step(0.8, hash(vec2(sliceY, floor(time * 5.0))));

            // Offset X based on glitch
            float glitchAmount = hash(vec2(sliceY, floor(time * 5.0))) * 2.0 - 1.0;
            glitchAmount *= 0.1 * sliceGlitch; // Scale the effect

            // Apply the glitch offset
            uv.x += glitchAmount;

            // RGB split
            float rChannel = step(0.2, hash(vec2(uv.y, time))) * 0.15 * sliceGlitch;

            // Build the final color with glitch effect
            if (uv.x < 0.1 || uv.x > 0.9 || uv.y < 0.1 || uv.y > 0.9) {
                color = vec3(0.0); // Black border
            } else {
                // Create some lines for a "text" effect
                float line = step(0.4, hash(vec2(floor(uv.y * 30.0), floor(uv.x * 5.0))));
                color = vec3(line) * vec3(0.8, 0.8, 0.9); // Light gray

                // Add glitch colors
                color.r += rChannel;
                color.b -= rChannel * 0.5;
            }

            // Add scanlines for terminal effect
            float scanline = sin(uv.y * resolution.y * 0.8) * 0.05;
            color -= vec3(scanline);

            gl_FragColor = vec4(color, step(0.01, length(color)));
        }
    |]



-- TERMINAL SHADER
-- Creates a green terminal/matrix style effect


terminalShader : WebGL.Shader {} Uniforms { vUV : Vec2.Vec2 }
terminalShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        varying vec2 vUV;

        // Hash function for randomness
        float hash(vec2 p) {
            return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
        }

        void main() {
            vec2 uv = vUV;

            // Create a grid for character cells
            vec2 cellSize = vec2(resolution.x / 40.0, resolution.y / 25.0);
            vec2 cell = floor(uv * resolution / cellSize);

            // Calculate character change frequency
            float charChangeSpeed = hash(cell) * 3.0 + 1.0;
            float charIndex = floor(time * charChangeSpeed);

            // Generate "characters" - just random blocks for now
            float char = hash(vec2(cell.x, cell.y + charIndex));

            // Create terminal character effect
            float brightness = char * step(0.5, char) * 0.7;

            // Apply scanlines for terminal effect
            float scanline = sin(uv.y * resolution.y) * 0.05;
            brightness -= scanline;

            // Dim characters that are "farther away" from cursor
            vec2 mouseCell = mousePosition / cellSize;
            float distanceToMouse = length(cell - mouseCell) / 20.0;
            brightness *= max(0.4, 1.0 - distanceToMouse);

            // Add green terminal color
            vec3 color = vec3(0.0, brightness * 0.8, brightness * 0.4);

            // Add subtle flicker
            float flicker = sin(time * 10.0 + cell.y) * 0.03 + 0.97;
            color *= flicker;

            gl_FragColor = vec4(color, 1.0);
        }
    |]
