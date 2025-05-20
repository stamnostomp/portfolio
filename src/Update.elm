module Update exposing (Msg(..), update)

import Math.Vector2 as Vec2
import Model exposing (Model)


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
