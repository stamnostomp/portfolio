module Main exposing (main)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Time



-- MODEL


type alias Model =
    { time : Float
    , currentPage : Page
    , menuOpen : Bool
    , loadingProgress : Float
    , isLoading : Bool
    , mouseX : Float
    , mouseY : Float
    }


type Page
    = Home
    | Projects
    | About
    | Contact


init : { width : Int, height : Int } -> ( Model, Cmd Msg )
init flags =
    ( { time = 0
      , currentPage = Home
      , menuOpen = False
      , loadingProgress = 0
      , isLoading = True
      , mouseX = 0
      , mouseY = 0
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Tick Float
    | ChangePage Page
    | ToggleMenu
    | IncrementLoading Float
    | FinishLoading
    | MouseMove Float Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick delta ->
            ( { model | time = model.time + delta * 0.001 }, Cmd.none )

        ChangePage page ->
            ( { model | currentPage = page, menuOpen = False }, Cmd.none )

        ToggleMenu ->
            ( { model | menuOpen = not model.menuOpen }, Cmd.none )

        IncrementLoading amount ->
            let
                newProgress =
                    Basics.min 100 (model.loadingProgress + amount)

                isComplete =
                    newProgress >= 100
            in
            ( { model
                | loadingProgress = newProgress
                , isLoading = not isComplete
              }
            , if isComplete then
                Cmd.none

              else
                Cmd.none
            )

        FinishLoading ->
            ( { model | isLoading = False }, Cmd.none )

        MouseMove x y ->
            ( { model | mouseX = x, mouseY = y }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ if model.isLoading then
            viewLoading model

          else
            viewMain model
        ]


viewLoading : Model -> Html Msg
viewLoading model =
    div [ class "fixed top-0 left-0 w-100 h-100 bg-black white code flex flex-column justify-center items-center z-999" ]
        [ h2 [ class "mb4 tracked-tight glitch" ] [ text "INITIALIZING SYSTEM" ]
        , div [ class "w-50 h1 ba b--white mv3 relative overflow-hidden" ]
            [ div
                [ class "h-100 bg-white absolute top-0 left-0 transition-all"
                , style "width" (String.fromFloat model.loadingProgress ++ "%")
                ]
                []
            ]
        , p [ class "mt3 blink" ] [ text "Please wait... " ]
        , div [ class "mt3 f7 o-50" ]
            [ text ("Loading " ++ String.fromInt (floor model.loadingProgress) ++ "% complete")
            ]
        , div [ class "absolute bottom-1 left-1 f7 o-50 code" ]
            [ text "v.2.5.0 | © 2025 DUNEDIN"
            ]
        ]


viewMain : Model -> Html Msg
viewMain model =
    div [ class "w-100 min-vh-100 bg-black white code relative overflow-hidden" ]
        [ viewHeader model
        , viewBrowserBar model
        , viewNavBar model
        , viewContent model
        , viewNoise
        , viewScanlines
        ]


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


viewContent : Model -> Html Msg
viewContent model =
    div [ class "pa3 flex flex-column" ]
        [ div [ class "w-100 bt bb b--gray pv2 mb3 flex items-center overflow-x-auto" ]
            (List.map viewNavigationItem
                [ "What's New?", "What's Cool?", "Handbook", "Net Search", "Net Directory", "Newsgroups" ]
            )
        , case model.currentPage of
            Home ->
                viewHomePage model

            Projects ->
                viewProjectsPage model

            About ->
                viewAboutPage model

            Contact ->
                viewContactPage model
        ]


viewNavigationItem : String -> Html Msg
viewNavigationItem label =
    div [ class "mr2 bg-light-gray pa1 br2 f7 gray pointer grow" ]
        [ text label ]


viewHomePage : Model -> Html Msg
viewHomePage model =
    div [ class "flex flex-wrap" ]
        [ div [ class "w-100 w-60-ns pa2" ]
            [ div [ class "pa3 br2 bg-navy blue mb3 relative overflow-hidden" ]
                [ h2 [ class "mt0 mb3 f3 pink" ] [ text "VIRTUAL DELIGHT" ]
                , p [ class "measure" ] [ text "Welcome to the digital utopia of tomorrow, where beauty is evolutionized and style is your interface to the world." ]
                , p [ class "measure" ] [ text "Browse the collections. Mix the fabrics. Create your virtual self." ]
                , div [ class "absolute top-0 right-0 pa2 o-70 f7" ]
                    [ text "ID: 1001100"
                    ]
                ]
            , div [ class "pa3 br2 bg-dark-blue light-blue" ]
                [ h3 [ class "mt0 mb2 f4 yellow" ] [ text "SYSTEM STATUS" ]
                , div [ class "flex flex-wrap" ]
                    [ statusBlock "Memory" "87%" "bg-pink"
                    , statusBlock "CPU" "42%" "bg-green"
                    , statusBlock "Network" "91%" "bg-gold"
                    , statusBlock "Data" "53%" "bg-light-purple"
                    ]
                ]
            ]
        , div [ class "w-100 w-40-ns pa2" ]
            [ div [ class "pa3 br2 bg-dark-gray near-white mb3" ]
                [ h3 [ class "mt0 mb3 f4 light-green" ] [ text "LATEST UPDATES" ]
                , ul [ class "list pl0" ]
                    [ updateItem "FABRIC SYSTEM v2.5" "05.13.2025"
                    , updateItem "NEURAL INTERFACE PATCH" "04.29.2025"
                    , updateItem "COLOR CALIBRATION UPDATE" "04.15.2025"
                    ]
                ]
            , colorPalette
            ]
        , div [ class "w-100 pa2 mt3" ]
            [ div [ class "flex justify-center" ]
                [ navArrow "◀" "Previous"
                , navArrow "▲" "Up"
                , navArrow "▶" "Next"
                ]
            ]
        ]


viewProjectsPage : Model -> Html Msg
viewProjectsPage model =
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


viewAboutPage : Model -> Html Msg
viewAboutPage model =
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
                    [ updateItem "NETWORK CAPACITY" "87%"
                    , updateItem "BANDWIDTH ALLOCATION" "42%"
                    , updateItem "ACCESS CLEARANCE" "LEVEL 5"
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


viewContactPage : Model -> Html Msg
viewContactPage model =
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


statusBlock : String -> String -> String -> Html Msg
statusBlock label value color =
    div [ class "w-50 pa2" ]
        [ div [ class "f7 silver mb1" ] [ text label ]
        , div [ class "w-100 h1 bg-white overflow-hidden" ]
            [ div [ class (color ++ " h-100"), style "width" value ] [] ]
        , div [ class "tr f7 silver mt1" ] [ text value ]
        ]


updateItem : String -> String -> Html Msg
updateItem title date =
    li [ class "pb2 mb2 bb b--gray-20" ]
        [ div [ class "flex justify-between items-center" ]
            [ span [ class "f7 near-white" ] [ text title ]
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onAnimationFrameDelta Tick
        , if model.isLoading && model.loadingProgress < 100 then
            Time.every 100 (\_ -> IncrementLoading (5 + model.loadingProgress / 20))

          else if model.isLoading && model.loadingProgress >= 100 then
            Time.every 500 (\_ -> FinishLoading)

          else
            Sub.none
        , Browser.Events.onMouseMove
            (Decode.map2 MouseMove
                (Decode.field "clientX" Decode.float)
                (Decode.field "clientY" Decode.float)
            )
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
