-- src/View/GoopNavigation.elm - Fixed version


module View.GoopNavigation exposing (viewGoopNavigation, viewHoverLabels)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Math.Vector2 as Vec2
import Model exposing (Model, Msg(..))
import Navigation.GoopNav as GoopNav
import Shaders.GoopBall as GoopBall
import Shaders.Mesh exposing (fullscreenMesh)
import WebGL



-- Main goop navigation view


viewGoopNavigation : Model -> Html Msg
viewGoopNavigation model =
    if not model.showGoopNav then
        text ""

    else
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

                -- Handle clicks through the message system
                ]
                [ WebGL.entity
                    GoopBall.vertexShader
                    GoopBall.fragmentShader
                    fullscreenMesh
                    { time = model.time
                    , resolution = model.resolution
                    , mousePosition = model.mousePosition
                    , hoveredBranch = GoopNav.getHoveredBranch model.goopNavState
                    , centerPosition = model.goopNavState.centerPosition
                    }
                ]
            , -- Overlay for hover labels
              viewHoverLabels model
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
                -- Calculate label position based on branch
                labelPosition =
                    getBranchLabelPosition branch model.resolution model.goopNavState.centerPosition

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
                    [ class "bg-dark-gray near-white pa2 br2 f6 glow-hover cyber-label"
                    , style "border" "1px solid #00ffff"
                    , style "box-shadow" "0 0 10px rgba(0, 255, 255, 0.5)"
                    , style "backdrop-filter" "blur(2px)"
                    ]
                    [ div [ class "f6 fw7" ] [ text label ]
                    , div [ class "f7 o-70 mt1" ] [ text "◦ CLICK TO NAVIGATE ◦" ]
                    ]
                ]



-- Calculate screen position for branch labels


getBranchLabelPosition : GoopNav.NavBranch -> Vec2.Vec2 -> Vec2.Vec2 -> ( Float, Float )
getBranchLabelPosition branch resolution center =
    let
        -- Get branch position in normalized coordinates
        branchPositions =
            GoopNav.getBranchPositions center

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
