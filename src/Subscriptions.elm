module Subscriptions exposing (subscriptions)

import Browser.Events
import Json.Decode as Decode
import Model exposing (Model)
import Update exposing (Msg(..))


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
