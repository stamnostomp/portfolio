-- src/Shaders/GoopBall.elm


module Shaders.GoopBall exposing (GoopAttributes, GoopUniforms, fragmentShader, vertexShader)

import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import WebGL



-- Types for the goop navigation


type alias GoopUniforms =
    { time : Float
    , resolution : Vec2.Vec2
    , mousePosition : Vec2.Vec2
    , hoveredBranch : Float -- -1 for none, 0-7 for branch index
    , centerPosition : Vec2.Vec2
    }


type alias GoopAttributes =
    { position : Vec3.Vec3
    }



-- Vertex shader (same as your existing one)


vertexShader : WebGL.Shader GoopAttributes GoopUniforms { vUV : Vec2.Vec2 }
vertexShader =
    [glsl|
        attribute vec3 position;
        uniform vec2 resolution;
        varying vec2 vUV;

        void main() {
            gl_Position = vec4(position, 1.0);
            vUV = position.xy * 0.5 + 0.5;
        }
    |]



-- Fragment shader for the goop ball effect


fragmentShader : WebGL.Shader {} GoopUniforms { vUV : Vec2.Vec2 }
fragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        uniform float hoveredBranch;
        uniform vec2 centerPosition;
        varying vec2 vUV;

        // Smooth minimum function for organic blending
        float smin(float a, float b, float k) {
            float h = max(k - abs(a - b), 0.0) / k;
            return min(a, b) - h * h * h * k * (1.0 / 6.0);
        }

        // Distance to a circle
        float circle(vec2 p, vec2 center, float radius) {
            return length(p - center) - radius;
        }

        // Distance to a capsule (rounded line)
        float capsule(vec2 p, vec2 a, vec2 b, float r) {
            vec2 pa = p - a;
            vec2 ba = b - a;
            float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
            return length(pa - ba * h) - r;
        }

        // Create the goop ball and branches
        float goopSDF(vec2 p) {
            vec2 center = centerPosition;

            // Main goop ball
            float mainBall = circle(p, center, 0.08);

            // Branch positions (8 directions)
            vec2 branches[8];
            branches[0] = center + vec2(0.0, -0.15);      // Top
            branches[1] = center + vec2(0.12, -0.1);      // Top Right
            branches[2] = center + vec2(0.18, 0.0);       // Right
            branches[3] = center + vec2(0.12, 0.15);      // Bottom Right
            branches[4] = center + vec2(0.0, 0.18);       // Bottom
            branches[5] = center + vec2(-0.12, 0.15);     // Bottom Left
            branches[6] = center + vec2(-0.18, 0.0);      // Left
            branches[7] = center + vec2(-0.12, -0.1);     // Top Left

            float result = mainBall;

            // Add branches with organic connections
            for (int i = 0; i < 8; i++) {
                float fi = float(i);

                // Branch size varies based on hover
                float branchSize = 0.025;
                if (hoveredBranch == fi) {
                    branchSize = 0.035 + 0.01 * sin(time * 8.0);
                }

                // Create branch end
                float branchBall = circle(p, branches[i], branchSize);

                // Create organic connection to center
                float connection = capsule(p, center, branches[i], 0.015);

                // Smooth blend everything together
                result = smin(result, branchBall, 0.02);
                result = smin(result, connection, 0.015);
            }

            return result;
        }

        // Generate metallic color based on position and SDF
        vec3 getMetallicColor(vec2 p, float sdf) {
            // Base colors: black to silver gradient
            vec3 silver = vec3(0.8, 0.85, 0.9);
            vec3 darkGray = vec3(0.15, 0.15, 0.18);
            vec3 black = vec3(0.05, 0.05, 0.08);

            // Distance-based coloring
            float t = 1.0 - smoothstep(0.0, 0.02, abs(sdf));

            // Add some metallic reflection based on position
            vec2 center = centerPosition;
            vec2 toCenter = normalize(p - center);
            float reflection = 0.5 + 0.5 * dot(toCenter, vec2(0.3, 0.7));

            // Animate the metallic sheen
            float sheen = 0.5 + 0.5 * sin(time * 2.0 + p.x * 10.0 + p.y * 15.0);

            // Mix colors based on reflection and sheen
            vec3 baseColor = mix(black, darkGray, reflection);
            vec3 highlightColor = mix(darkGray, silver, sheen * 0.3);

            return mix(baseColor, highlightColor, t * reflection);
        }

        void main() {
            // Convert to shader coordinates
            vec2 uv = vUV;
            vec2 p = (uv - 0.5) * 2.0;
            p.x *= resolution.x / resolution.y;  // Maintain aspect ratio

            // Get distance to goop shape
            float sdf = goopSDF(p);

            // Create the goop
            float goop = smoothstep(0.01, 0.0, sdf);

            // Get metallic color
            vec3 color = getMetallicColor(p, sdf);

            // Add glow effect for hovered branches
            float glow = 0.0;
            if (hoveredBranch >= 0.0) {
                glow = 0.3 * exp(-sdf * 50.0);
                color += vec3(0.0, 0.5, 1.0) * glow;
            }

            // Combine with your existing background
            vec3 bgColor = vec3(0.08, 0.09, 0.11);  // From your Background.elm
            vec3 finalColor = mix(bgColor, color, goop);
            finalColor += vec3(glow * 0.1);

            gl_FragColor = vec4(finalColor, 1.0);
        }
    |]
