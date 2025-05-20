module Main exposing (main)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import WebGL



-- MODEL


type alias Model =
    { time : Float
    , resolution : Vec2.Vec2
    , mousePosition : Vec2.Vec2
    , buttonClicked : Bool
    }


init : { width : Int, height : Int } -> ( Model, Cmd Msg )
init flags =
    ( { time = 0
      , resolution = Vec2.vec2 (toFloat flags.width) (toFloat flags.height)
      , mousePosition = Vec2.vec2 0 0
      , buttonClicked = False
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Tick Float
    | MouseMove Float Float
    | WindowResize Int Int
    | ButtonClick


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick delta ->
            ( { model | time = model.time + delta * 0.001 }, Cmd.none )

        MouseMove x y ->
            ( { model | mousePosition = Vec2.vec2 x y }, Cmd.none )

        WindowResize width height ->
            ( { model | resolution = Vec2.vec2 (toFloat width) (toFloat height) }, Cmd.none )

        ButtonClick ->
            ( { model | buttonClicked = not model.buttonClicked }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "w-100 h-100 fixed top-0 left-0 overflow-auto bg-black", onClick ButtonClick ]
        [ WebGL.toHtml
            [ width (floor (Vec2.getX model.resolution))
            , height (floor (Vec2.getY model.resolution))
            , class "fixed top-0 left-0 z-0"
            , style "display" "block"
            ]
            [ WebGL.entity
                vertexShader
                fragmentShader
                fullscreenMesh
                { time = model.time
                , resolution = model.resolution
                , mousePosition = model.mousePosition
                , buttonClicked = model.buttonClicked
                }
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


vertexShader : WebGL.Shader { position : Vec3.Vec3 } { u | time : Float, resolution : Vec2.Vec2, mousePosition : Vec2.Vec2 } { vUV : Vec2.Vec2 }
vertexShader =
    [glsl|
        attribute vec3 position;
        varying vec2 vUV;

        void main() {
            gl_Position = vec4(position, 1.0);
            vUV = position.xy * 0.5 + 0.5;
        }
    |]


fragmentShader : WebGL.Shader {} { u | time : Float, resolution : Vec2.Vec2, mousePosition : Vec2.Vec2, buttonClicked : Bool } { vUV : Vec2.Vec2 }
fragmentShader =
    [glsl|
        precision mediump float;
        uniform float time;
        uniform vec2 resolution;
        uniform vec2 mousePosition;
        uniform bool buttonClicked;
        varying vec2 vUV;

        float hash(vec2 p) {
            return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
        }

        float rectangle(vec2 uv, vec2 center, vec2 size) {
            vec2 d = abs(uv - center) - size;
            return 1.0 - smoothstep(-0.01, 0.01, min(max(d.x, d.y), 0.0));
        }

        float text(vec2 uv, vec2 center, float scale, int textType) {
            vec2 d = uv - center;
            float letterWidth = 0.05 * scale;
            float letterHeight = 0.1 * scale;
            float spacing = 0.02 * scale;

            // Simple representation of the text based on textType
            if (textType == 0) { // "HOME"
                float h = rectangle(d + vec2(-0.15 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float o = rectangle(d + vec2(-0.1 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float m = rectangle(d + vec2(-0.05 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float e = rectangle(d + vec2(0.05 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                return max(max(h, o), max(m, e));
            } else if (textType == 1) { // "PROJECTS"
                float p = rectangle(d + vec2(-0.2 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float r = rectangle(d + vec2(-0.15 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float o = rectangle(d + vec2(-0.1 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float j = rectangle(d + vec2(-0.05 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float e = rectangle(d + vec2(0.05 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float c = rectangle(d + vec2(0.1 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float t = rectangle(d + vec2(0.15 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float s = rectangle(d + vec2(0.2 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                return max(max(max(p, r), max(o, j)), max(max(e, c), max(t, s)));
            } else if (textType == 2) { // "ABOUT"
                float a = rectangle(d + vec2(-0.15 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float b = rectangle(d + vec2(-0.1 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float o = rectangle(d + vec2(-0.05 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float u = rectangle(d + vec2(0.05 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float t = rectangle(d + vec2(0.1 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                return max(max(a, b), max(o, max(u, t)));
            } else if (textType == 3) { // "CONTACT"
                float c = rectangle(d + vec2(-0.2 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float o = rectangle(d + vec2(-0.15 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float n = rectangle(d + vec2(-0.1 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float t = rectangle(d + vec2(-0.05 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float a = rectangle(d + vec2(0.05 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float c2 = rectangle(d + vec2(0.1 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                float t2 = rectangle(d + vec2(0.15 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
                return max(max(max(c, o), max(n, t)), max(max(a, c2), t2));
            }
            return 0.0;
        }

        void main() {
            // Base grey color
            vec3 color = vec3(0.5, 0.5, 0.5);

            // Add noise for a hazy effect
            float noise = hash(vUV * 100.0 + time * 0.1) * 0.1;
            color += vec3(noise);

            // Add scanlines for a retro effect
            float scanline = sin(gl_FragCoord.y * 0.5) * 0.1 + 0.9;
            color *= scanline;

            // Draw a header
            vec2 headerCenter = vec2(0.5, 0.9);
            vec2 headerSize = vec2(0.8, 0.1);
            float header = rectangle(vUV, headerCenter, headerSize);
            color = mix(color, vec3(0.3, 0.3, 0.3), header);

            // Draw a navigation button
            vec2 navButtonCenter = vec2(0.1, 0.8);
            vec2 navButtonSize = vec2(0.1, 0.05);
            float navButton = rectangle(vUV, navButtonCenter, navButtonSize);
            color = mix(color, vec3(0.6, 0.6, 0.6), navButton);

            // Draw text on the navigation button
            float textScale = 0.5;
            float textOnNavButton = text(vUV, navButtonCenter, textScale, 0);
            vec3 textColor = vec3(0.0, 0.0, 0.0); // Black color for the text
            color = mix(color, textColor, textOnNavButton);

            // Draw a project area
            vec2 projectCenter = vec2(0.3, 0.5);
            vec2 projectSize = vec2(0.2, 0.2);
            float project = rectangle(vUV, projectCenter, projectSize);
            color = mix(color, vec3(0.4, 0.4, 0.4), project);

            // Draw text on the project area
            float textOnProject = text(vUV, projectCenter, textScale, 1);
            color = mix(color, textColor, textOnProject);

            // Draw another project area
            vec2 project2Center = vec2(0.7, 0.5);
            vec2 project2Size = vec2(0.2, 0.2);
            float project2 = rectangle(vUV, project2Center, project2Size);
            color = mix(color, vec3(0.4, 0.4, 0.4), project2);

            // Draw text on the second project area
            float textOnProject2 = text(vUV, project2Center, textScale, 2);
            color = mix(color, textColor, textOnProject2);

            // Draw a footer
            vec2 footerCenter = vec2(0.5, 0.1);
            vec2 footerSize = vec2(0.8, 0.1);
            float footer = rectangle(vUV, footerCenter, footerSize);
            color = mix(color, vec3(0.3, 0.3, 0.3), footer);

            // Draw text on the footer
            float textOnFooter = text(vUV, footerCenter, textScale, 3);
            color = mix(color, textColor, textOnFooter);

            gl_FragColor = vec4(color, 1.0);
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



-- Main Program


main : Program { width : Int, height : Int } Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
