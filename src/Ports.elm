-- src/Ports.elm - Port for content bounds detection


port module Ports exposing (contentBoundsChanged, exitPointerLock, playMusic, playSound, pointerLockChanged, preloadSound, requestPointerLock, stopMusic)

-- Port to receive content bounds changes from JavaScript


port contentBoundsChanged : ({ width : Int, height : Int } -> msg) -> Sub msg



-- Ask JS to pointer-lock the element with the given id


port requestPointerLock : String -> Cmd msg



-- Ask JS to release the pointer lock (e.g. so a form can be used)


port exitPointerLock : () -> Cmd msg



-- True when the pointer is locked, False when released (e.g. Esc)


port pointerLockChanged : (Bool -> msg) -> Sub msg



-- Ask JS to play the sound effect at the given URL


port playSound : String -> Cmd msg



-- Ask JS to fetch and decode a sound effect ahead of time


port preloadSound : String -> Cmd msg



-- Loop the track at the given URL as background music (one at a time)


port playMusic : String -> Cmd msg



-- Stop the looping background music, if any


port stopMusic : () -> Cmd msg
