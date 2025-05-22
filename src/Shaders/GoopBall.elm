-- src/Shaders/GoopBall.elm - Working version with full goop ball


module Shaders.GoopBall exposing (GoopAttributes, fragmentShader, vertexShader)

import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import Shaders.Types exposing (Uniforms)
import WebGL


type alias GoopAttributes =
    { position : Vec3.Vec3
    }



-- Working vertex shader


vertexShader : WebGL.Shader GoopAttributes Uniforms { vUV : Vec2.Vec2 }
vertexShader =
    [glsl|
        precision mediump float;
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



-- Working fragment shader with full goop ball


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

        // Smooth minimum function for organic blending
        float smin(float a, float b, float k) {
            float h = clamp(k - abs(a - b), 0.0, k) / k;
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
            vec2 center = vec2(0.0, 0.0); // Use center of screen

            // Main goop ball - MADE BIGGER
            float mainBall = circle(p, center, 0.15);

            // Branch positions (8 directions) - WITH ORGANIC MOVEMENT RESTORED
            vec2 branches[8];

            // Add organic variation to branch lengths - RESTORED BEAUTIFUL MOVEMENT
            float var1 = 0.025 * sin(time * 0.8 + 0.0);
            float var2 = 0.020 * sin(time * 1.2 + 2.1);
            float var3 = 0.030 * sin(time * 0.6 + 4.2);
            float var4 = 0.018 * sin(time * 1.0 + 6.3);
            float var5 = 0.025 * sin(time * 0.9 + 1.5);
            float var6 = 0.022 * sin(time * 1.1 + 3.6);
            float var7 = 0.028 * sin(time * 0.7 + 5.7);
            float var8 = 0.024 * sin(time * 0.8 + 0.9);

            branches[0] = center + vec2(0.0, -0.25 + var1);           // Top
            branches[1] = center + vec2(0.18 + var2, -0.16 + var2*0.4); // Top Right
            branches[2] = center + vec2(0.28 + var3, 0.0);            // Right
            branches[3] = center + vec2(0.18 + var4, 0.25 + var4*0.5); // Bottom Right
            branches[4] = center + vec2(0.0, 0.28 + var5);            // Bottom
            branches[5] = center + vec2(-0.18 - var6, 0.25 + var6*0.4); // Bottom Left
            branches[6] = center + vec2(-0.28 - var7, 0.0);           // Left
            branches[7] = center + vec2(-0.18 - var8, -0.16 + var8*0.3); // Top Left

            float result = mainBall;

            // Add branches with organic connections
            for (int i = 0; i < 8; i++) {
                float fi = float(i);

                // Branch size varies based on hover - SLOWED DOWN ANIMATION
                float branchSize = 0.04;
                if (abs(hoveredBranch - fi) < 0.5) {
                    branchSize = 0.06 + 0.015 * sin(time * 2.5); // Reduced from 6.0 to 2.5 for slower pulse
                }

                // Create branch end
                float branchBall = circle(p, branches[i], branchSize);

                // Create organic connection to center - MADE THICKER
                float connection = capsule(p, center, branches[i], 0.025);

                // Smooth blend everything together - INCREASED BLENDING
                result = smin(result, branchBall, 0.03);
                result = smin(result, connection, 0.02);
            }

            return result;
        }

        // Generate metallic color
        vec3 getMetallicColor(vec2 p, float sdf) {
            // Base metallic colors
            vec3 silver = vec3(0.7, 0.75, 0.8);
            vec3 darkGray = vec3(0.2, 0.2, 0.25);
            vec3 black = vec3(0.08, 0.08, 0.1);

            // Distance-based coloring
            float t = 1.0 - smoothstep(0.0, 0.015, abs(sdf));

            // Add metallic reflection
            float reflection = 0.5 + 0.5 * sin(p.x * 8.0 + time * 1.5);

            // Animate metallic sheen
            float sheen = 0.5 + 0.5 * cos(time * 2.0 + p.y * 6.0);

            // Mix colors
            vec3 baseColor = mix(black, darkGray, reflection * 0.7);
            vec3 highlightColor = mix(darkGray, silver, sheen * 0.5);

            return mix(baseColor, highlightColor, t * 0.8);
        }

        void main() {
            // Convert to shader coordinates
            vec2 uv = vUV;
            vec2 p = (uv - 0.5) * 2.0;

            // Maintain aspect ratio
            p.x *= resolution.x / resolution.y;

            // Get distance to goop shape
            float sdf = goopSDF(p);

            // Create the goop
            float goop = smoothstep(0.008, 0.0, sdf);

            // Get metallic color
            vec3 color = getMetallicColor(p, sdf);

            // Add glow effect for hovered branches
            float glow = 0.0;
            if (hoveredBranch >= 0.0) {
                glow = 0.2 * exp(-abs(sdf) * 30.0);
                color += vec3(0.0, 0.4, 0.8) * glow;
            }

            // Dark background
            vec3 bgColor = vec3(0.05, 0.06, 0.08);
            vec3 finalColor = mix(bgColor, color, goop);

            // Add subtle glow around the edges
            finalColor += vec3(glow * 0.05);

            gl_FragColor = vec4(finalColor, 1.0);
        }
    |]
