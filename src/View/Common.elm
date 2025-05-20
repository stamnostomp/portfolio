module View.Common exposing
    ( viewHeader
    , viewBrowserBar
    , viewNavBar
    , viewNavigationItem
    , viewNoise
    , viewScanlines
    , statusBlock
    , updateItem
    , fabricSwatch
    , navArrow
    , colorPalette
    , colorBlock
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (Model, Msg(..), Page(..))


viewHeader : Model -> Html Msg
viewHeader model =
    header [ class "w-100 h3 bg-dark-gray flex items-center justify-between ph3 bb b--silver" ]
        [ div [ class "flex items-center" ]
            [ span [ class "mr2 f7 o-70" ] [ text "SYS:" ]
            , span [ class "f4 tracked b cyan-blue" ] [ text "CYBER REALISM" ]
            ]
        , div [ class "flex-ns dn" ]
            [ div [ class "mh2 ba b--gray gray pa1 f7" ] [ text (String.fromFloat model.time |> String.left 5) ]
            , div [ class "mh2 ba b--gray gray pa1 f7" ]
                [ text ("X:" ++ (String.fromFloat model.mouseX |> String.left 5))
                , text (" Y:" ++ (String.fromFloat model.mouseY |> String.left 5))
                ]
            ]
        ]


viewBrowserBar : Model -> Html Msg
viewBrowserBar model =
    div [ class "w-100 bg-near-white dark-gray flex items-center ph2 pv1 f7 bb b--silver" ]
        [ div [ class "flex w-100 items-center" ]
            [ span [ class "mr2 gray" ] [ text "Location:" ]
            , div
                [ class "flex-grow-1 ba b--silver bg-white black ph2 pv1" ]
                [ case model.currentPage of
                    Home ->
                        text "VIRTUAL DELIGHT"

                    Projects ->
                        text "CYBER REALISM"

                    About ->
                        text "CROSS TOWN TRAFFIC"

                    Contact ->
                        text "MIXER INSPIRATIONS"
                ]
            , span [ class "mh2" ] [ text "YOOF" ]
            , span [ class "mh2" ] [ text "154" ]
            , span [ class "mh2" ] [ text "SUMMER 97" ]
            ]
        ]


viewNavBar : Model -> Html Msg
viewNavBar model =
    let
        navButton icon label page =
            button
                [ class "h-100 bn bg-inherit flex flex-column items-center justify-center pa2 pointer grow bw1"
                , classList [ ( "bg-light-blue", model.currentPage == page ) ]
                , onClick (ChangePage page)
                ]
                [ div [ class "f5 mb1" ] [ text icon ]
                , div [ class "f7" ] [ text label ]
                ]
    in
    div [ class "w-100 bg-light-gray dark-gray flex items-center bb b--silver" ]
        [ navButton "⬅️" "Back" Home
        , navButton "➡️" "Forward" Home
        , navButton "🏠" "Home" Home
        , navButton "🔄" "Reload" Home
        , navButton "🖼️" "Images" Projects
        , navButton "📂" "Open" About
        , navButton "🖨️" "Print" Home
        , navButton "🔍" "Find" Contact
        , navButton "⏹️" "Stop" Home
        ]


viewNavigationItem : String -> Html Msg
viewNavigationItem label =
    div [ class "mr2 bg-light-gray pa1 br2 f7 gray pointer grow" ]
        [ text label ]


statusBlock : String -> String -> String -> Html Msg
statusBlock label value color =
    div [ class "w-50 pa2" ]
        [ div [ class "f7 silver mb1" ] [ text label ]
        , div [ class "w-100 h1 bg-white overflow-hidden" ]
            [ div [ class (color ++ " h-100"), style "width" value ] [] ]
        , div [ class "tr f7 silver mt1" ] [ text value ]
        ]


updateItem : String -> String -> Maybe String -> Html Msg
updateItem title date maybeUrl =
    let
        titleElement =
            case maybeUrl of
                Just url ->
                    a [ href url, class "f7 near-white no-underline hover-light-blue", target "_blank" ]
                        [ text title
                        , span [ class "ml1 f8 o-60" ] [ text "↗" ]
                        ]

                Nothing ->
                    span [ class "f7 near-white" ] [ text title ]
    in
    li [ class "pb2 mb2 bb b--gray-20" ]
        [ div [ class "flex justify-between items-center" ]
            [ titleElement
            , span [ class "f7 light-blue" ] [ text date ]
            ]
        ]


fabricSwatch : String -> String -> Html Msg
fabricSwatch color label =
    div [ class "mb3" ]
        [ div [ class (color ++ " w-100 h3 ba b--white-30 mb1") ] []
        , div [ class "f7 silver tc" ] [ text label ]
        ]


navArrow : String -> String -> Html Msg
navArrow symbol tooltip =
    div [ class "mh2 pv2 ph3 ba b--silver br2 pointer hover-bg-dark-gray tc" ]
        [ div [ class "f5" ] [ text symbol ]
        , div [ class "f7 silver" ] [ text tooltip ]
        ]


colorPalette : Html Msg
colorPalette =
    div [ class "w-100 flex mt3" ]
        [ colorBlock "bg-near-white" "13-4250"
        , colorBlock "bg-light-yellow" "15-0942"
        , colorBlock "bg-gold" "16-1054"
        , colorBlock "bg-light-red" "18-1664"
        , colorBlock "bg-navy" "19-4026"
        ]


colorBlock : String -> String -> Html Msg
colorBlock color code =
    div [ class "flex-auto" ]
        [ div [ class (color ++ " h2 ba b--white-30") ] []
        , div [ class "f7 silver tc mt1" ] [ text code ]
        ]


viewNoise : Html Msg
viewNoise =
    div
        [ class "fixed top-0 left-0 w-100 h-100 z-1 pointer-events-none o-10"
        , style "background-image" "url('data:image/svg+xml;utf8,<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"500\" height=\"500\" viewBox=\"0 0 500 500\"><filter id=\"n\"><feTurbulence type=\"fractalNoise\" baseFrequency=\"0.7\" numOctaves=\"10\" stitchTiles=\"stitch\"/></filter><rect width=\"500\" height=\"500\" filter=\"url(%23n)\" opacity=\"0.5\"/></svg>')"
        ]
        []


viewScanlines : Html Msg
viewScanlines =
    div
        [ class "fixed top-0 left-0 w-100 h-100 z-1 pointer-events-none o-20"
        , style "background" "linear-gradient(transparent 50%, rgba(0, 0, 0, 0.5) 50%)"
        , style "background-size" "100% 4px"
        ]
        []
