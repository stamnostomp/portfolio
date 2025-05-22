-- src/Update.elm - Enhanced with transition logic


module Update exposing (update)

import Math.Vector2 as Vec2
import Model exposing (Model, Msg(..), TransitionState(..))
import Navigation.GoopNav as GoopNav
import Types exposing (Page(..))



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

                -- Handle transition state updates
                updatedTransitionState =
                    updateTransitionState delta model.transitionState model.transitionSpeed
            in
            case updatedTransitionState of
                TransitioningOut progress targetPage ->
                    if progress >= 1.0 then
                        -- Transition completed, switch to showing content
                        ( { model
                            | time = newTime
                            , goopNavState = updatedGoopState
                            , transitionState = ShowingContent targetPage 0.0
                            , currentPage = targetPage
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | time = newTime
                            , goopNavState = updatedGoopState
                            , transitionState = updatedTransitionState
                          }
                        , Cmd.none
                        )

                TransitioningIn progress fromPage ->
                    if progress >= 1.0 then
                        -- Transition back to goop nav completed
                        ( { model
                            | time = newTime
                            , goopNavState = updatedGoopState
                            , transitionState = NoTransition
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | time = newTime
                            , goopNavState = updatedGoopState
                            , transitionState = updatedTransitionState
                          }
                        , Cmd.none
                        )

                ShowingContent page contentTime ->
                    ( { model
                        | time = newTime
                        , goopNavState = updatedGoopState
                        , transitionState = ShowingContent page (contentTime + delta * 0.001)
                      }
                    , Cmd.none
                    )

                NoTransition ->
                    ( { model
                        | time = newTime
                        , goopNavState = updatedGoopState
                        , transitionState = updatedTransitionState
                      }
                    , Cmd.none
                    )

        ChangePage page ->
            -- Direct page changes (from menu, etc.)
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

        -- Goop navigation messages
        ToggleGoopNav ->
            ( { model | showGoopNav = not model.showGoopNav }, Cmd.none )

        ClickBranch branch ->
            let
                targetPage =
                    GoopNav.getBranchPage branch
            in
            -- Start transition instead of immediate page change
            update (StartTransition targetPage) model

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
                    -- Check if we're in content mode and should close
                    case model.transitionState of
                        ShowingContent _ _ ->
                            update CloseContent model

                        _ ->
                            ( model, Cmd.none )

        -- NEW: Transition messages
        StartTransition targetPage ->
            -- Only start transition if we're not already transitioning
            case model.transitionState of
                NoTransition ->
                    ( { model | transitionState = TransitioningOut 0.0 targetPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CompleteTransitionOut ->
            -- This message can be sent manually if needed
            case model.transitionState of
                TransitioningOut _ targetPage ->
                    ( { model
                        | transitionState = ShowingContent targetPage 0.0
                        , currentPage = targetPage
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        CompleteTransitionIn ->
            -- This message can be sent manually if needed
            ( { model | transitionState = NoTransition }, Cmd.none )

        CloseContent ->
            -- Start transition back to goop nav
            case model.transitionState of
                ShowingContent fromPage _ ->
                    ( { model | transitionState = TransitioningIn 0.0 fromPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )



-- Helper function to update transition state


updateTransitionState : Float -> TransitionState -> Float -> TransitionState
updateTransitionState delta transitionState speed =
    let
        progressIncrement =
            delta * 0.001 * speed
    in
    case transitionState of
        TransitioningOut progress targetPage ->
            TransitioningOut (min 1.0 (progress + progressIncrement)) targetPage

        TransitioningIn progress fromPage ->
            TransitioningIn (min 1.0 (progress + progressIncrement)) fromPage

        ShowingContent page contentTime ->
            ShowingContent page contentTime

        NoTransition ->
            NoTransition
