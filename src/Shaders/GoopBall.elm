-- src/Shaders/GoopBall.elm - Original structure with smooth transitions added


module Shaders.GoopBall exposing (GoopAttributes, fragmentShader, vertexShader)

import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import Shaders.Types exposing (Uniforms)
import WebGL


type alias GoopAttributes =
    { position : Vec3.Vec3
    }


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
        uniform float transitionProgress;
        uniform float transitionType;
        varying vec2 vUV;

        void main() {
            gl_Position = vec4(position, 1.0);
            vUV = position.xy * 0.5 + 0.5;
        }
    |]


fragmentShader : WebGL.Shader {} Uniforms { vUV : Vec2.Vec2 }
fragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        uniform float hoveredBranch;
        uniform vec2 centerPosition;
        uniform float transitionProgress;
        uniform float transitionType;
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

        // Deformable rectangle with organic variations (like the circle)
        float deformableRectangle(vec2 p, vec2 center, vec2 size, float cornerRadius) {
            vec2 offset = p - center;

            // Apply same organic deformations as the circle
            float angle = atan(offset.y, offset.x);

            // Subtle organic edge deformation
            float deform1 = 0.003 * sin(angle * 3.0 + time * 0.2);
            float deform2 = 0.002 * sin(angle * 5.0 - time * 0.15);

            // Gentle breathing effect
            float breathing = 0.004 * sin(time * 0.3);

            // Apply deformations to the rectangle size
            vec2 deformedSize = size + vec2(deform1 + breathing, deform2 + breathing);

            // Add subtle edge waves
            float edgeWave1 = 0.002 * sin(p.x * 12.0 + time * 0.4);
            float edgeWave2 = 0.001 * sin(p.y * 15.0 - time * 0.3);

            vec2 finalOffset = abs(offset) - deformedSize + vec2(edgeWave1, edgeWave2);

            return length(max(finalOffset, 0.0)) + min(max(finalOffset.x, finalOffset.y), 0.0) - cornerRadius;
        }

        // Original subtle deformable circle
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

        // Smooth interpolation with easing
        float smootherstep(float edge0, float edge1, float x) {
            x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
            return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
        }

        // Create the morphing goop ball with nodes-to-center animation
        float goopSDF(vec2 p) {
            // Very subtle floating center with minimal movement
            vec2 floatOffset = vec2(
                0.008 * sin(time * 0.15) + 0.004 * sin(time * 0.25),
                0.006 * cos(time * 0.18) + 0.005 * cos(time * 0.22)
            );

            vec2 center = vec2(0.0, 0.0) + floatOffset;

            // Transition parameters
            float progress = transitionProgress;
            float easedProgress = smootherstep(0.0, 1.0, progress);

            float baseRadius = 0.15;

            if (transitionType > 0.5) {
                // Transitioning out: nodes move to center, then center grows into organic rectangle

                // Stage 1: Branches move toward center (0.0 to 0.6)
                // Stage 2: Center morphs and grows to organic rectangle (0.4 to 1.0)

                float branchInwardProgress = smootherstep(0.0, 0.6, progress);
                float centerGrowProgress = smootherstep(0.4, 1.0, progress);
                float morphProgress = smootherstep(0.5, 1.0, progress);

                // Original branch positions
                vec2 branches[8];
                float var1 = 0.025 * sin(time * 0.3 + 0.0);
                float var2 = 0.020 * sin(time * 0.4 + 2.1);
                float var3 = 0.030 * sin(time * 0.25 + 4.2);
                float var4 = 0.018 * sin(time * 0.35 + 6.3);
                float var5 = 0.025 * sin(time * 0.32 + 1.5);
                float var6 = 0.022 * sin(time * 0.38 + 3.6);
                float var7 = 0.028 * sin(time * 0.28 + 5.7);
                float var8 = 0.024 * sin(time * 0.33 + 0.9);

                vec2 originalPositions[8];
                originalPositions[0] = center + vec2(0.0, -0.25 + var1);
                originalPositions[1] = center + vec2(0.18 + var2, -0.16 + var2*0.4);
                originalPositions[2] = center + vec2(0.28 + var3, 0.0);
                originalPositions[3] = center + vec2(0.18 + var4, 0.25 + var4*0.5);
                originalPositions[4] = center + vec2(0.0, 0.28 + var5);
                originalPositions[5] = center + vec2(-0.18 - var6, 0.25 + var6*0.4);
                originalPositions[6] = center + vec2(-0.28 - var7, 0.0);
                originalPositions[7] = center + vec2(-0.18 - var8, -0.16 + var8*0.3);

                // Animate branch positions moving toward center
                for (int i = 0; i < 8; i++) {
                    branches[i] = mix(originalPositions[i], center, branchInwardProgress);
                }

                // Calculate shapes - morph from circle to organic rectangle
                float currentCenterRadius = baseRadius + centerGrowProgress * 0.2; // Slight circle growth
                // Rectangle sized to match content square (85% of viewport)
                float aspectRatio = resolution.x / resolution.y;
                vec2 rectSize = vec2(0.85 * aspectRatio * 0.85, 0.85 * 0.71) * centerGrowProgress; // Rectangle target size

                float circleShape = deformableCircle(p, center, currentCenterRadius);
                float rectangleShape = deformableRectangle(p, center, rectSize, 0.05);

                // Blend between circle and organic rectangle
                float mainShape = mix(circleShape, rectangleShape, morphProgress);

                float result = mainShape;

                // Branch opacity - fade out as they approach center
                float branchOpacity = 1.0 - smootherstep(0.2, 0.8, branchInwardProgress);

                if (branchOpacity > 0.01) {
                    for (int i = 0; i < 8; i++) {
                        float fi = float(i);
                        float branchSize = 0.04 * branchOpacity;
                        float breathing = 0.005 * sin(time * 0.4 + fi * 1.2) * branchOpacity;
                        branchSize += breathing;

                        if (abs(hoveredBranch - fi) < 0.5) {
                            branchSize = (0.05 + 0.01 * sin(time * 1.2)) * branchOpacity + breathing;
                        }

                        float branchBall = circle(p, branches[i], branchSize);

                        // Connection opacity also fades
                        float connectionThickness = 0.025 * branchOpacity;
                        float connection = capsule(p, center, branches[i], connectionThickness);

                        result = smin(result, branchBall, 0.03);
                        result = smin(result, connection, 0.02);
                    }
                }

                return result;

            } else if (transitionType < -0.5) {
                // Transitioning in: organic rectangle shrinks and morphs to circle, then nodes move back out

                float morphProgress = smootherstep(0.0, 0.5, progress);
                float centerShrinkProgress = smootherstep(0.0, 0.6, progress);
                float branchOutwardProgress = smootherstep(0.4, 1.0, progress);

                // Start with organic rectangle, morph to circle, then shrink
                float aspectRatio = resolution.x / resolution.y;
                vec2 rectSize = vec2(0.85 * aspectRatio * 0.85, 0.85 * 0.71) * (1.0 - centerShrinkProgress);
                float rectangleShape = deformableRectangle(p, center, rectSize, 0.05);

                float currentCenterRadius = mix(baseRadius + 0.2, baseRadius, centerShrinkProgress);
                float circleShape = deformableCircle(p, center, currentCenterRadius);

                // Morph from rectangle back to circle
                float mainShape = mix(rectangleShape, circleShape, morphProgress);

                // Original branch positions
                vec2 branches[8];
                float var1 = 0.025 * sin(time * 0.3 + 0.0);
                float var2 = 0.020 * sin(time * 0.4 + 2.1);
                float var3 = 0.030 * sin(time * 0.25 + 4.2);
                float var4 = 0.018 * sin(time * 0.35 + 6.3);
                float var5 = 0.025 * sin(time * 0.32 + 1.5);
                float var6 = 0.022 * sin(time * 0.38 + 3.6);
                float var7 = 0.028 * sin(time * 0.28 + 5.7);
                float var8 = 0.024 * sin(time * 0.33 + 0.9);

                vec2 originalPositions[8];
                originalPositions[0] = center + vec2(0.0, -0.25 + var1);
                originalPositions[1] = center + vec2(0.18 + var2, -0.16 + var2*0.4);
                originalPositions[2] = center + vec2(0.28 + var3, 0.0);
                originalPositions[3] = center + vec2(0.18 + var4, 0.25 + var4*0.5);
                originalPositions[4] = center + vec2(0.0, 0.28 + var5);
                originalPositions[5] = center + vec2(-0.18 - var6, 0.25 + var6*0.4);
                originalPositions[6] = center + vec2(-0.28 - var7, 0.0);
                originalPositions[7] = center + vec2(-0.18 - var8, -0.16 + var8*0.3);

                // Animate branch positions moving back out from center
                for (int i = 0; i < 8; i++) {
                    branches[i] = mix(center, originalPositions[i], branchOutwardProgress);
                }

                float result = mainShape;

                // Branch opacity - fade in as they move out from center
                float branchOpacity = smootherstep(0.2, 0.8, branchOutwardProgress);

                if (branchOpacity > 0.01) {
                    for (int i = 0; i < 8; i++) {
                        float fi = float(i);
                        float branchSize = 0.04 * branchOpacity;
                        float breathing = 0.005 * sin(time * 0.4 + fi * 1.2) * branchOpacity;
                        branchSize += breathing;

                        if (abs(hoveredBranch - fi) < 0.5) {
                            branchSize = (0.05 + 0.01 * sin(time * 1.2)) * branchOpacity + breathing;
                        }

                        float branchBall = circle(p, branches[i], branchSize);

                        float connectionThickness = 0.025 * branchOpacity;
                        float connection = capsule(p, center, branches[i], connectionThickness);

                        result = smin(result, branchBall, 0.03);
                        result = smin(result, connection, 0.02);
                    }
                }

                return result;

            } else {
                // Normal goop ball with all branches - ORIGINAL STRUCTURE
                float mainBall = deformableCircle(p, center, baseRadius);

                vec2 branches[8];
                float var1 = 0.025 * sin(time * 0.3 + 0.0);
                float var2 = 0.020 * sin(time * 0.4 + 2.1);
                float var3 = 0.030 * sin(time * 0.25 + 4.2);
                float var4 = 0.018 * sin(time * 0.35 + 6.3);
                float var5 = 0.025 * sin(time * 0.32 + 1.5);
                float var6 = 0.022 * sin(time * 0.38 + 3.6);
                float var7 = 0.028 * sin(time * 0.28 + 5.7);
                float var8 = 0.024 * sin(time * 0.33 + 0.9);

                branches[0] = center + vec2(0.0, -0.25 + var1);
                branches[1] = center + vec2(0.18 + var2, -0.16 + var2*0.4);
                branches[2] = center + vec2(0.28 + var3, 0.0);
                branches[3] = center + vec2(0.18 + var4, 0.25 + var4*0.5);
                branches[4] = center + vec2(0.0, 0.28 + var5);
                branches[5] = center + vec2(-0.18 - var6, 0.25 + var6*0.4);
                branches[6] = center + vec2(-0.28 - var7, 0.0);
                branches[7] = center + vec2(-0.18 - var8, -0.16 + var8*0.3);

                float result = mainBall;

                for (int i = 0; i < 8; i++) {
                    float fi = float(i);
                    float branchSize = 0.04;
                    float breathing = 0.005 * sin(time * 0.4 + fi * 1.2);
                    branchSize += breathing;

                    if (abs(hoveredBranch - fi) < 0.5) {
                        branchSize = 0.05 + 0.01 * sin(time * 1.2) + breathing;
                    }

                    float branchBall = circle(p, branches[i], branchSize);
                    float connectionThickness = 0.025;
                    float connection = capsule(p, center, branches[i], connectionThickness);

                    result = smin(result, branchBall, 0.03);
                    result = smin(result, connection, 0.02);
                }

                return result;
            }
        }

        // Generate enhanced metallic color with transition effects
        vec3 getMetallicColor(vec2 p, float sdf) {
            vec3 silver = vec3(0.7, 0.75, 0.8);
            vec3 darkGray = vec3(0.2, 0.2, 0.25);
            vec3 black = vec3(0.08, 0.08, 0.1);

            // Enhanced coloring during transitions
            if (abs(transitionType) > 0.5 && transitionProgress > 0.1) {
                // Add blue energy effect during transitions
                vec3 energyColor = vec3(0.2, 0.6, 1.0);
                float energyIntensity = sin(time * 3.0 + length(p) * 8.0) * 0.5 + 0.5;
                silver = mix(silver, energyColor, energyIntensity * 0.3 * transitionProgress);
            }

            float t = 1.0 - smoothstep(0.0, 0.015, abs(sdf));

            float floatX = 0.008 * sin(time * 0.15) + 0.004 * sin(time * 0.25);
            float floatY = 0.006 * cos(time * 0.18) + 0.005 * cos(time * 0.22);

            float reflection = 0.5 + 0.5 * sin((p.x - floatX) * 8.0 + time * 0.3);
            float sheen = 0.5 + 0.5 * cos(time * 0.4 + (p.y - floatY) * 6.0);

            float iridescence = 0.1 * sin(time * 0.2 + length(p) * 4.0);
            vec3 iridColor = vec3(0.05, 0.15, 0.3) * iridescence;

            vec3 baseColor = mix(black, darkGray, reflection * 0.7);
            vec3 highlightColor = mix(darkGray, silver, sheen * 0.5);

            vec3 finalColor = mix(baseColor, highlightColor, t * 0.8) + iridColor * t;

            return finalColor;
        }

        void main() {
            vec2 uv = vUV;
            vec2 p = (uv - 0.5) * 2.0;
            p.x *= resolution.x / resolution.y;

            float sdf = goopSDF(p);
            float goop = smoothstep(0.008, 0.0, sdf);

            vec3 color = getMetallicColor(p, sdf);

            // Enhanced glow effects
            float glow = 0.0;
            if (hoveredBranch >= 0.0 && abs(transitionType) < 0.5) {
                glow = 0.2 * exp(-abs(sdf) * 30.0);
                float transition = 0.8 + 0.2 * sin(time * 1.0);
                vec3 blueGlow = vec3(0.0, 0.5, 1.0) * glow * transition;
                color += blueGlow;
            }

            // Transition-specific effects
            if (abs(transitionType) > 0.5) {
                float transitionGlow = 0.1 * exp(-abs(sdf) * 20.0) * transitionProgress;
                vec3 transitionColor = vec3(0.2, 0.8, 1.0) * transitionGlow;
                color += transitionColor;
            }

            vec3 bgColor = vec3(0.05, 0.06, 0.08);
            bgColor += vec3(0.005) * sin(time * 0.1 + length(p) * 2.0);

            vec3 finalColor = mix(bgColor, color, goop);
            finalColor += vec3(glow * 0.05);

            gl_FragColor = vec4(finalColor, 1.0);
        }
    |]
