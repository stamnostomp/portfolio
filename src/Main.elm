module Main exposing (main)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Model exposing (Model, Msg(..), Page(..), init)
import Time
import Update exposing (update)
import View.About
import View.Common exposing (viewBrowserBar, viewHeader, viewNavBar, viewNavigationItem, viewNoise, viewScanlines)
import View.Contact
import View.Home
import View.Projects


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


viewContent : Model -> Html Msg
viewContent model =
    div [ class "pa3 flex flex-column" ]
        [ div [ class "w-100 bt bb b--gray pv2 mb3 flex items-center overflow-x-auto" ]
            (List.map viewNavigationItem
                [ "What's New?", "What's Cool?", "Handbook", "Net Search", "Net Directory", "Newsgroups" ]
            )
        , case model.currentPage of
            Home ->
                View.Home.view model

            Projects ->
                View.Projects.view model

            About ->
                View.About.view model

            Contact ->
                View.Contact.view model
        ]



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
