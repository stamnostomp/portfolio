module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Math.Vector2 as Vec2
import Mesh exposing (fullscreenMesh)
import Model exposing (Model)
import Shaders exposing (fragmentShader, vertexShader)
import Update exposing (Msg)
import WebGL


view : Model -> Html Msg
view model =
    div [ class "w-100 h-100 fixed top-0 left-0 overflow-auto bg-black" ]
        [ -- WebGL canvas with no uniforms at all
          WebGL.toHtml
            [ width (floor (Vec2.getX model.resolution))
            , height (floor (Vec2.getY model.resolution))
            , class "fixed top-0 left-0 z-0"
            , style "display" "block"
            ]
            [ WebGL.entity
                vertexShader
                fragmentShader
                fullscreenMesh
                {}

            -- Empty record - no uniforms passed
            ]

        -- Simple content overlay
        , div [ class "relative z-1 pa3 white tc" ]
            [ h1 [ class "f1 lh-title" ] [ text "Y2K Retro Portfolio" ]
            , p [ class "f3" ] [ text "Basic WebGL Version" ]
            ]
        ]
