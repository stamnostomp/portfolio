-- src/View/GoopNavigation.elm - Updated to use enhanced shaders


module View.GoopNavigation exposing
    ( fragmentShader
    , vertexShader
    , viewGoopNavigation
    , viewGoopToggle
    , viewHoverLabels
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import Model exposing (Model, Msg(..))
import Navigation.GoopNav as GoopNav
import Shaders.GoopBall
import Shaders.Mesh exposing (fullscreenMesh)
import Shaders.Types exposing (Uniforms)
import WebGL



-- Re-export the enhanced shaders from GoopBall


vertexShader : WebGL.Shader { position : Vec3.Vec3 } Uniforms { vUV : Vec2.Vec2 }
vertexShader =
    Shaders.GoopBall.vertexShader


fragmentShader : WebGL.Shader {} Uniforms { vUV : Vec2.Vec2 }
fragmentShader =
    Shaders.GoopBall.fragmentShader



-- Main goop navigation view (called from Main.elm now)


viewGoopNavigation : Model -> Html Msg
viewGoopNavigation model =
    if not model.showGoopNav then
        text ""

    else
        let
            -- Calculate transition parameters
            ( transitionProgress, transitionType ) =
                case model.transitionState of
                    Model.TransitioningOut progress _ ->
                        ( progress, 1.0 )

                    Model.TransitioningIn progress _ ->
                        ( progress, -1.0 )

                    Model.ShowingContent _ _ ->
                        ( 1.0, 1.0 )

                    Model.NoTransition ->
                        ( 0.0, 0.0 )
        in
        div
            [ class "fixed top-0 left-0 w-100 h-100 pointer-events-none z-2"
            , style "z-index" "2"
            ]
            [ -- WebGL Canvas for the goop effect
              WebGL.toHtml
                [ width (floor (Vec2.getX model.resolution))
                , height (floor (Vec2.getY model.resolution))
                , style "position" "absolute"
                , style "top" "0"
                , style "left" "0"
                , style "pointer-events" "auto"
                , style "cursor" "crosshair"
                , class "goop-navigation-container"
                ]
                [ WebGL.entity
                    vertexShader
                    fragmentShader
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
                viewHoverLabels model

              else
                text ""
            , -- Toggle button for debugging
              viewGoopToggle model
            ]



-- View hover labels that appear over branches


viewHoverLabels : Model -> Html Msg
viewHoverLabels model =
    case model.goopNavState.hoveredBranch of
        Nothing ->
            text ""

        Just branch ->
            let
                -- Calculate label position based on branch using CURRENT TIME
                labelPosition =
                    getBranchLabelPosition branch model.resolution model.goopNavState.centerPosition model.time

                label =
                    GoopNav.getBranchLabel branch
            in
            div
                [ class "fixed pointer-events-none z-3"
                , style "left" (String.fromFloat (Tuple.first labelPosition) ++ "px")
                , style "top" (String.fromFloat (Tuple.second labelPosition) ++ "px")
                , style "transform" "translate(-50%, -50%)"
                , style "z-index" "3"
                ]
                [ div
                    [ class "pa2 br2 f6 glow-hover"
                    , style "background" "linear-gradient(135deg, rgba(0, 20, 40, 0.9), rgba(0, 40, 60, 0.8), rgba(0, 20, 40, 0.9))"
                    , style "border" "1px solid rgba(0, 150, 200, 0.6)"
                    , style "box-shadow" "0 0 12px rgba(0, 150, 200, 0.4), inset 0 0 8px rgba(0, 100, 150, 0.3)"
                    , style "backdrop-filter" "blur(4px)"
                    , style "color" "white !important"
                    , style "text-shadow" "2px 2px 4px rgba(0, 0, 0, 1), -1px -1px 2px rgba(0, 0, 0, 1), 0 0 8px rgba(0, 200, 255, 0.6)"
                    , style "font-weight" "600"
                    ]
                    [ div [ class "f6 fw7", style "color" "white !important" ] [ text label ]
                    , div [ class "f7 o-70 mt1", style "color" "rgba(255, 255, 255, 0.8) !important" ] [ text "◦ CLICK TO EXPAND ◦" ]
                    ]
                ]



-- Calculate screen position for branch labels using DYNAMIC POSITIONS


getBranchLabelPosition : GoopNav.NavBranch -> Vec2.Vec2 -> Vec2.Vec2 -> Float -> ( Float, Float )
getBranchLabelPosition branch resolution center time =
    let
        -- Get branch position in normalized coordinates using current time
        branchPositions =
            GoopNav.getBranchPositions center time

        branchIndex =
            GoopNav.branchToIndex branch

        branchPos =
            branchPositions
                |> List.drop branchIndex
                |> List.head
                |> Maybe.withDefault center

        -- Convert to screen coordinates
        -- Account for aspect ratio adjustment
        aspectRatio =
            Vec2.getX resolution / Vec2.getY resolution

        adjustedX =
            Vec2.getX branchPos / aspectRatio

        screenX =
            (adjustedX + 1.0) * Vec2.getX resolution / 2.0

        screenY =
            (1.0 - Vec2.getY branchPos) * Vec2.getY resolution / 2.0

        -- Add some offset to position labels nicely
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



-- Toggle button for showing/hiding goop navigation


viewGoopToggle : Model -> Html Msg
viewGoopToggle model =
    button
        [ class "fixed top-4 right-4 bg-dark-gray white pa2 br2 pointer z-4 f7"
        , style "border" "1px solid #00ffff"
        , style "z-index" "4"
        , style "pointer-events" "auto"
        , onClick ToggleGoopNav
        ]
        [ text
            (if model.showGoopNav then
                "HIDE GOOP"

             else
                "SHOW GOOP"
            )
        ]
