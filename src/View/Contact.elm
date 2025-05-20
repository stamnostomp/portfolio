module View.Contact exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (Model, Msg(..))
import View.Common exposing (..)


view : Model -> Html Msg
view model =
    div [ class "flex flex-wrap" ]
        [ div [ class "w-100 w-30-ns pa2" ]
            [ fabricSwatch "bg-yellow" "LDS (l)"
            , fabricSwatch "bg-gold" "telemetra (SX)"
            , fabricSwatch "bg-blue" "LDS (l)"
            ]
        , div [ class "w-100 w-40-ns pa2" ]
            [ div [ class "pa3 br2 bg-dark-gray near-white mb3" ]
                [ h2 [ class "mt0 mb3 f3 light-green tc" ] [ text "MIXER INSPIRATIONS" ]
                , div [ class "flex flex-column items-center" ]
                    [ div [ class "w2 h2 bg-hot-pink mb2" ] []
                    , div [ class "w3 h1 bg-gold mb2" ] []
                    , div [ class "w2 h2 bg-green mb2" ] []
                    , p [ class "measure tc f7 silver" ] [ text "Select from palette samples and combine to create your unique digital signature." ]
                    ]
                ]
            ]
        , div [ class "w-100 w-30-ns pa2" ]
            [ fabricSwatch "bg-green" "kaksyams (SX)"
            , fabricSwatch "bg-hot-pink" "microfoam (E)"
            , fabricSwatch "bg-blue" "LDS (l)"
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
