-- src/Main.elm - Updated with Tachyons CSS and complete goop styling


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
        , -- Enhanced CSS with goop effects and Tachyons
          node "style"
            []
            [ text """
                /* Cycle animation for gradient text */
                @keyframes cycle {
                    0% { background-position: 0% 50%; }
                    100% { background-position: 300% 50%; }
                }

                .cycle-colors {
                    background-image: linear-gradient(90deg, #ff00ea, #00c3ff, #ffe700, #ff00ea);
                    background-size: 300% auto;
                    color: transparent;
                    -webkit-background-clip: text;
                    background-clip: text;
                    animation: cycle 4s linear infinite;
                }

                /* Goop close button effects - enhanced visibility */
                .goop-close-button {
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.15) 0%,
                        rgba(64, 64, 64, 0.1) 50%,
                        rgba(0, 0, 0, 0.1) 100%) !important;
                    transition: all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    backdrop-filter: blur(2px);
                    animation: close-button-float 3s ease-in-out infinite;
                    border: 1px solid rgba(192, 192, 192, 0.4) !important;
                    color: rgba(192, 192, 192, 0.9) !important;
                    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2),
                                inset 0 1px 0 rgba(255, 255, 255, 0.1);
                }

                .goop-close-button::before {
                    content: '';
                    position: absolute;
                    top: -50%;
                    left: -50%;
                    width: 200%;
                    height: 200%;
                    background: conic-gradient(
                        from 0deg at 50% 50%,
                        transparent 0deg,
                        rgba(192, 192, 192, 0.1) 90deg,
                        transparent 180deg,
                        rgba(192, 192, 192, 0.05) 270deg,
                        transparent 360deg
                    );
                    animation: close-button-rotate 6s linear infinite;
                    opacity: 0;
                    transition: opacity 0.3s;
                }

                .goop-close-button:hover::before {
                    opacity: 1;
                }

                .goop-close-button:hover {
                    transform: translateY(-2px) scale(1.05);
                    border-color: rgba(192, 192, 192, 0.8) !important;
                    color: rgba(255, 255, 255, 0.95) !important;
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.25) 0%,
                        rgba(64, 64, 64, 0.15) 50%,
                        rgba(0, 0, 0, 0.1) 100%) !important;
                    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.3),
                                0 0 20px rgba(192, 192, 192, 0.2),
                                inset 0 1px 0 rgba(255, 255, 255, 0.2);
                    text-shadow: 0 0 10px rgba(192, 192, 192, 0.4);
                }

                @keyframes close-button-float {
                    0%, 100% { transform: translateY(0px); }
                    50% { transform: translateY(-1px); }
                }

                @keyframes close-button-rotate {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }

                /* Info card hover effects */
                .info-card {
                    background: rgba(0, 50, 100, 0.3);
                    border: 1px solid rgba(0, 150, 200, 0.3);
                    transition: all 0.3s ease;
                }

                .info-card:hover {
                    background: rgba(0, 70, 140, 0.4);
                    border-color: rgba(0, 150, 200, 0.6);
                    transform: translateY(-2px);
                    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
                }

                /* Project section styling */
                .project-section {
                    background: rgba(0, 50, 100, 0.2);
                    transition: all 0.3s ease;
                }

                .project-section:hover {
                    background: rgba(0, 70, 140, 0.3);
                }

                /* About section styling */
                .about-section {
                    background: rgba(100, 0, 50, 0.2);
                    transition: all 0.3s ease;
                }

                .about-section:hover {
                    background: rgba(120, 0, 60, 0.3);
                }

                /* Grid utility for Tachyons */
                .grid-2 {
                    display: grid;
                    grid-template-columns: repeat(2, 1fr);
                    gap: 1rem;
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
    div [ Attr.class "fixed top-0 left-0 w-100 h-100 z-2" ]
        [ -- WebGL Canvas for the goop effect
          WebGL.toHtml
            [ Attr.width (floor (Vec2.getX model.resolution))
            , Attr.height (floor (Vec2.getY model.resolution))
            , Attr.class "absolute top-0 left-0"
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
                [ Attr.class "fixed pointer-events-none z-3 monospace"
                , Attr.style "left" (String.fromFloat (Tuple.first labelPosition) ++ "px")
                , Attr.style "top" (String.fromFloat (Tuple.second labelPosition) ++ "px")
                , Attr.style "transform" "translate(-50%, -50%)"
                ]
                [ div
                    [ Attr.class "pa2 ph3 f6 fw6 white"
                    , Attr.style "background" "linear-gradient(135deg, rgba(0, 20, 40, 0.9), rgba(0, 40, 60, 0.8))"
                    , Attr.style "border" "1px solid rgba(0, 150, 200, 0.6)"
                    , Attr.style "box-shadow" "0 0 12px rgba(0, 150, 200, 0.4)"
                    , Attr.style "backdrop-filter" "blur(4px)"
                    , Attr.style "text-shadow" "0 0 8px rgba(0, 200, 255, 0.6)"
                    ]
                    [ div [] [ text label ]
                    , div [ Attr.class "f7 o-70 mt1" ]
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
                [ Attr.class "fixed z-3 overflow-auto monospace white"
                , Attr.style "left" (String.fromFloat leftPos ++ "px")
                , Attr.style "top" (String.fromFloat topPos ++ "px")
                , Attr.style "width" (String.fromFloat squareWidth ++ "px")
                , Attr.style "height" (String.fromFloat squareHeight ++ "px")
                ]
                [ -- Content without close button (now handled in Contact page)
                  div [ Attr.class "pa4 h-100 overflow-auto" ]
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
            div [ Attr.class "tc" ]
                [ h1 [ Attr.class "f1 mb3 cycle-colors" ]
                    [ text "VIRTUAL DELIGHT" ]
                , h2 [ Attr.class "f3 mb4 gray" ]
                    [ text "Y2K RETRO PORTFOLIO" ]
                , p [ Attr.class "f5 lh-copy mb4 mw6 center" ]
                    [ text "Welcome to the organic navigation system. Each branch represents a different section of the portfolio." ]
                , div [ Attr.class "grid-2 mw7 center" ]
                    [ viewInfoCard "🎯" "Interactive" "Mouse-driven organic UI"
                    , viewInfoCard "🌊" "WebGL" "Real-time shader effects"
                    , viewInfoCard "⚡" "Reactive" "Dynamic transformations"
                    , viewInfoCard "🔮" "Y2K Style" "Retro-futuristic design"
                    ]
                ]

        Projects ->
            div []
                [ h1 [ Attr.class "f2 mb4" ]
                    [ text "PROJECTS" ]
                , p [ Attr.class "f5 lh-copy mb4" ]
                    [ text "Here you can showcase your projects, portfolio pieces, and creative works." ]
                , div [ Attr.class "pa4 project-section" ]
                    [ h3 [ Attr.class "mb3" ]
                        [ text "Featured Project" ]
                    , p []
                        [ text "This goop navigation system itself is a project! An organic, WebGL-powered interface that morphs and responds to user interaction." ]
                    ]
                ]

        About ->
            div []
                [ h1 [ Attr.class "f2 mb4" ]
                    [ text "ABOUT" ]
                , p [ Attr.class "f5 lh-copy mb4" ]
                    [ text "This is where you can tell your story, share your background, and connect with visitors." ]
                , div [ Attr.class "pa4 about-section" ]
                    [ h3 [ Attr.class "mb3" ]
                        [ text "Developer" ]
                    , p []
                        [ text "Passionate about creating unique user experiences through code. This portfolio demonstrates organic UI design with WebGL shaders and Elm." ]
                    ]
                ]

        Contact ->
            -- Use the new Contact page module
            Pages.Contact.view



-- Info card helper


viewInfoCard : String -> String -> String -> Html Msg
viewInfoCard icon title description =
    div [ Attr.class "pa3 tc info-card" ]
        [ div [ Attr.class "f1 mb2" ] [ text icon ]
        , h4 [ Attr.class "f5 fw6 mb2" ] [ text title ]
        , p [ Attr.class "f6 lh-title" ] [ text description ]
        ]



-- Debug information (optional)


viewDebugInfo : Model -> Html Msg
viewDebugInfo model =
    div
        [ Attr.class "fixed bottom-2 left-2 f7 z-3 monospace pa2"
        , Attr.style "color" "#888"
        , Attr.style "background" "rgba(0, 0, 0, 0.5)"
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
