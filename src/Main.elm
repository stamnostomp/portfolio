-- src/Main.elm - Fixed version importing Page from Types


module Main exposing (main)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (..)
import Json.Decode as Decode
import Math.Vector2 as Vec2
import Model exposing (Model, Msg(..), init)
import Navigation.GoopNav as GoopNav
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
        , -- Main content based on current page
          viewMainContent model
        , -- Goop navigation overlay
          View.GoopNavigation.viewGoopNavigation model
        , -- Loading screen (if needed)
          viewLoadingScreen model
        , -- Browser-like UI elements
          viewHeader model
        , viewBrowserBar model
        , viewNavBar model
        , -- Debug info
          viewDebugInfo model
        ]



-- Background WebGL shader


viewBackground : Model -> Html Msg
viewBackground model =
    WebGL.toHtml
        [ Attr.width (floor (Vec2.getX model.resolution))
        , Attr.height (floor (Vec2.getY model.resolution))
        , Attr.style "position" "fixed"
        , Attr.style "top" "0"
        , Attr.style "left" "0"
        , Attr.style "z-index" "0"
        , Attr.class "pointer-events-none"
        ]
        [-- You can add your background shader here if you have one
         -- For now, we'll use CSS background
        ]



-- Main content area


viewMainContent : Model -> Html Msg
viewMainContent model =
    div
        [ Attr.class "relative z-1 pa4 mt5" -- Account for header space
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



-- Home page content


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
            , -- Navigation instructions
              div [ Attr.class "pa3 br2 bg-dark-gray white mb3 tc" ]
                [ h3 [ Attr.class "mt0 mb2 f5 hot-pink" ] [ text "NAVIGATION INSTRUCTIONS" ]
                , p [ Attr.class "f7 silver" ] [ text "Hover over the metallic goop ball in the center" ]
                , p [ Attr.class "f7 silver" ] [ text "Eight branches will respond to your mouse movement" ]
                , p [ Attr.class "f7 silver" ] [ text "Click on any branch to navigate to that section" ]
                ]
            ]
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
        ]



-- Convert page to string for debug


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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ -- Animation frame for smooth updates
          Browser.Events.onAnimationFrameDelta Tick
        , -- Mouse movement tracking
          Browser.Events.onMouseMove
            (Decode.map2 MouseMove
                (Decode.field "clientX" Decode.float)
                (Decode.field "clientY" Decode.float)
            )
        , -- Window resize handling
          Browser.Events.onResize WindowResize
        , -- Mouse clicks for goop navigation
          Browser.Events.onClick
            (Decode.map2 MouseClick
                (Decode.field "clientX" Decode.float)
                (Decode.field "clientY" Decode.float)
            )
        , -- Keyboard controls (optional)
          Browser.Events.onKeyPress keyDecoder
        ]



-- Keyboard decoder for additional controls


keyDecoder : Decode.Decoder Msg
keyDecoder =
    Decode.map toKey (Decode.field "key" Decode.string)


toKey : String -> Msg
toKey key =
    case key of
        " " ->
            ToggleGoopNav

        -- Spacebar toggles goop nav
        "h" ->
            ChangePage Home

        "p" ->
            ChangePage Projects

        "a" ->
            ChangePage About

        "c" ->
            ChangePage Contact

        _ ->
            Tick 0



-- No-op for other keys
