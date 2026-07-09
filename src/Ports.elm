-- src/Ports.elm - Port for content bounds detection


port module Ports exposing (contentBoundsChanged, pointerLockChanged, requestPointerLock)

-- Port to receive content bounds changes from JavaScript


port contentBoundsChanged : ({ width : Int, height : Int } -> msg) -> Sub msg



-- Ask JS to pointer-lock the element with the given id


port requestPointerLock : String -> Cmd msg



-- True when the pointer is locked, False when released (e.g. Esc)


port pointerLockChanged : (Bool -> msg) -> Sub msg
