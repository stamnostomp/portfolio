-- Main.elm - WebGL-focused version with fragment shaders


module Main exposing (main)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Math.Matrix4 as Mat4
import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import Task
import Time
import WebGL



-- MODEL


type alias Model =
    { time : Float
    , resolution : Vec2.Vec2
    , mousePosition : Vec2.Vec2
    }


init : { width : Int, height : Int } -> ( Model, Cmd Msg )
init flags =
    ( { time = 0
      , resolution = Vec2.vec2 (toFloat flags.width) (toFloat flags.height)
      , mousePosition = Vec2.vec2 0 0
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Tick Float
    | MouseMove Float Float
    | WindowResize Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick delta ->
            ( { model | time = model.time + delta * 0.001 }, Cmd.none )

        MouseMove x y ->
            ( { model | mousePosition = Vec2.vec2 x y }, Cmd.none )

        WindowResize width height ->
            ( { model | resolution = Vec2.vec2 (toFloat width) (toFloat height) }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "w-100 h-100 fixed top-0 left-0 overflow-auto bg-black" ]
        [ -- Main WebGL canvas for background effect
          WebGL.toHtml
            [ width (floor (Vec2.getX model.resolution))
            , height (floor (Vec2.getY model.resolution))
            , class "fixed top-0 left-0 z-0"
            , style "display" "block"
            ]
            [ WebGL.entity
                vertexShader
                backgroundFragmentShader
                fullscreenMesh
                { time = model.time
                , resolution = model.resolution
                , mousePosition = model.mousePosition
                }
            ]

        -- Content Layers - Each section will be its own WebGL entity
        , div [ class "relative z-1 pa3" ]
            [ -- Header with glitch effect
              WebGL.toHtml
                [ width (floor (Vec2.getX model.resolution))
                , height 150
                , class "center mb4"
                ]
                [ WebGL.entity
                    vertexShader
                    headerFragmentShader
                    fullscreenMesh
                    { time = model.time
                    , resolution = model.resolution
                    , mousePosition = model.mousePosition
                    }
                ]

            -- 3D Rotating Cube
            , WebGL.toHtml
                [ width 400
                , height 300
                , class "db center ba b--white-30 mb4"
                ]
                [ WebGL.entity
                    cubeVertexShader
                    cubeFragmentShader
                    cubeMesh
                    { perspective =
                        Mat4.mul
                            (Mat4.makePerspective 45 (4 / 3) 0.01 100)
                            (Mat4.makeLookAt (Vec3.vec3 0 0 3) (Vec3.vec3 0 0 0) (Vec3.vec3 0 1 0))
                    , rotation =
                        Mat4.mul
                            (Mat4.makeRotate (model.time * 0.5) (Vec3.vec3 1 0 0))
                            (Mat4.makeRotate (model.time * 0.3) (Vec3.vec3 0 1 0))
                    , time = model.time
                    }
                ]

            -- About Section with text effect
            , WebGL.toHtml
                [ width (floor (Vec2.getX model.resolution * 0.8))
                , height 200
                , class "db center mb4 ba b--white-10"
                ]
                [ WebGL.entity
                    vertexShader
                    aboutFragmentShader
                    fullscreenMesh
                    { time = model.time
                    , resolution = Vec2.vec2 (Vec2.getX model.resolution * 0.8) 200
                    , mousePosition = model.mousePosition
                    }
                ]

            -- Projects Section with grid effect
            , WebGL.toHtml
                [ width (floor (Vec2.getX model.resolution * 0.8))
                , height 300
                , class "db center mb4 ba b--white-10"
                ]
                [ WebGL.entity
                    vertexShader
                    projectsFragmentShader
                    fullscreenMesh
                    { time = model.time
                    , resolution = Vec2.vec2 (Vec2.getX model.resolution * 0.8) 300
                    , mousePosition = model.mousePosition
                    }
                ]

            -- Contact Section with plasma effect
            , WebGL.toHtml
                [ width (floor (Vec2.getX model.resolution * 0.8))
                , height 150
                , class "db center mb4 ba b--white-10"
                ]
                [ WebGL.entity
                    vertexShader
                    contactFragmentShader
                    fullscreenMesh
                    { time = model.time
                    , resolution = Vec2.vec2 (Vec2.getX model.resolution * 0.8) 150
                    , mousePosition = model.mousePosition
                    }
                ]

            -- Footer with scanline effect
            , WebGL.toHtml
                [ width (floor (Vec2.getX model.resolution))
                , height 80
                , class "db center mt5"
                ]
                [ WebGL.entity
                    vertexShader
                    footerFragmentShader
                    fullscreenMesh
                    { time = model.time
                    , resolution = Vec2.vec2 (Vec2.getX model.resolution) 80
                    , mousePosition = model.mousePosition
                    }
                ]

            -- Visitor Counter with digital effect
            , WebGL.toHtml
                [ width 120
                , height 30
                , class "fixed bottom-1 right-1"
                ]
                [ WebGL.entity
                    vertexShader
                    counterFragmentShader
                    fullscreenMesh
                    { time = model.time
                    , resolution = Vec2.vec2 120 30
                    , mousePosition = model.mousePosition
                    }
                ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Browser.Events.onAnimationFrameDelta Tick
        , Browser.Events.onMouseMove
            (Decode.map2 MouseMove
                (Decode.field "clientX" Decode.float)
                (Decode.field "clientY" Decode.float)
            )
        , Browser.Events.onResize WindowResize
        ]



-- SHADERS
-- Common vertex shader for fullscreen quads
-- Common vertex shader for fullscreen quads


vertexShader : WebGL.Shader { position : Vec3.Vec3 } { u | time : Float, resolution : Vec2.Vec2, mousePosition : Vec2.Vec2 } { vUV : Vec2.Vec2 }
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



-- Background shader with dark retro grid effect


backgroundFragmentShader : WebGL.Shader {} { u | time : Float, resolution : Vec2.Vec2, mousePosition : Vec2.Vec2 } { vUV : Vec2.Vec2 }
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



-- Header shader with Y2K glitch text effect


headerFragmentShader : WebGL.Shader {} { u | time : Float, resolution : Vec2.Vec2 } { vUV : Vec2.Vec2 }
headerFragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        varying vec2 vUV;

        // Simple hash function
        float hash(vec2 p) {
            return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
        }

        // Function to render text
        float text(vec2 uv) {
            // Simplified text rendering - just creating shapes that look like text
            float result = 0.0;

            // M
            result += step(0.1, 1.0 - smoothstep(0.0, 0.05, abs(abs(uv.x - 0.2) - 0.05) + abs(uv.y - 0.5) - 0.25));

            // Y
            vec2 yPos = uv - vec2(0.35, 0.0);
            float y1 = 1.0 - smoothstep(0.0, 0.05, abs(yPos.x) - 0.05 + abs(yPos.y - 0.7) - 0.2);
            float y2 = 1.0 - smoothstep(0.0, 0.05, abs(yPos.x) - 0.05 + abs(yPos.y - 0.4) - 0.10);
            result += step(0.1, y1 * y2);

            // P
            vec2 pPos = uv - vec2(0.5, 0.0);
            result += step(0.1, 1.0 - smoothstep(0.0, 0.05, abs(pPos.x + 0.05) - 0.05 + abs(pPos.y - 0.5) - 0.25));
            result += step(0.1, 1.0 - smoothstep(0.0, 0.05, length(vec2(pPos.x - 0.05, pPos.y - 0.6)) - 0.1));

            // O
            vec2 oPos = uv - vec2(0.65, 0.0);
            result += step(0.1, 1.0 - smoothstep(0.0, 0.05, abs(length(vec2(oPos.x, oPos.y - 0.5)) - 0.15)));

            // R
            vec2 rPos = uv - vec2(0.8, 0.0);
            result += step(0.1, 1.0 - smoothstep(0.0, 0.05, abs(rPos.x + 0.05) - 0.05 + abs(rPos.y - 0.5) - 0.25));
            result += step(0.1, 1.0 - smoothstep(0.0, 0.05, length(vec2(rPos.x - 0.05, rPos.y - 0.6)) - 0.1));
            result = min(result, 1.0);

            return result;
        }

        void main() {
            // Base dark color
            vec3 color = vec3(0.0, 0.0, 0.1);

            // Distort UVs for glitch effect
            vec2 uv = vUV;

            // Glitch effect with time
            float glitchIntensity = 0.02 * (sin(time * 10.0) * 0.5 + 0.5);
            if (hash(vec2(time * 0.1, floor(uv.y * 20.0))) > 0.8) {
                uv.x += glitchIntensity * (hash(vec2(time, floor(uv.y * 50.0))) * 2.0 - 1.0);
            }

            // RGB shift
            float r = text(uv + vec2(glitchIntensity * sin(time * 2.0), 0.0));
            float g = text(uv);
            float b = text(uv - vec2(glitchIntensity * sin(time * 1.7), 0.0));

            // Combine for final effect
            color = vec3(r, g, b);

            // Scan lines
            float scanline = sin(vUV.y * 100.0 + time * 5.0) * 0.5 + 0.5;
            color *= 0.8 + scanline * 0.2;

            // Add glow
            color += vec3(r, g, b) * 0.5;

            gl_FragColor = vec4(color, 1.0);
        }
    |]



-- Cube vertex shader with animation


cubeVertexShader : WebGL.Shader { position : Vec3.Vec3, color : Vec3.Vec3 } { u | perspective : Mat4.Mat4, rotation : Mat4.Mat4, time : Float } { vColor : Vec3.Vec3, vPosition : Vec3.Vec3 }
cubeVertexShader =
    [glsl|
        attribute vec3 position;
        attribute vec3 color;
        uniform mat4 perspective;
        uniform mat4 rotation;
        uniform float time;
        varying vec3 vColor;
        varying vec3 vPosition;

        void main() {
            // Apply distortion based on time
            vec3 pos = position;
            pos.x += sin(pos.y * 5.0 + time) * 0.05;
            pos.y += cos(pos.z * 5.0 + time * 0.7) * 0.05;

            gl_Position = perspective * rotation * vec4(pos, 1.0);
            vColor = color;
            vPosition = position;
        }
    |]



-- Cube fragment shader with retro effect


cubeFragmentShader : WebGL.Shader {} { u | time : Float } { vColor : Vec3.Vec3, vPosition : Vec3.Vec3 }
cubeFragmentShader =
    [glsl|
        precision mediump float;
        varying vec3 vColor;
        varying vec3 vPosition;
        uniform float time;

        void main() {
            // Y2K-style plasma effect on the cube
            float x = vPosition.x;
            float y = vPosition.y;
            float z = vPosition.z;

            // Classic plasma formula
            float v1 = sin(x * 10.0 + time * 2.0);
            float v2 = sin(10.0 * (x * sin(time / 2.0) + y * cos(time / 3.0)) + time);
            float v3 = sin(sqrt(100.0 * (x * x + y * y + z * z)) + time);

            // Combine for final effect
            float plasma = (v1 + v2 + v3) / 3.0;

            // Monochrome output with slight color tint
            float shade = (plasma + 1.0) / 2.0; // Normalize to 0-1
            vec3 color = vec3(shade) * (0.5 + 0.5 * vColor); // Mix with vertex color

            // Add wireframe effect on edges
            vec3 absPos = abs(vPosition);
            float edgeFactor = max(max(absPos.x, absPos.y), absPos.z);
            float edge = 1.0 - smoothstep(0.48, 0.5, edgeFactor);

            // Brighten edges
            color = mix(color, vec3(1.0), edge * 0.8);

            gl_FragColor = vec4(color, 1.0);
        }
    |]



-- About section with text effect


aboutFragmentShader : WebGL.Shader {} { u | time : Float, resolution : Vec2.Vec2 } { vUV : Vec2.Vec2 }
aboutFragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        varying vec2 vUV;

        // Hash function for noise
        float hash(vec2 p) {
            return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
        }

        float text(vec2 uv, float pattern) {
            // Replicate a "text-like" pattern for the about section
            float result = 0.0;

            // Create horizontal lines of varying lengths to simulate text
            float lineHeight = 0.08;
            float lineY = floor(uv.y / lineHeight) * lineHeight;
            float lineWidth = hash(vec2(lineY, pattern)) * 0.6 + 0.2;

            if (uv.x < lineWidth && fract(uv.y / lineHeight) < 0.7) {
                result = hash(vec2(floor(uv.x * 50.0), lineY)) > 0.5 ? 1.0 : 0.0;
            }

            return result;
        }

        void main() {
            // Header area
            vec3 color = vec3(0.02, 0.03, 0.05);
            vec2 uv = vUV;

            // Create section header
            if (uv.y > 0.8) {
                // ABOUT ME header
                if (uv.y > 0.85 && uv.x > 0.3 && uv.x < 0.7) {
                    float headerGlow = sin(time * 2.0) * 0.5 + 0.5;
                    color = vec3(0.5 + headerGlow * 0.5);
                }
            } else {
                // Main text area
                float textPattern = text(uv, 1.0);
                color = mix(color, vec3(0.7, 0.7, 0.8), textPattern);

                // Add CRT scan line effect
                float scanline = sin(uv.y * 200.0) * 0.5 + 0.5;
                color *= 0.8 + scanline * 0.2;
            }

            // Add subtle glow to the edges
            float edge = max(
                1.0 - smoothstep(0.0, 0.1, uv.x),
                max(
                    1.0 - smoothstep(0.0, 0.1, uv.y),
                    max(
                        1.0 - smoothstep(0.0, 0.1, 1.0 - uv.x),
                        1.0 - smoothstep(0.0, 0.1, 1.0 - uv.y)
                    )
                )
            );
            color += vec3(0.1, 0.1, 0.2) * edge;

            gl_FragColor = vec4(color, 1.0);
        }
    |]



-- Projects section with grid effect


projectsFragmentShader : WebGL.Shader {} { u | time : Float, resolution : Vec2.Vec2, mousePosition : Vec2.Vec2 } { vUV : Vec2.Vec2 }
projectsFragmentShader =
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
            // Dark background
            vec3 color = vec3(0.02, 0.03, 0.05);
            vec2 uv = vUV;

            // Create section header
            if (uv.y > 0.85) {
                if (uv.x > 0.3 && uv.x < 0.7) {
                    float headerGlow = sin(time * 2.0) * 0.5 + 0.5;
                    color = vec3(0.5 + headerGlow * 0.5);
                }
            } else {
                // Create 3 project boxes
                float boxWidth = 0.25;
                float boxHeight = 0.4;
                float boxSpacing = 0.07;
                float boxY = 0.4;

                for (int i = 0; i < 3; i++) {
                    float boxX = 0.2 + float(i) * (boxWidth + boxSpacing);

                    // Check if inside box
                    if (uv.x > boxX && uv.x < boxX + boxWidth &&
                        uv.y > boxY && uv.y < boxY + boxHeight) {

                        // Box interior with retro pattern
                        vec2 boxUV = (uv - vec2(boxX, boxY)) / vec2(boxWidth, boxHeight);

                        // Project title area
                        if (boxUV.y > 0.8) {
                            color = vec3(0.8);
                        } else {
                            // Create grid pattern
                            vec2 grid = fract(boxUV * 10.0);
                            float gridLine = step(0.9, grid.x) + step(0.9, grid.y);

                            // Add some dynamic elements
                            float wave = sin(boxUV.y * 20.0 + time * 2.0) * 0.5 + 0.5;

                            color = mix(color, vec3(0.3, 0.4, 0.5), gridLine * 0.7);
                            color = mix(color, vec3(0.5, 0.6, 0.7), wave * 0.2);
                        }

                        // Highlight on hover (using mouse position)
                        vec2 mouseUV = mousePosition / resolution;
                        if (mouseUV.x > boxX && mouseUV.x < boxX + boxWidth &&
                            mouseUV.y > boxY && mouseUV.y < boxY + boxHeight) {
                            color *= 1.5;
                        }

                        // Add box border
                        vec2 border = smoothstep(0.0, 0.03, boxUV) * (1.0 - smoothstep(0.97, 1.0, boxUV));
                        float borderMask = min(border.x, border.y);
                        color = mix(vec3(0.9), color, borderMask);
                    }
                }
            }

            // Scanlines
            float scanline = sin(gl_FragCoord.y * 0.5 + time * 5.0) * 0.5 + 0.5;
            color *= 0.8 + scanline * 0.2;

            gl_FragColor = vec4(color, 1.0);
        }
    |]



-- Contact section with retro terminal effect


contactFragmentShader : WebGL.Shader {} { u | time : Float, resolution : Vec2.Vec2 } { vUV : Vec2.Vec2 }
contactFragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        varying vec2 vUV;

        // Terminal text effect
        float terminalText(vec2 uv) {
            // Simple approach to create "text-like" appearance
            float y = floor(uv.y * 10.0) / 10.0;
            float x = floor(uv.x * 30.0) / 30.0;

            float value = fract(sin(dot(vec2(x, y), vec2(12.9898, 78.233))) * 43758.5453);

            // Create realistic-looking text lines
            if (y < 0.3) { // first line
                return (x < 0.2) ? 1.0 : (x < 0.6 ? value > 0.5 ? 1.0 : 0.0 : 0.0);
            } else if (y < 0.6) { // second line
                return (x < 0.15) ? 1.0 : (x < 0.65 ? value > 0.6 ? 1.0 : 0.0 : 0.0);
            } else { // third line
                return (x < 0.25) ? 1.0 : (x < 0.5 ? value > 0.7 ? 1.0 : 0.0 : 0.0);
            }
        }

        void main() {
            vec3 color = vec3(0.02, 0.03, 0.05);
            vec2 uv = vUV;

            // Create section header
            if (uv.y > 0.8) {
                if (uv.x > 0.3 && uv.x < 0.7) {
                    float headerGlow = sin(time * 2.0) * 0.5 + 0.5;
                    color = vec3(0.5 + headerGlow * 0.5);
                }
            } else {
                // Terminal effect with blinking cursor
                float text = terminalText(uv);

                // Cursor blinking
                if (uv.x > 0.25 && uv.x < 0.27 && uv.y > 0.65 && uv.y < 0.7) {
                    text = mod(time, 1.0) > 0.5 ? 1.0 : 0.0;
                }

                // Green terminal color
                color = mix(color, vec3(0.2, 0.8, 0.3), text);

                // CRT effect
                float vignette = length(uv - 0.5) * 1.5;
                color *= 1.0 - vignette * 0.7;

                // Slight CRT distortion
                float distortion = sin(uv.y * 20.0 + time) * 0.003;
                color.g += distortion;
            }

            // Scanlines
            float scanline = sin(gl_FragCoord.y * 0.5) * 0.5 + 0.5;
            color *= 0.8 + scanline * 0.2;

            // Ambient flicker
            float flicker = sin(time * 10.0) * 0.03 + 0.97;
            color *= flicker;

            gl_FragColor = vec4(color, 1.0);
        }
    |]



-- Footer with scanline effect


footerFragmentShader : WebGL.Shader {} { u | time : Float, resolution : Vec2.Vec2 } { vUV : Vec2.Vec2 }
footerFragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        varying vec2 vUV;

        void main() {
            // Dark base color
            vec3 color = vec3(0.02, 0.03, 0.05);
            vec2 uv = vUV;

            // Copyright text simulation
            if (uv.y > 0.3 && uv.y < 0.7 && uv.x > 0.2 && uv.x < 0.8) {
                float textPattern = abs(sin(uv.x * 40.0));

                if (textPattern > 0.7) {
                    color = vec3(0.7);
                }
            }

            // Add scanlines
            float scanline = sin(gl_FragCoord.y * 0.5) * 0.5 + 0.5;
            color *= 0.8 + scanline * 0.2;

            // Add subtle holographic effect
            float holo = sin(uv.x * 50.0 + time * 2.0) * sin(uv.y * 30.0 + time) * 0.1;
            color += vec3(0.0, holo, holo * 0.8);

            gl_FragColor = vec4(color, 1.0);
        }
    |]



-- Visitor counter with digital number effect-- Continuation of counterFragmentShader


counterFragmentShader : WebGL.Shader {} { u | time : Float, resolution : Vec2.Vec2 } { vUV : Vec2.Vec2 }
counterFragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        varying vec2 vUV;

        // Digital number segment check
        float segment(vec2 uv, int n) {
            // Normalized segment positions for a digital display
            uv = uv * 2.0 - 1.0; // Center at origin and scale to -1..1
            float thickness = 0.3;

            // Check which segments should be on for number n
            bool top = (n != 1 && n != 4);
            bool topLeft = (n != 1 && n != 2 && n != 3 && n != 7);
            bool topRight = (n != 5 && n != 6);
            bool middle = (n != 0 && n != 1 && n != 7);
            bool bottomLeft = (n == 0 || n == 2 || n == 6 || n == 8);
            bool bottomRight = (n != 2);
            bool bottom = (n != 1 && n != 4 && n != 7);

            // Check if current position is on a segment
            if (top && abs(uv.x) < 0.5 && uv.y > 0.5 - thickness && uv.y < 0.5)
                return 1.0;
            if (topLeft && uv.x < -0.5 + thickness && uv.x > -0.5 && uv.y > 0.0 && uv.y < 0.5)
                return 1.0;
            if (topRight && uv.x > 0.5 - thickness && uv.x < 0.5 && uv.y > 0.0 && uv.y < 0.5)
                return 1.0;
            if (middle && abs(uv.x) < 0.5 && uv.y > -thickness/2.0 && uv.y < thickness/2.0)
                return 1.0;
            if (bottomLeft && uv.x < -0.5 + thickness && uv.x > -0.5 && uv.y > -0.5 && uv.y < 0.0)
                return 1.0;
            if (bottomRight && uv.x > 0.5 - thickness && uv.x < 0.5 && uv.y > -0.5 && uv.y < 0.0)
                return 1.0;
            if (bottom && abs(uv.x) < 0.5 && uv.y > -0.5 && uv.y < -0.5 + thickness)
                return 1.0;

            return 0.0;
        }

        // Display a digit at position
        float digit(vec2 uv, int digit) {
            // Scale and position
            uv = (uv - 0.5) * 2.0; // Center and scale

            // Check if in digit bounding box
            if (abs(uv.x) > 0.6 || abs(uv.y) > 1.0)
                return 0.0;

            // Render the digit
            return segment(uv, digit);
        }

        void main() {
            // Dark background with slight gradient
            vec3 color = vec3(0.02, 0.03, 0.05);

            // Display "VISITORS: 00001337"
            vec2 uv = vUV;

            // Text label part (approximated)
            if (uv.x < 0.3 && uv.y > 0.4 && uv.y < 0.6) {
                float textPattern = abs(sin(uv.x * 50.0));
                if (textPattern > 0.7)
                    color = vec3(0.7);
            }

            // Position for digits (simplified to just show a few numbers)
            float digitWidth = 0.1;

            // Display 1337 digits
            if (uv.x > 0.5 && uv.x < 0.9) {
                vec2 digitUV;
                int num;

                // Ones place
                if (uv.x > 0.8) {
                    digitUV = (uv - vec2(0.85, 0.5)) / vec2(0.1, 0.3);
                    num = 7;
                }
                // Tens place
                else if (uv.x > 0.7) {
                    digitUV = (uv - vec2(0.75, 0.5)) / vec2(0.1, 0.3);
                    num = 3;
                }
                // Hundreds place
                else if (uv.x > 0.6) {
                    digitUV = (uv - vec2(0.65, 0.5)) / vec2(0.1, 0.3);
                    num = 3;
                }
                // Thousands place
                else {
                    digitUV = (uv - vec2(0.55, 0.5)) / vec2(0.1, 0.3);
                    num = 1;
                }

                float d = digit(digitUV, num);

                // Apply digital effect with glow
                if (d > 0.0) {
                    // Slightly uneven brightness with time for authentic feel
                    float flicker = sin(time * 10.0 + uv.x * 5.0) * 0.1 + 0.9;
                    color = vec3(0.1, 0.9, 0.3) * flicker; // Green digital display
                }
            }

            // Add scanlines and CRT effect
            float scanline = sin(gl_FragCoord.y * 2.0) * 0.1 + 0.9;
            color *= scanline;

            // Add subtle glow
            float glow = sin(time * 3.0) * 0.05 + 0.95;
            color *= glow;

            gl_FragColor = vec4(color, 1.0);
        }
    |]



-- Meshes and Data Types
-- Full screen quad mesh for 2D effects


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



-- 3D cube mesh with per-vertex colors for the rotating cube


cubeMesh : WebGL.Mesh { position : Vec3.Vec3, color : Vec3.Vec3 }
cubeMesh =
    let
        -- Vertex colors for a retro gradient look
        topColor =
            Vec3.vec3 0.8 0.8 0.9

        bottomColor =
            Vec3.vec3 0.2 0.3 0.4

        rgt =
            0.5

        lft =
            -0.5

        top =
            0.5

        bot =
            -0.5

        bck =
            -0.5

        frn =
            0.5
    in
    WebGL.triangles
        [ -- Front face (triangles)
          ( { position = Vec3.vec3 lft bot frn, color = bottomColor }
          , { position = Vec3.vec3 rgt bot frn, color = bottomColor }
          , { position = Vec3.vec3 rgt top frn, color = topColor }
          )
        , ( { position = Vec3.vec3 lft bot frn, color = bottomColor }
          , { position = Vec3.vec3 rgt top frn, color = topColor }
          , { position = Vec3.vec3 lft top frn, color = topColor }
          )

        -- Back face
        , ( { position = Vec3.vec3 lft bot bck, color = bottomColor }
          , { position = Vec3.vec3 lft top bck, color = topColor }
          , { position = Vec3.vec3 rgt top bck, color = topColor }
          )
        , ( { position = Vec3.vec3 lft bot bck, color = bottomColor }
          , { position = Vec3.vec3 rgt top bck, color = topColor }
          , { position = Vec3.vec3 rgt bot bck, color = bottomColor }
          )

        -- Top face
        , ( { position = Vec3.vec3 lft top frn, color = topColor }
          , { position = Vec3.vec3 rgt top frn, color = topColor }
          , { position = Vec3.vec3 rgt top bck, color = topColor }
          )
        , ( { position = Vec3.vec3 lft top frn, color = topColor }
          , { position = Vec3.vec3 rgt top bck, color = topColor }
          , { position = Vec3.vec3 lft top bck, color = topColor }
          )

        -- Bottom face
        , ( { position = Vec3.vec3 lft bot frn, color = bottomColor }
          , { position = Vec3.vec3 lft bot bck, color = bottomColor }
          , { position = Vec3.vec3 rgt bot bck, color = bottomColor }
          )
        , ( { position = Vec3.vec3 lft bot frn, color = bottomColor }
          , { position = Vec3.vec3 rgt bot bck, color = bottomColor }
          , { position = Vec3.vec3 rgt bot frn, color = bottomColor }
          )

        -- Right face
        , ( { position = Vec3.vec3 rgt bot frn, color = Vec3.vec3 0.5 0.5 0.6 }
          , { position = Vec3.vec3 rgt bot bck, color = Vec3.vec3 0.5 0.5 0.6 }
          , { position = Vec3.vec3 rgt top bck, color = Vec3.vec3 0.7 0.7 0.8 }
          )
        , ( { position = Vec3.vec3 rgt bot frn, color = Vec3.vec3 0.5 0.5 0.6 }
          , { position = Vec3.vec3 rgt top bck, color = Vec3.vec3 0.7 0.7 0.8 }
          , { position = Vec3.vec3 rgt top frn, color = Vec3.vec3 0.7 0.7 0.8 }
          )

        -- Left face
        , ( { position = Vec3.vec3 lft bot frn, color = Vec3.vec3 0.5 0.5 0.6 }
          , { position = Vec3.vec3 lft top bck, color = Vec3.vec3 0.7 0.7 0.8 }
          , { position = Vec3.vec3 lft bot bck, color = Vec3.vec3 0.5 0.5 0.6 }
          )
        , ( { position = Vec3.vec3 lft bot frn, color = Vec3.vec3 0.5 0.5 0.6 }
          , { position = Vec3.vec3 lft top frn, color = Vec3.vec3 0.7 0.7 0.8 }
          , { position = Vec3.vec3 lft top bck, color = Vec3.vec3 0.7 0.7 0.8 }
          )
        ]



-- Main Program


main : Program { width : Int, height : Int } Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
