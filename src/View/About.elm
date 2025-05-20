module View.About exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (Model, Msg(..))
import View.Common exposing (..)


view : Model -> Html Msg
view model =
    div [ class "flex flex-wrap relative" ]
        [ div [ class "absolute top-0 left-0 w-100 h-100 o-30" ]
            [ div
                [ class "w-100 h-100 bg-center bg-no-repeat"
                , style "background-image" "url('data:image/svg+xml;utf8,<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"500\" height=\"500\" viewBox=\"0 0 500 500\"><rect width=\"500\" height=\"500\" fill=\"none\" stroke=\"white\" stroke-width=\"1\"/><path d=\"M 0,0 L 500,500 M 500,0 L 0,500\" stroke=\"white\" stroke-width=\"1\"/></svg>')"
                ]
                []
            ]
        , div [ class "w-100 w-50-ns pa2 relative z-1" ]
            [ div [ class "pa3 br2 bg-navy white mb3" ]
                [ h2 [ class "mt0 mb3 f3 hot-pink" ] [ text "CROSS TOWN TRAFFIC" ]
                , p [ class "measure" ] [ text "The digital highways are congested with data flows and information packets." ]
                , p [ class "measure" ] [ text "Navigate the urban grid system to find your destination in the cyber landscape." ]
                ]
            , fabricSwatch "bg-blue" "velcronr (P)"
            , fabricSwatch "bg-dark-blue" "wayfarer (T/HOF (D)"
            ]
        , div [ class "w-100 w-50-ns pa2 relative z-1" ]
            [ fabricSwatch "bg-navy" "HOF (D)"
            , fabricSwatch "bg-blue" "LDS (l)"
            , div [ class "pa3 br2 bg-dark-gray near-white mb3" ]
                [ h3 [ class "mt0 mb3 f4 light-yellow" ] [ text "TRANSPORT METRICS" ]
                , ul [ class "list pl0" ]
                    [ updateItem "NETWORK CAPACITY" "87%" Nothing
                    , updateItem "BANDWIDTH ALLOCATION" "42%" Nothing
                    , updateItem "ACCESS CLEARANCE" "LEVEL 5" Nothing
                    ]
                ]
            ]
        , div [ class "w-100 pa2 mt3 relative z-1" ]
            [ div [ class "flex justify-center" ]
                [ navArrow "◀" "Previous"
                , navArrow "▲" "Up"
                , navArrow "▶" "Next"
                ]
            ]
        , colorPalette
        ]
