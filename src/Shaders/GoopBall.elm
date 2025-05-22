-- src/Shaders/GoopBall.elm - Enhanced version with floating and deforming center


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



-- Enhanced fragment shader with floating and deforming center


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

        // Subtle deformable circle - nearly perfect circle with minimal variation
        float deformableCircle(vec2 p, vec2 center, float baseRadius) {
            vec2 offset = p - center;
            float angle = atan(offset.y, offset.x);
            float dist = length(offset);

            // Very subtle organic deformation
            float deform1 = 0.003 * sin(angle * 3.0 + time * 0.2);
            float deform2 = 0.002 * sin(angle * 5.0 - time * 0.15);

            // Very gentle breathing effect
            float breathing = 0.004 * sin(time * 0.3);

            // Combine minimal deformations
            float radius = baseRadius + deform1 + deform2 + breathing;

            return dist - radius;
        }

        // Distance to a capsule (rounded line)
        float capsule(vec2 p, vec2 a, vec2 b, float r) {
            vec2 pa = p - a;
            vec2 ba = b - a;
            float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
            return length(pa - ba * h) - r;
        }

        // Create the goop ball and branches with very subtle floating center
        float goopSDF(vec2 p) {
            // Very subtle floating center with minimal movement
            vec2 floatOffset = vec2(
                0.008 * sin(time * 0.15) + 0.004 * sin(time * 0.25),
                0.006 * cos(time * 0.18) + 0.005 * cos(time * 0.22)
            );

            vec2 center = vec2(0.0, 0.0) + floatOffset;

            // Main goop ball with very subtle deformation - mostly circular
            float mainBall = deformableCircle(p, center, 0.15);

            // Branch positions (8 directions) - WITH ORGANIC MOVEMENT RELATIVE TO FLOATING CENTER
            vec2 branches[8];

            // Add organic variation to branch lengths - SLOWED DOWN MOVEMENT
            float var1 = 0.025 * sin(time * 0.3 + 0.0);
            float var2 = 0.020 * sin(time * 0.4 + 2.1);
            float var3 = 0.030 * sin(time * 0.25 + 4.2);
            float var4 = 0.018 * sin(time * 0.35 + 6.3);
            float var5 = 0.025 * sin(time * 0.32 + 1.5);
            float var6 = 0.022 * sin(time * 0.38 + 3.6);
            float var7 = 0.028 * sin(time * 0.28 + 5.7);
            float var8 = 0.024 * sin(time * 0.33 + 0.9);

            // Branches now follow the floating center
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

                // Branch size with subtle growing animation on hover AND gentle breathing for all nodes
                float branchSize = 0.04;

                // Add gentle breathing to all nodes as they move
                float breathing = 0.005 * sin(time * 0.4 + fi * 1.2);
                branchSize += breathing;

                if (abs(hoveredBranch - fi) < 0.5) {
                    // Smaller range (0.04 to 0.06) and gentle pulsing for hovered
                    branchSize = 0.05 + 0.01 * sin(time * 1.2) + breathing;
                }

                // Create branch end with animated size
                float branchBall = circle(p, branches[i], branchSize);

                // Create organic connection with breathing thickness to match nodes
                float connectionThickness = 0.025;
                // Add gentle thickness breathing that matches node breathing
                float thicknessBreathing = 0.003 * sin(time * 0.4 + fi * 1.2);
                connectionThickness += thicknessBreathing;

                float connection = capsule(p, center, branches[i], connectionThickness);

                // Smooth blend everything together - INCREASED BLENDING
                result = smin(result, branchBall, 0.03);
                result = smin(result, connection, 0.02);
            }

            return result;
        }

        // Generate subtle metallic color with gentle highlights
        vec3 getMetallicColor(vec2 p, float sdf) {
            // Base metallic colors
            vec3 silver = vec3(0.7, 0.75, 0.8);
            vec3 darkGray = vec3(0.2, 0.2, 0.25);
            vec3 black = vec3(0.08, 0.08, 0.1);

            // Distance-based coloring
            float t = 1.0 - smoothstep(0.0, 0.015, abs(sdf));

            // Very subtle floating metallic reflection
            float floatX = 0.008 * sin(time * 0.15) + 0.004 * sin(time * 0.25);
            float floatY = 0.006 * cos(time * 0.18) + 0.005 * cos(time * 0.22);

            float reflection = 0.5 + 0.5 * sin((p.x - floatX) * 8.0 + time * 0.3);

            // Gentle metallic sheen
            float sheen = 0.5 + 0.5 * cos(time * 0.4 + (p.y - floatY) * 6.0);

            // Very subtle iridescence
            float iridescence = 0.1 * sin(time * 0.2 + length(p) * 4.0);
            vec3 iridColor = vec3(0.05, 0.15, 0.3) * iridescence;

            // Mix colors
            vec3 baseColor = mix(black, darkGray, reflection * 0.7);
            vec3 highlightColor = mix(darkGray, silver, sheen * 0.5);

            vec3 finalColor = mix(baseColor, highlightColor, t * 0.8) + iridColor * t;

            return finalColor;
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

            // Get enhanced metallic color
            vec3 color = getMetallicColor(p, sdf);

            // Add smooth blue transition glow effect for hovered branches
            float glow = 0.0;
            if (hoveredBranch >= 0.0) {
                glow = 0.2 * exp(-abs(sdf) * 30.0);
                // Smooth transition to blue with gentle pulsing
                float transition = 0.8 + 0.2 * sin(time * 1.0);
                vec3 blueGlow = vec3(0.0, 0.5, 1.0) * glow * transition;
                color += blueGlow;
            }

            // Dark background with very subtle animation
            vec3 bgColor = vec3(0.05, 0.06, 0.08);
            bgColor += vec3(0.005) * sin(time * 0.1 + length(p) * 2.0);

            vec3 finalColor = mix(bgColor, color, goop);

            // Add subtle floating glow around the edges
            finalColor += vec3(glow * 0.05);

            gl_FragColor = vec4(finalColor, 1.0);
        }
    |]
