-- src/Main.elm - Updated with Portfolio page support and Tachyons CSS


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
import Pages.About
import Pages.Blog
import Pages.Contact
import Pages.Games
import Pages.Games.MissileCommand as MissileCommand
import Pages.Games.RatSnatcher as RatSnatcher
import Pages.Games.Shooter as Shooter
import Pages.Links
import Pages.Portfolio
import Pages.Projects
import Pages.Services
import Ports
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

        -- Debug info (hidden)
        -- , viewDebugInfo model
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


calculateContentSquareDimensions : Vec2.Vec2 -> { width : Float, height : Float, left : Float, top : Float }
calculateContentSquareDimensions resolution =
    let
        centerX =
            Vec2.getX resolution / 2

        centerY =
            Vec2.getY resolution / 2

        viewportWidth =
            Vec2.getX resolution

        viewportHeight =
            Vec2.getY resolution

        -- Match the shader's rectangle calculation exactly
        -- Shader draws: vec2(0.85 * aspectRatio * 0.85, 0.85 * 0.71)
        -- These are half-extents in shader coordinates
        -- Shader coordinate system: vertical [-1,1] maps to viewport height
        -- So 1 shader unit = viewport height / 2
        -- Rectangle half-height in shader units: 0.85 * 0.71 = 0.6035
        -- Full height: 2 * 0.6035 * (viewport height / 2) = 0.6035 * viewport height
        squareHeight =
            viewportHeight * 0.6035

        -- Rectangle half-width in shader units: 0.85 * aspectRatio * 0.85 = 0.7225 * aspectRatio
        -- Full width: 2 * 0.7225 * aspectRatio * (viewport width / (2 * aspectRatio)) = 0.7225 * viewport width
        squareWidth =
            viewportWidth * 0.7225

        -- Center the content
        leftPos =
            centerX - squareWidth / 2

        topPos =
            centerY - squareHeight / 2
    in
    { width = squareWidth, height = squareHeight, left = leftPos, top = topPos }


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

        -- Canvas always stays full screen
        canvasDims =
            { width = Vec2.getX model.resolution
            , height = Vec2.getY model.resolution
            , left = 0
            , top = 0
            }
    in
    div [ Attr.class "fixed top-0 left-0 w-100 h-100 z-2" ]
        [ -- WebGL Canvas for the goop effect
          WebGL.toHtml
            [ Attr.width (floor canvasDims.width)
            , Attr.height (floor canvasDims.height)
            , Attr.class "absolute"
            , Attr.style "left" (String.fromFloat canvasDims.left ++ "px")
            , Attr.style "top" (String.fromFloat canvasDims.top ++ "px")
            , Attr.style "cursor" "crosshair"
            ]
            [ WebGL.entity
                Shaders.GoopBall.vertexShader
                Shaders.GoopBall.fragmentShader
                fullscreenMesh
                { time = model.time
                , resolution = model.resolution
                , mousePosition = model.mousePosition
                , hoveredBranch =
                    case GoopNav.getHoveredBranch model.goopNavState of
                        Just branch ->
                            toFloat (GoopNav.branchToIndex branch)

                        Nothing ->
                            -1.0
                , centerPosition = model.goopNavState.centerPosition
                , transitionProgress = transitionProgress
                , transitionType = transitionType
                , gameExpand = model.gameExpand
                }
            ]
        , -- Hover labels (only when not transitioning)
          if transitionProgress < 0.3 then
            viewHoverLabels model

          else
            text ""
        , -- Center label (only when not transitioning)
          if transitionProgress < 0.3 then
            viewCenterLabel model

          else
            text ""
        ]



-- Center label for hovered branch


viewCenterLabel : Model -> Html Msg
viewCenterLabel model =
    case model.goopNavState.hoveredBranch of
        Nothing ->
            text ""

        Just branch ->
            let
                centerX =
                    Vec2.getX model.resolution / 2

                centerY =
                    Vec2.getY model.resolution / 2

                label =
                    GoopNav.getBranchLabel branch

                -- Floating animation based on time
                floatOffsetY =
                    sin (model.time * 2.0) * 3.0

                floatOffsetX =
                    cos (model.time * 1.5) * 2.0
            in
            div
                [ Attr.class "dn fixed pointer-events-none z-3 monospace tc center-goop-label"
                , Attr.style "left" (String.fromFloat (centerX + floatOffsetX) ++ "px")
                , Attr.style "top" (String.fromFloat (centerY + floatOffsetY) ++ "px")
                , Attr.style "transform" "translate(-50%, -50%)"
                ]
                [ div
                    [ Attr.class "f5 fw6"
                    , Attr.style "color" "rgba(192, 192, 192, 0.9)"
                    , Attr.style "text-shadow" "0 0 8px rgba(192, 192, 192, 0.5), 0 0 16px rgba(192, 192, 192, 0.3)"
                    ]
                    [ text label ]
                , div
                    [ Attr.class "f7 mt1"
                    , Attr.style "color" "rgba(192, 192, 192, 0.6)"
                    , Attr.style "text-shadow" "0 0 6px rgba(192, 192, 192, 0.4)"
                    ]
                    [ text "◦ CLICK TO EXPAND ◦" ]
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
        ShowingContent Games _ ->
            -- The Games page shows the list; opening a game swaps to its panel.
            if gameOpen model then
                viewFullscreenGame model

            else
                viewContentPanel Games model

        ShowingContent page _ ->
            viewContentPanel page model

        TransitioningOut progress page ->
            if progress > 0.7 then
                viewContentSquare { model | transitionState = ShowingContent page 0.0 }

            else
                text ""

        _ ->
            text ""


{-| Ids of games that actually have a playable implementation. -}
playableGames : List String
playableGames =
    [ "missile-command", "shooter", "rat-snatcher" ]


{-| True when a playable game is open on the Games page. -}
gameOpen : Model -> Bool
gameOpen model =
    case model.transitionState of
        ShowingContent Games _ ->
            case model.selectedGame of
                Just id ->
                    List.member id playableGames

                Nothing ->
                    False

        _ ->
            False


{-| The standard centered content square used by every page (and the Games list). -}
viewContentPanel : Page -> Model -> Html Msg
viewContentPanel page model =
    let
        dims =
            calculateContentSquareDimensions model.resolution
    in
    div
        [ Attr.class "fixed z-3 overflow-hidden monospace white"
        , Attr.style "left" (String.fromFloat dims.left ++ "px")
        , Attr.style "top" (String.fromFloat dims.top ++ "px")
        , Attr.style "width" (String.fromFloat dims.width ++ "px")
        , Attr.style "height" (String.fromFloat dims.height ++ "px")
        ]
        [ -- Content container - full height for blog/portfolio/games, padded for others
          if page == Blog || page == Portfolio || page == Projects || page == Links || page == Games then
            div [ Attr.class "h-100 w-100 pa2" ]
                [ viewPageContent page model ]

          else
            div [ Attr.class "pa3 h-100 overflow-auto" ]
                [ viewPageContent page model ]
        ]


{-| The game fills nearly the whole window, leaving a thin border so the
page's shader backdrop still frames it. Closed with Esc or the corner button.
-}
viewFullscreenGame : Model -> Html Msg
viewFullscreenGame model =
    div
        [ Attr.class "fixed z-3 overflow-hidden monospace white"
        , Attr.style "left" "2vw"
        , Attr.style "top" "2vh"
        , Attr.style "width" "96vw"
        , Attr.style "height" "96vh"
        ]
        [ viewSelectedGame model
        , button
            [ Attr.class "absolute top-1 right-1 z-4 bg-transparent pa1 ph2 f7 fw6 monospace tracked pointer ttu goop-close-button"
            , onClick CloseGame
            ]
            [ text "✕ BACK" ]
        ]


viewSelectedGame : Model -> Html Msg
viewSelectedGame model =
    case model.selectedGame of
        Just "shooter" ->
            Html.map ShooterGameMsg (Shooter.view model.shooterGame)

        Just "rat-snatcher" ->
            Html.map RatGameMsg (RatSnatcher.view model.ratGame)

        _ ->
            Html.map MissileGameMsg (MissileCommand.view model.missileGame)



-- Message conversion functions for page-specific messages


gamesMsgToMainMsg : Pages.Games.GamesMsg -> Msg
gamesMsgToMainMsg msg =
    case msg of
        Pages.Games.OpenGame id ->
            OpenGame id

        Pages.Games.Close ->
            CloseContent

        Pages.Games.NoOp ->
            Tick 0


blogMsgToMainMsg : Pages.Blog.BlogMsg -> Msg
blogMsgToMainMsg msg =
    case msg of
        Pages.Blog.ToggleFilter tag ->
            ToggleBlogFilter tag

        Pages.Blog.LoadPost slug ->
            LoadBlogPost slug

        Pages.Blog.ClosePost ->
            CloseBlogPost

        Pages.Blog.Close ->
            CloseContent

        Pages.Blog.NoOp ->
            Tick 0


linksMsgToMainMsg : Pages.Links.LinksMsg -> Msg
linksMsgToMainMsg msg =
    case msg of
        Pages.Links.ToggleFilter filter ->
            ToggleLinkFilter filter

        Pages.Links.Close ->
            CloseContent

        _ ->
            Tick 0


portfolioMsgToMainMsg : Pages.Portfolio.PortfolioMsg -> Msg
portfolioMsgToMainMsg msg =
    case msg of
        Pages.Portfolio.SetFilter filter ->
            SetPortfolioFilter filter

        Pages.Portfolio.Close ->
            CloseContent

        _ ->
            Tick 0


projectMsgToMainMsg : Pages.Projects.ProjectMsg -> Msg
projectMsgToMainMsg msg =
    case msg of
        Pages.Projects.ToggleFilter filter ->
            ToggleProjectFilter filter

        Pages.Projects.NoOp ->
            Tick 0

        Pages.Projects.Close ->
            CloseContent

        _ ->
            Tick 0



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
            Html.map projectMsgToMainMsg (Pages.Projects.view model.projectFilters)

        Portfolio ->
            Html.map portfolioMsgToMainMsg (Pages.Portfolio.view model.portfolioFilter)

        About ->
            Html.map (\_ -> CloseContent) Pages.About.view

        Contact ->
            Html.map (\_ -> CloseContent) Pages.Contact.view

        Services ->
            Html.map (\_ -> CloseContent) Pages.Services.view

        Blog ->
            Html.map blogMsgToMainMsg (Pages.Blog.view model.blogFilters model.currentBlogPost model.blogPostLoading model.blogError model.blogPostIndex)

        Links ->
            Html.map linksMsgToMainMsg (Pages.Links.view model.linkFilters model.linkStatuses)

        Games ->
            Html.map gamesMsgToMainMsg Pages.Games.view



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

        Portfolio ->
            "PORTFOLIO"

        About ->
            "ABOUT"

        Contact ->
            "CONTACT"

        Services ->
            "SERVICES"

        Blog ->
            "BLOG"

        Links ->
            "LINKS"

        Games ->
            "GAMES"


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
        , Ports.contentBoundsChanged (\bounds -> ContentBoundsChanged bounds.width bounds.height)

        -- Run the loop for whichever game is actually open
        , if gameOpen model then
            case model.selectedGame of
                Just "shooter" ->
                    Sub.map ShooterGameMsg (Shooter.subscriptions model.shooterGame)

                Just "rat-snatcher" ->
                    Sub.map RatGameMsg (RatSnatcher.subscriptions model.ratGame)

                _ ->
                    Sub.map MissileGameMsg (MissileCommand.subscriptions model.missileGame)

          else
            Sub.none
        ]


keyDecoder : Decode.Decoder Msg
keyDecoder =
    Decode.map toKey (Decode.field "key" Decode.string)


toKey : String -> Msg
toKey key =
    case key of
        "Escape" ->
            EscapePressed

        _ ->
            Tick 0
