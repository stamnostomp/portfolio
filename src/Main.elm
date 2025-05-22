-- src/Main.elm - Updated to use the new Contact page module


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
import Pages.Contact
import Shaders.GoopBall
import Shaders.Mesh exposing (fullscreenMesh)
import Types exposing (Page(..))
import Update exposing (update)
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
    div [ Attr.class "relative w-100 min-vh-100 overflow-hidden bg-black" ]
        [ -- Goop navigation (WebGL provides the background)
          viewGoopNavigation model
        , -- Content square (when active)
          viewContentSquare model
        , -- Debug info (optional)
          viewDebugInfo model
        , -- Add CSS for the cycle animation and button hover
          node "style"
            []
            [ text """
            @keyframes cycle {
                0% { background-position: 0% 50%; }
                100% { background-position: 300% 50%; }
            }

            /* Close button hover effect */
            button:hover {
                border-color: rgba(0, 150, 255, 0.5) !important;
                color: rgba(200, 230, 255, 0.9) !important;
                box-shadow: 0 0 15px rgba(0, 150, 255, 0.2),
                            inset 0 0 10px rgba(0, 100, 200, 0.1);
                background: rgba(20, 40, 60, 0.3) !important;
            }
            """ ]
        ]



-- Goop navigation WebGL


viewGoopNavigation : Model -> Html Msg
viewGoopNavigation model =
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
        [ Attr.class "fixed top-0 left-0 w-100 h-100 z-2"
        , Attr.style "z-index" "2"
        ]
        [ -- WebGL Canvas for the goop effect
          WebGL.toHtml
            [ Attr.width (floor (Vec2.getX model.resolution))
            , Attr.height (floor (Vec2.getY model.resolution))
            , Attr.style "position" "absolute"
            , Attr.style "top" "0"
            , Attr.style "left" "0"
            , Attr.style "cursor" "crosshair"
            ]
            [ WebGL.entity
                Shaders.GoopBall.vertexShader
                Shaders.GoopBall.fragmentShader
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
        , -- Hover labels (only when not transitioning)
          if transitionProgress < 0.3 then
            viewHoverLabels model

          else
            text ""
        ]



-- Hover labels for branches


viewHoverLabels : Model -> Html Msg
viewHoverLabels model =
    case model.goopNavState.hoveredBranch of
        Nothing ->
            text ""

        Just branch ->
            let
                labelPosition =
                    getBranchLabelPosition branch model.resolution model.goopNavState.centerPosition model.time

                label =
                    GoopNav.getBranchLabel branch
            in
            div
                [ Attr.class "fixed pointer-events-none z-3"
                , Attr.style "left" (String.fromFloat (Tuple.first labelPosition) ++ "px")
                , Attr.style "top" (String.fromFloat (Tuple.second labelPosition) ++ "px")
                , Attr.style "transform" "translate(-50%, -50%)"
                , Attr.style "z-index" "3"
                , Attr.style "font-family" "monospace"
                ]
                [ div
                    [ Attr.style "padding" "8px 12px"
                    , Attr.style "border-radius" "4px"
                    , Attr.style "font-size" "14px"
                    , Attr.style "background" "linear-gradient(135deg, rgba(0, 20, 40, 0.9), rgba(0, 40, 60, 0.8))"
                    , Attr.style "border" "1px solid rgba(0, 150, 200, 0.6)"
                    , Attr.style "box-shadow" "0 0 12px rgba(0, 150, 200, 0.4)"
                    , Attr.style "backdrop-filter" "blur(4px)"
                    , Attr.style "color" "white"
                    , Attr.style "text-shadow" "0 0 8px rgba(0, 200, 255, 0.6)"
                    , Attr.style "font-weight" "600"
                    ]
                    [ div [] [ text label ]
                    , div
                        [ Attr.style "font-size" "11px"
                        , Attr.style "opacity" "0.7"
                        , Attr.style "margin-top" "4px"
                        ]
                        [ text "◦ CLICK TO EXPAND ◦" ]
                    ]
                ]



-- Calculate screen position for branch labels


getBranchLabelPosition : GoopNav.NavBranch -> Vec2.Vec2 -> Vec2.Vec2 -> Float -> ( Float, Float )
getBranchLabelPosition branch resolution center time =
    let
        branchPositions =
            GoopNav.getBranchPositions center time

        branchIndex =
            GoopNav.branchToIndex branch

        branchPos =
            branchPositions
                |> List.drop branchIndex
                |> List.head
                |> Maybe.withDefault center

        aspectRatio =
            Vec2.getX resolution / Vec2.getY resolution

        adjustedX =
            Vec2.getX branchPos / aspectRatio

        screenX =
            (adjustedX + 1.0) * Vec2.getX resolution / 2.0

        screenY =
            (1.0 - Vec2.getY branchPos) * Vec2.getY resolution / 2.0

        offsetX =
            if Vec2.getX branchPos > 0 then
                30

            else
                -30

        offsetY =
            if Vec2.getY branchPos > 0 then
                30

            else
                -30
    in
    ( screenX + offsetX, screenY + offsetY )



-- Content square display


viewContentSquare : Model -> Html Msg
viewContentSquare model =
    case model.transitionState of
        ShowingContent page _ ->
            let
                centerX =
                    Vec2.getX model.resolution / 2

                centerY =
                    Vec2.getY model.resolution / 2

                squareSize =
                    min (Vec2.getX model.resolution) (Vec2.getY model.resolution) * 0.75

                -- Make it more rectangular to match the shader
                squareWidth =
                    squareSize * 1.2

                squareHeight =
                    squareSize * 0.85

                leftPos =
                    centerX - squareWidth / 2

                topPos =
                    centerY - squareHeight / 2
            in
            div
                [ Attr.class "fixed z-3"
                , Attr.style "left" (String.fromFloat leftPos ++ "px")
                , Attr.style "top" (String.fromFloat topPos ++ "px")
                , Attr.style "width" (String.fromFloat squareWidth ++ "px")
                , Attr.style "height" (String.fromFloat squareHeight ++ "px")
                , Attr.style "z-index" "3"
                , Attr.style "overflow" "auto"
                , Attr.style "background" "rgba(20, 20, 25, 0.7)"
                , Attr.style "border" "1px solid rgba(70, 70, 75, 0.4)"
                , Attr.style "border-radius" "8px"
                , Attr.style "backdrop-filter" "blur(8px)"
                , Attr.style "box-shadow" "0 0 30px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(80, 80, 85, 0.2)"
                , Attr.style "font-family" "monospace"
                , Attr.style "color" "white"
                ]
                [ -- Close button
                  button
                    [ Attr.style "position" "absolute"
                    , Attr.style "top" "8px"
                    , Attr.style "right" "8px"
                    , Attr.style "background" "transparent"
                    , Attr.style "color" "#999"
                    , Attr.style "padding" "8px 12px"
                    , Attr.style "border" "1px solid rgba(80, 80, 80, 0.3)"
                    , Attr.style "border-radius" "4px"
                    , Attr.style "cursor" "pointer"
                    , Attr.style "font-size" "12px"
                    , Attr.style "font-family" "monospace"
                    , Attr.style "z-index" "4"
                    , Attr.style "transition" "all 0.3s"
                    , onClick CloseContent
                    ]
                    [ text "✕ CLOSE" ]
                , -- Content
                  div
                    [ Attr.style "padding" "32px"
                    , Attr.style "height" "100%"
                    , Attr.style "overflow" "auto"
                    ]
                    [ viewPageContent page model ]
                ]

        TransitioningOut progress page ->
            if progress > 0.7 then
                viewContentSquare { model | transitionState = ShowingContent page 0.0 }

            else
                text ""

        _ ->
            text ""



-- Simple content for each page


viewPageContent : Page -> Model -> Html Msg
viewPageContent page model =
    case page of
        Home ->
            div [ Attr.style "text-align" "center" ]
                [ h1
                    [ Attr.style "font-size" "48px"
                    , Attr.style "margin-bottom" "16px"
                    , Attr.style "background" "linear-gradient(90deg, #ff00ea, #00c3ff, #ffe700)"
                    , Attr.style "background-size" "300% auto"
                    , Attr.style "color" "transparent"
                    , Attr.style "-webkit-background-clip" "text"
                    , Attr.style "background-clip" "text"
                    , Attr.style "animation" "cycle 4s linear infinite"
                    ]
                    [ text "VIRTUAL DELIGHT" ]
                , h2
                    [ Attr.style "font-size" "24px"
                    , Attr.style "margin-bottom" "24px"
                    , Attr.style "color" "#888"
                    ]
                    [ text "Y2K RETRO PORTFOLIO" ]
                , p
                    [ Attr.style "font-size" "16px"
                    , Attr.style "line-height" "1.6"
                    , Attr.style "color" "#00c3ff"
                    , Attr.style "max-width" "400px"
                    , Attr.style "margin" "0 auto 32px"
                    ]
                    [ text "Welcome to the organic navigation system. Each branch represents a different section of the portfolio." ]
                , div
                    [ Attr.style "display" "grid"
                    , Attr.style "grid-template-columns" "repeat(2, 1fr)"
                    , Attr.style "gap" "16px"
                    , Attr.style "max-width" "500px"
                    , Attr.style "margin" "0 auto"
                    ]
                    [ viewInfoCard "🎯" "Interactive" "Mouse-driven organic UI"
                    , viewInfoCard "🌊" "WebGL" "Real-time shader effects"
                    , viewInfoCard "⚡" "Reactive" "Dynamic transformations"
                    , viewInfoCard "🔮" "Y2K Style" "Retro-futuristic design"
                    ]
                ]

        Projects ->
            div []
                [ h1 [ Attr.style "font-size" "36px", Attr.style "margin-bottom" "24px", Attr.style "color" "#00c3ff" ] [ text "PROJECTS" ]
                , p [ Attr.style "font-size" "16px", Attr.style "line-height" "1.6", Attr.style "margin-bottom" "24px" ]
                    [ text "Here you can showcase your projects, portfolio pieces, and creative works." ]
                , div [ Attr.style "padding" "24px", Attr.style "background" "rgba(0, 50, 100, 0.2)", Attr.style "border-radius" "8px" ]
                    [ h3 [ Attr.style "color" "#ff00ea", Attr.style "margin-bottom" "16px" ] [ text "Featured Project" ]
                    , p [ Attr.style "color" "#ccc" ] [ text "This goop navigation system itself is a project! An organic, WebGL-powered interface that morphs and responds to user interaction." ]
                    ]
                ]

        About ->
            div []
                [ h1 [ Attr.style "font-size" "36px", Attr.style "margin-bottom" "24px", Attr.style "color" "#00c3ff" ] [ text "ABOUT" ]
                , p [ Attr.style "font-size" "16px", Attr.style "line-height" "1.6", Attr.style "margin-bottom" "24px" ]
                    [ text "This is where you can tell your story, share your background, and connect with visitors." ]
                , div [ Attr.style "padding" "24px", Attr.style "background" "rgba(100, 0, 50, 0.2)", Attr.style "border-radius" "8px" ]
                    [ h3 [ Attr.style "color" "#ffe700", Attr.style "margin-bottom" "16px" ] [ text "Developer" ]
                    , p [ Attr.style "color" "#ccc" ] [ text "Passionate about creating unique user experiences through code. This portfolio demonstrates organic UI design with WebGL shaders and Elm." ]
                    ]
                ]

        Contact ->
            -- Use the new Contact page module
            Pages.Contact.view



-- Info card helper


viewInfoCard : String -> String -> String -> Html Msg
viewInfoCard icon title description =
    div
        [ Attr.style "padding" "16px"
        , Attr.style "background" "rgba(0, 50, 100, 0.3)"
        , Attr.style "border" "1px solid rgba(0, 150, 200, 0.3)"
        , Attr.style "border-radius" "8px"
        , Attr.style "text-align" "center"
        ]
        [ div [ Attr.style "font-size" "32px", Attr.style "margin-bottom" "8px" ] [ text icon ]
        , h4 [ Attr.style "font-size" "16px", Attr.style "font-weight" "bold", Attr.style "margin-bottom" "8px", Attr.style "color" "#00c3ff" ] [ text title ]
        , p [ Attr.style "font-size" "12px", Attr.style "color" "#888", Attr.style "line-height" "1.4" ] [ text description ]
        ]



-- Debug information (optional)


viewDebugInfo : Model -> Html Msg
viewDebugInfo model =
    div
        [ Attr.style "position" "fixed"
        , Attr.style "bottom" "8px"
        , Attr.style "left" "8px"
        , Attr.style "font-size" "12px"
        , Attr.style "color" "#888"
        , Attr.style "z-index" "3"
        , Attr.style "font-family" "monospace"
        , Attr.style "background" "rgba(0, 0, 0, 0.5)"
        , Attr.style "padding" "8px"
        , Attr.style "border-radius" "4px"
        ]
        [ div [] [ text ("FPS: " ++ (String.fromFloat (1000 / max 1 (model.time * 1000)) |> String.left 5)) ]
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
        "Escape" ->
            CloseContent

        _ ->
            Tick 0
