-- src/Shaders/Types.elm - Enhanced with transition uniforms


module Shaders.Types exposing (Uniforms)

import Math.Vector2 as Vec2


type alias Uniforms =
    { time : Float
    , resolution : Vec2.Vec2
    , mousePosition : Vec2.Vec2
    , hoveredBranch : Float
    , centerPosition : Vec2.Vec2

    -- NEW: Transition uniforms
    , transitionProgress : Float -- 0.0 to 1.0
    , transitionType : Float -- 1.0 = out, -1.0 = in, 0.0 = none
    }
