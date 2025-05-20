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

        float text(vec2 uv, vec2 center, float scale) {
            vec2 d = uv - center;
            float letterWidth = 0.05 * scale;
            float letterHeight = 0.1 * scale;
            float spacing = 0.02 * scale;

            // Simple representation of the text "CLICK"
            float c = rectangle(d + vec2(-0.15 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
            float l = rectangle(d + vec2(-0.1 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));
            float i = rectangle(d + vec2(-0.05 * scale, 0), vec2(0, 0), vec2(letterWidth * 0.5, letterHeight));
            float k = rectangle(d + vec2(0.05 * scale, 0), vec2(0, 0), vec2(letterWidth, letterHeight));

            return max(max(c, l), max(i, k));
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

            // Draw a button
            vec2 buttonCenter = vec2(0.5, 0.5);
            vec2 buttonSize = vec2(0.2, 0.1);
            float button = rectangle(vUV, buttonCenter, buttonSize);

            // Highlight the button if the mouse is over it
            vec2 normalizedMouse = mousePosition / resolution;
            float mouseOverButton = rectangle(normalizedMouse, buttonCenter, buttonSize);
            vec3 buttonColor = mix(vec3(0.7, 0.7, 0.7), vec3(0.9, 0.9, 0.9), mouseOverButton);

            // Change button color if clicked
            if (buttonClicked) {
                buttonColor = vec3(0.4, 0.4, 0.9);
            }

            color = mix(color, buttonColor, button);

            // Draw text on the button
            float textScale = 0.5;
            float textOnButton = text(vUV, buttonCenter, textScale);
            vec3 textColor = vec3(0.0, 0.0, 0.0); // Black color for the text
            color = mix(color, textColor, textOnButton);

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
