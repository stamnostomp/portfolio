module Shaders.Types exposing (Uniforms)

import Math.Vector2 as Vec2


type alias Uniforms =
    { time : Float
    , resolution : Vec2.Vec2
    , mousePosition : Vec2.Vec2
    , hoveredBranch : Float -- Add this for goop navigation
    , centerPosition : Vec2.Vec2 -- Add this for goop navigation
    }
