module Model exposing (Model, init)

import Math.Vector2 as Vec2


type alias Model =
    { time : Float
    , resolution : Vec2.Vec2
    , mousePosition : Vec2.Vec2
    }


init : { width : Int, height : Int } -> ( Model, Cmd msg )
init flags =
    ( { time = 0
      , resolution = Vec2.vec2 (toFloat flags.width) (toFloat flags.height)
      , mousePosition = Vec2.vec2 0 0
      }
    , Cmd.none
    )
