-- src/Main.elm - Enhanced with content square display


module Main exposing (main)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (..)
import Json.Decode as Decode
import Math.Vector2 as Vec2
import Model exposing (Model, Msg(..), TransitionState(..), init)
import Navigation.GoopNav as GoopNav
import Shaders.Background
import Shaders.Mesh exposing (fullscreenMesh)
import Types exposing (Page(..))
import Update exposing (update)
import View.About
import View.Common exposing (..)
import View.Contact
import View.GoopNavigation
import View.Projects
import WebGL



-- MAIN PROGRAM


main : Program { width : Int, height : Int } Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- VIEW


view : Model -> Html Msg
view model =
    div [ Attr.class "relative w-100 min-vh-100 overflow-hidden" ]
        [ -- Background WebGL shader
          viewBackground model
        , -- Content based on transition state
          viewContent model
        , -- Goop navigation overlay (when not in content mode)
          viewGoopNavigation model
        , -- Loading screen (if needed)
          viewLoadingScreen model
        , -- Browser-like UI elements (only when not in content mode)
          viewBrowserUI model
        , -- Debug info
          viewDebugInfo model
        ]



-- Background WebGL shader


viewBackground : Model -> Html Msg
viewBackground model =
    div
        [ Attr.style "position" "fixed"
        , Attr.style "top" "0"
        , Attr.style "left" "0"
        , Attr.style "width" "100%"
        , Attr.style "height" "100%"
        , Attr.style "background" "linear-gradient(45deg, #0a0a0a, #1a1a1a)"
        , Attr.style "z-index" "0"
        , Attr.class "pointer-events-none"
        ]
        []



-- Enhanced goop navigation view with transition support


viewGoopNavigation : Model -> Html Msg
viewGoopNavigation model =
    if not model.showGoopNav then
        text ""

    else
        let
            -- Calculate transition parameters
            ( transitionProgress, transitionType ) =
                case model.transitionState of
                    TransitioningOut progress _ ->
                        ( progress, 1.0 )

                    TransitioningIn progress _ ->
                        ( progress, -1.0 )

                    ShowingContent _ _ ->
                        ( 1.0, 1.0 )

                    NoTransition ->
                        ( 0.0, 0.0 )
        in
        div
            [ Attr.class "fixed top-0 left-0 w-100 h-100 pointer-events-none z-2"
            , Attr.style "z-index" "2"
            ]
            [ -- WebGL Canvas for the goop effect
              WebGL.toHtml
                [ Attr.width (floor (Vec2.getX model.resolution))
                , Attr.height (floor (Vec2.getY model.resolution))
                , Attr.style "position" "absolute"
                , Attr.style "top" "0"
                , Attr.style "left" "0"
                , Attr.style "pointer-events" "auto"
                , Attr.style "cursor" "crosshair"
                , Attr.class "goop-navigation-container"
                ]
                [ WebGL.entity
                    View.GoopNavigation.vertexShader
                    View.GoopNavigation.fragmentShader
                    fullscreenMesh
                    { time = model.time
                    , resolution = model.resolution
                    , mousePosition = model.mousePosition
                    , hoveredBranch = GoopNav.getHoveredBranch model.goopNavState
                    , centerPosition = model.goopNavState.centerPosition
                    , transitionProgress = transitionProgress
                    , transitionType = transitionType
                    }
                ]
            , -- Overlay for hover labels (only when not transitioning)
              if transitionProgress < 0.3 then
                View.GoopNavigation.viewHoverLabels model

              else
                text ""
            , -- Toggle button for debugging
              View.GoopNavigation.viewGoopToggle model
            ]



-- Content display based on transition state


viewContent : Model -> Html Msg
viewContent model =
    case model.transitionState of
        ShowingContent page _ ->
            viewContentSquare model page

        TransitioningOut progress page ->
            if progress > 0.7 then
                viewContentSquare model page

            else
                viewMainContent model

        TransitioningIn _ _ ->
            text ""

        NoTransition ->
            viewMainContent model



-- Content displayed inside the expanded square


viewContentSquare : Model -> Page -> Html Msg
viewContentSquare model page =
    let
        -- Calculate the square's screen position and size
        centerX =
            Vec2.getX model.resolution / 2

        centerY =
            Vec2.getY model.resolution / 2

        -- Size of the content square (80% of the smaller dimension)
        squareSize =
            min (Vec2.getX model.resolution) (Vec2.getY model.resolution) * 0.8

        leftPos =
            centerX - squareSize / 2

        topPos =
            centerY - squareSize / 2
    in
    div
        [ Attr.class "fixed z-3 pointer-events-auto"
        , Attr.style "left" (String.fromFloat leftPos ++ "px")
        , Attr.style "top" (String.fromFloat topPos ++ "px")
        , Attr.style "width" (String.fromFloat squareSize ++ "px")
        , Attr.style "height" (String.fromFloat squareSize ++ "px")
        , Attr.style "z-index" "3"
        , Attr.style "overflow" "auto"
        , Attr.style "background" "rgba(10, 10, 15, 0.95)"
        , Attr.style "border" "2px solid rgba(0, 200, 255, 0.8)"
        , Attr.style "border-radius" "8px"
        , Attr.style "backdrop-filter" "blur(10px)"
        , Attr.style "box-shadow" "0 0 30px rgba(0, 200, 255, 0.3)"
        , Attr.class "transition-all"
        ]
        [ -- Close button
          button
            [ Attr.class "absolute top-2 right-2 bg-transparent white pa2 br2 pointer f6 z-4"
            , Attr.style "border" "1px solid rgba(255, 255, 255, 0.3)"
            , Attr.style "z-index" "4"
            , onClick CloseContent
            ]
            [ text "✕ CLOSE" ]
        , -- Content
          div [ Attr.class "pa4 white h-100 overflow-auto" ]
            [ case page of
                Home ->
                    viewHomeContent model

                Projects ->
                    div []
                        [ h1 [ Attr.class "f2 mb3 light-blue" ] [ text "PROJECTS" ]
                        , View.Projects.view model
                        ]

                About ->
                    div []
                        [ h1 [ Attr.class "f2 mb3 light-blue" ] [ text "ABOUT" ]
                        , View.About.view model
                        ]

                Contact ->
                    div []
                        [ h1 [ Attr.class "f2 mb3 light-blue" ] [ text "CONTACT" ]
                        , View.Contact.view model
                        ]
            ]
        ]



-- Home content for the square


viewHomeContent : Model -> Html Msg
viewHomeContent model =
    div [ Attr.class "tc" ]
        [ h1 [ Attr.class "f1 mb4 cycle-colors" ] [ text "VIRTUAL DELIGHT" ]
        , h2 [ Attr.class "f3 mb3 silver" ] [ text "Y2K RETRO PORTFOLIO" ]
        , p [ Attr.class "f4 mb4 light-blue measure center lh-copy" ]
            [ text "Welcome to the digital realm where organic interfaces meet cyberpunk aesthetics. Navigate through this interactive space using the goop navigation system." ]
        , div [ Attr.class "flex flex-wrap justify-center gap-3 mb4" ]
            [ viewContentCard "🎯" "Interactive Navigation" "Goop-based UI with organic responses"
            , viewContentCard "🌊" "WebGL Shaders" "Real-time visual effects and animations"
            , viewContentCard "⚡" "Reactive Design" "Mouse-driven interface transformations"
            , viewContentCard "🔮" "Y2K Aesthetic" "Retro-futuristic visual styling"
            ]
        , div [ Attr.class "mt4 pa3 br2 bg-dark-gray" ]
            [ h3 [ Attr.class "f4 mb2 hot-pink" ] [ text "SYSTEM STATUS" ]
            , div [ Attr.class "f6 silver" ]
                [ div [] [ text ("Time: " ++ (String.fromFloat model.time |> String.left 6)) ]
                , div [] [ text ("Mouse: " ++ (String.fromFloat model.mouseX |> String.left 4) ++ ", " ++ (String.fromFloat model.mouseY |> String.left 4)) ]
                , div [] [ text "Status: GOOP NAVIGATION ACTIVE" ]
                ]
            ]
        ]



-- Content card helper


viewContentCard : String -> String -> String -> Html Msg
viewContentCard icon title description =
    div
        [ Attr.class "w5 pa3 br2 bg-navy white ma2"
        , Attr.style "border" "1px solid rgba(0, 150, 200, 0.3)"
        ]
        [ div [ Attr.class "f2 tc mb2" ] [ text icon ]
        , h4 [ Attr.class "f5 fw7 mb2 light-blue tc" ] [ text title ]
        , p [ Attr.class "f7 silver tc lh-copy" ] [ text description ]
        ]



-- Main content area (when not in content square mode)


viewMainContent : Model -> Html Msg
viewMainContent model =
    div
        [ Attr.class "relative z-1 pa4 mt5"
        , Attr.style "min-height" "calc(100vh - 200px)"
        ]
        [ case model.currentPage of
            Home ->
                viewHomePage model

            Projects ->
                View.Projects.view model

            About ->
                View.About.view model

            Contact ->
                View.Contact.view model
        ]



-- Home page content (original)


viewHomePage : Model -> Html Msg
viewHomePage model =
    div [ Attr.class "flex flex-wrap items-center justify-center min-vh-50" ]
        [ div [ Attr.class "w-100 w-60-ns tc pa4" ]
            [ h1
                [ Attr.class "f1 mb4 glitch cycle-colors"
                , Attr.attribute "data-text" "VIRTUAL DELIGHT"
                ]
                [ text "VIRTUAL DELIGHT" ]
            , h2 [ Attr.class "f3 mb3 silver" ] [ text "Y2K RETRO PORTFOLIO" ]
            , p [ Attr.class "f4 mb4 light-blue measure center" ]
                [ text "Navigate through cyberspace using the interactive goop navigation. Click on the metallic branches to explore different sections." ]
            , div [ Attr.class "f6 silver mb4" ]
                [ p [] [ text "✨ WebGL goop navigation active" ]
                , p [] [ text "🎯 Mouse tracking enabled" ]
                , p [] [ text "🌊 Organic UI elements" ]
                , p [] [ text "⚡ Real-time shader effects" ]
                ]
            , div [ Attr.class "pa3 br2 bg-dark-gray white mb3 tc" ]
                [ h3 [ Attr.class "mt0 mb2 f5 hot-pink" ] [ text "NAVIGATION INSTRUCTIONS" ]
                , p [ Attr.class "f7 silver" ] [ text "Hover over the metallic goop ball in the center" ]
                , p [ Attr.class "f7 silver" ] [ text "Eight branches will respond to your mouse movement" ]
                , p [ Attr.class "f7 silver" ] [ text "Click on any branch to open content in an expanding square" ]
                , p [ Attr.class "f7 hot-pink fw7" ] [ text "NEW: Content opens in morphing container!" ]
                ]
            ]
        ]



-- Browser UI (only show when not in content mode)


viewBrowserUI : Model -> Html Msg
viewBrowserUI model =
    case model.transitionState of
        ShowingContent _ _ ->
            text ""

        _ ->
            div []
                [ viewHeader model
                , viewBrowserBar model
                , viewNavBar model
                ]



-- Loading screen


viewLoadingScreen : Model -> Html Msg
viewLoadingScreen model =
    if not model.isLoading then
        text ""

    else
        div
            [ Attr.class "fixed top-0 left-0 w-100 h-100 bg-black flex items-center justify-center z-999"
            , Attr.style "z-index" "999"
            ]
            [ div [ Attr.class "tc" ]
                [ div [ Attr.class "f2 mb4 glitch", Attr.attribute "data-text" "LOADING..." ]
                    [ text "LOADING..." ]
                , div [ Attr.class "w5 h1 bg-dark-gray br2 overflow-hidden" ]
                    [ div
                        [ Attr.class "loading-progress h-100"
                        , Attr.style "width" (String.fromFloat model.loadingProgress ++ "%")
                        ]
                        []
                    ]
                , div [ Attr.class "f7 silver mt2" ]
                    [ text (String.fromFloat model.loadingProgress ++ "% COMPLETE") ]
                ]
            ]



-- Debug information


viewDebugInfo : Model -> Html Msg
viewDebugInfo model =
    div [ Attr.class "fixed bottom-2 left-2 f7 silver z-3" ]
        [ div [] [ text ("FPS: " ++ String.fromFloat (1000 / max 1 (model.time * 1000)) |> String.left 5) ]
        , div [] [ text ("Mouse: " ++ (String.fromFloat model.mouseX |> String.left 5) ++ ", " ++ (String.fromFloat model.mouseY |> String.left 5)) ]
        , div [] [ text ("Page: " ++ pageToString model.currentPage) ]
        , div []
            [ text
                ("Goop: "
                    ++ (case model.goopNavState.hoveredBranch of
                            Nothing ->
                                "None"

                            Just branch ->
                                GoopNav.getBranchLabel branch
                       )
                )
            ]
        , div [] [ text ("Transition: " ++ transitionStateToString model.transitionState) ]
        ]



-- Helper functions


pageToString : Page -> String
pageToString page =
    case page of
        Home ->
            "HOME"

        Projects ->
            "PROJECTS"

        About ->
            "ABOUT"

        Contact ->
            "CONTACT"


transitionStateToString : TransitionState -> String
transitionStateToString state =
    case state of
        NoTransition ->
            "NONE"

        TransitioningOut progress _ ->
            "OUT " ++ (String.fromFloat progress |> String.left 4)

        ShowingContent _ time ->
            "CONTENT " ++ (String.fromFloat time |> String.left 4)

        TransitioningIn progress _ ->
            "IN " ++ (String.fromFloat progress |> String.left 4)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onAnimationFrameDelta Tick
        , Browser.Events.onMouseMove
            (Decode.map2 MouseMove
                (Decode.field "clientX" Decode.float)
                (Decode.field "clientY" Decode.float)
            )
        , Browser.Events.onResize WindowResize
        , Browser.Events.onClick
            (Decode.map2 MouseClick
                (Decode.field "clientX" Decode.float)
                (Decode.field "clientY" Decode.float)
            )
        , Browser.Events.onKeyPress keyDecoder
        ]


keyDecoder : Decode.Decoder Msg
keyDecoder =
    Decode.map toKey (Decode.field "key" Decode.string)


toKey : String -> Msg
toKey key =
    case key of
        " " ->
            ToggleGoopNav

        "h" ->
            ChangePage Home

        "p" ->
            ChangePage Projects

        "a" ->
            ChangePage About

        "c" ->
            ChangePage Contact

        "Escape" ->
            CloseContent

        _ ->
            Tick 0
