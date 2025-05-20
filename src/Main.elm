module Main exposing (main)

import Browser
import Model exposing (Model, init)
import Subscriptions exposing (subscriptions)
import Update exposing (Msg, update)
import View exposing (view)


main : Program { width : Int, height : Int } Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
