-- src/Main.elm


module Main exposing (main)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Time



-- MODEL


type alias Model =
    { time : Float
    , mouseX : Float
    , mouseY : Float
    }


type Msg
    = Tick Float
    | MouseMove Float Float



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { time = 0
      , mouseX = 0
      , mouseY = 0
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick delta ->
            ( { model | time = model.time + delta * 0.001 }, Cmd.none )

        MouseMove x y ->
            ( { model | mouseX = x, mouseY = y }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "w-100 min-vh-100 bg-black white code flex items-center justify-center"
        , style "font-family" "Courier New, monospace"
        ]
        [ div [ class "tc" ]
            [ h1 [ class "f1 mb4" ] [ text "🌊 GOOP NAVIGATION" ]
            , h2 [ class "f3 mb3" ] [ text "Y2K RETRO PORTFOLIO" ]
            , p [ class "f4 mb2" ] [ text ("Time: " ++ String.fromFloat model.time) ]
            , p [ class "f5 mb4" ]
                [ text ("Mouse: " ++ String.fromInt (round model.mouseX) ++ ", " ++ String.fromInt (round model.mouseY)) ]
            , div [ class "f6 silver" ]
                [ p [] [ text "✨ Basic Elm app is working!" ]
                , p [] [ text "🔄 Animation loop running" ]
                , p [] [ text "🎯 Mouse tracking active" ]
                , p [] [ text "Next: Add WebGL goop ball..." ]
                ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onAnimationFrameDelta Tick
        , Browser.Events.onMouseMove
            (Decode.map2 MouseMove
                (Decode.field "clientX" Decode.float)
                (Decode.field "clientY" Decode.float)
            )
        ]



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
