-- Simplified src/Update.elm (no HTTP dependencies)


module Update exposing (update)

import Math.Vector2 as Vec2
import Model exposing (Model, Msg(..))
import Navigation.GoopNav as GoopNav



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick delta ->
            let
                newTime =
                    model.time + delta * 0.001

                -- Update goop navigation animation time
                updatedGoopState =
                    let
                        goopState =
                            model.goopNavState
                    in
                    { goopState | animationTime = newTime }
            in
            ( { model
                | time = newTime
                , goopNavState = updatedGoopState
              }
            , Cmd.none
            )

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
            , Cmd.none
            )

        FinishLoading ->
            ( { model | isLoading = False }, Cmd.none )

        MouseMove x y ->
            let
                -- Update goop navigation with new mouse position
                updatedGoopState =
                    GoopNav.updateGoopNav x y model.resolution model.goopNavState
            in
            ( { model
                | mouseX = x
                , mouseY = y
                , mousePosition = Vec2.vec2 x y
                , goopNavState = updatedGoopState
              }
            , Cmd.none
            )

        WindowResize width height ->
            let
                newResolution =
                    Vec2.vec2 (toFloat width) (toFloat height)

                -- Update goop navigation for new screen size
                updatedGoopState =
                    GoopNav.updateGoopNav model.mouseX model.mouseY newResolution model.goopNavState
            in
            ( { model
                | resolution = newResolution
                , goopNavState = updatedGoopState
              }
            , Cmd.none
            )

        -- New goop navigation messages
        ToggleGoopNav ->
            ( { model | showGoopNav = not model.showGoopNav }, Cmd.none )

        ClickBranch branch ->
            let
                targetPage =
                    GoopNav.getBranchPage branch
            in
            ( { model | currentPage = targetPage }, Cmd.none )

        MouseClick x y ->
            let
                -- Convert mouse position for hit testing
                normalizedMouse =
                    Vec2.vec2
                        ((x / Vec2.getX model.resolution) * 2.0 - 1.0)
                        (1.0 - (y / Vec2.getY model.resolution) * 2.0)

                aspectRatio =
                    Vec2.getX model.resolution / Vec2.getY model.resolution

                adjustedMouse =
                    Vec2.vec2
                        (Vec2.getX normalizedMouse * aspectRatio)
                        (Vec2.getY normalizedMouse)

                -- Check if any branch was clicked
                clickedBranch =
                    GoopNav.detectHoveredBranch adjustedMouse model.goopNavState.centerPosition
            in
            case clickedBranch of
                Just branch ->
                    update (ClickBranch branch) model

                Nothing ->
                    ( model, Cmd.none )
