-- src/Ports.elm - Port for content bounds detection

port module Ports exposing (contentBoundsChanged)

-- Port to receive content bounds changes from JavaScript
port contentBoundsChanged : ({ width : Int, height : Int } -> msg) -> Sub msg