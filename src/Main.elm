module Main exposing (main)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Math.Vector2 as Vec2
import Model exposing (Model, Msg(..), init, update)
import Shaders.Background as Background
import Shaders.Character as Character
import Shaders.ColorBlocks as ColorBlocks
import Shaders.Footer as Footer
import Shaders.Header as Header
import Shaders.Mesh exposing (fullscreenMesh)
import Shaders.Types exposing (Uniforms)
import Shaders.VisitorCounter as VisitorCounter
import WebGL



-- VIEW


view : Model -> Html Msg
view model =
    let
        uniforms =
            { time = model.time
            , resolution = model.resolution
            , mousePosition = model.mousePosition
            }
    in
    div [ class "w-100 h-100 fixed top-0 left-0 overflow-auto bg-black" ]
        [ -- Background
          WebGL.toHtml
            [ width (floor (Vec2.getX model.resolution))
            , height (floor (Vec2.getY model.resolution))
            , class "fixed top-0 left-0 z-0"
            ]
            [ WebGL.entity
                Shaders.Mesh.vertexShader
                Background.fragmentShader
                fullscreenMesh
                uniforms
            ]

        -- Content container
        , div [ class "relative z-1 pa3 h-100 flex flex-column" ]
            [ -- Header
              renderHeader model uniforms

            -- Main content
            , div [ class "w-100 flex-auto flex" ]
                [ renderLeftColumn model uniforms
                , renderRightColumn model uniforms
                ]

            -- Footer
            , renderFooter model uniforms
            ]

        -- Visitor Counter
        , renderVisitorCounter model uniforms
        ]



-- Helper functions for rendering each section


renderHeader : Model -> Uniforms -> Html Msg
renderHeader model uniforms =
    div [ class "w-100 h3 mb3" ]
        [ WebGL.toHtml
            [ width (floor (Vec2.getX model.resolution * 0.98))
            , height 60
            , class "w-100 h-100 ba b--gray"
            ]
            [ WebGL.entity
                Shaders.Mesh.vertexShader
                Header.fragmentShader
                fullscreenMesh
                uniforms
            ]
        ]


renderLeftColumn : Model -> Uniforms -> Html Msg
renderLeftColumn model uniforms =
    div [ class "w-40 pr2 flex flex-column" ]
        [ -- Top color block
          div [ class "w-100 mb2", style "height" "48%" ]
            [ WebGL.toHtml
                [ width (floor (Vec2.getX model.resolution * 0.38))
                , height (floor (Vec2.getY model.resolution * 0.36))
                , class "w-100 h-100 ba b--gray"
                ]
                [ WebGL.entity
                    Shaders.Mesh.vertexShader
                    ColorBlocks.colorBlock1FragmentShader
                    fullscreenMesh
                    uniforms
                ]
            ]

        -- Bottom color block
        , div [ class "w-100 mt2", style "height" "48%" ]
            [ WebGL.toHtml
                [ width (floor (Vec2.getX model.resolution * 0.38))
                , height (floor (Vec2.getY model.resolution * 0.36))
                , class "w-100 h-100 ba b--gray"
                ]
                [ WebGL.entity
                    Shaders.Mesh.vertexShader
                    ColorBlocks.colorBlock2FragmentShader
                    fullscreenMesh
                    uniforms
                ]
            ]
        ]


renderRightColumn : Model -> Uniforms -> Html Msg
renderRightColumn model uniforms =
    div [ class "w-60 pl2" ]
        [ WebGL.toHtml
            [ width (floor (Vec2.getX model.resolution * 0.58))
            , height (floor (Vec2.getY model.resolution * 0.76))
            , class "w-100 h-100 ba b--gray"
            ]
            [ WebGL.entity
                Shaders.Mesh.vertexShader
                Character.fragmentShader
                fullscreenMesh
                uniforms
            ]
        ]


renderFooter : Model -> Uniforms -> Html Msg
renderFooter model uniforms =
    div [ class "w-100 h3 mt3" ]
        [ WebGL.toHtml
            [ width (floor (Vec2.getX model.resolution * 0.98))
            , height 60
            , class "w-100 h-100 ba b--gray"
            ]
            [ WebGL.entity
                Shaders.Mesh.vertexShader
                Footer.fragmentShader
                fullscreenMesh
                uniforms
            ]
        ]


renderVisitorCounter : Model -> Uniforms -> Html Msg
renderVisitorCounter model uniforms =
    div [ class "absolute bottom-1 right-1" ]
        [ WebGL.toHtml
            [ width 120
            , height 30
            , class "ba b--gray"
            ]
            [ WebGL.entity
                Shaders.Mesh.vertexShader
                VisitorCounter.fragmentShader
                fullscreenMesh
                uniforms
            ]
        ]



-- SUBSCRIPTIONS


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



-- MAIN


main : Program { width : Int, height : Int } Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
