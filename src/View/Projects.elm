module View.Projects exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (Model, Msg(..))
import View.Common exposing (..)


view : Model -> Html Msg
view model =
    div [ class "flex flex-wrap" ]
        [ div [ class "w-100 w-30-ns pa2" ]
            [ fabricSwatch "bg-gold" "european stretch fabrics (F)"
            , fabricSwatch "bg-dark-red" "archive"
            , fabricSwatch "bg-blue" "LDS (t)"
            ]
        , div [ class "w-100 w-40-ns pa2 tc" ]
            [ div [ class "relative" ]
                [ div [ class "tc pa3" ]
                    [ div [ class "dib w-80 h5 bg-yellow relative overflow-hidden mb3" ]
                        [ div [ class "absolute top-0 left-0 w-100 h-100 bg-black-30" ] []
                        , div [ class "absolute top-0 left-0 w-100 h-100 flex items-center justify-center white f4 fw7" ]
                            [ text "CYBER FIGURE"
                            ]
                        ]
                    , div [ class "f7 silver mb2" ] [ text "mainstroke (E)" ]
                    ]
                ]
            ]
        , div [ class "w-100 w-30-ns pa2" ]
            [ fabricSwatch "bg-navy" "velcromp (P)"
            , fabricSwatch "bg-dark-green" "tektronix (S)"
            , fabricSwatch "bg-purple" "LDS (l)"
            ]
        , div [ class "w-100 pa2 mt3" ]
            [ div [ class "flex justify-center" ]
                [ navArrow "◀" "Previous"
                , navArrow "▲" "Up"
                , navArrow "▶" "Next"
                ]
            ]
        , colorPalette
        ]
