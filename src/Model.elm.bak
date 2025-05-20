mmodule Model exposing (Model, Msg(..), init, update)

import Math.Vector2 as Vec2

-- MODEL

type alias Model =
    { time : Float
    , resolution : Vec2.Vec2
    , mousePosition : Vec2.Vec2
    }

-- MSG

type Msg
    = Tick Float
    | MouseMove Float Float
    | WindowResize Int Int

-- INIT

init : { width : Int, height : Int } -> ( Model, Cmd Msg )
init flags =
    ( { time = 0
      , resolution = Vec2.vec2 (toFloat flags.width) (toFloat flags.height)
      , mousePosition = Vec2.vec2 0 0
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
            ( { model | mousePosition = Vec2.vec2 x y }, Cmd.none )

        WindowResize width height ->
            ( { model | resolution = Vec2.vec2 (toFloat width) (toFloat height) }, Cmd.none )
