-- src/Update.elm - Enhanced with organic easing and smoother transitions


module Update exposing (update)

import Math.Vector2 as Vec2
import Model exposing (Model, Msg(..), TransitionState(..), blogPostIndexListDecoder)
import Navigation.GoopNav as GoopNav
import Types exposing (Page(..))
import Http
import BlogContent.OrgParser as OrgParser



-- ORGANIC EASING FUNCTIONS
-- Organic ease-in-out with natural variation


organicEaseInOut : Float -> Float -> Float -> Float
organicEaseInOut t variation time =
    let
        -- Base smooth step
        baseEase =
            t * t * (3.0 - 2.0 * t)

        -- Add organic variation based on time
        organicWave =
            sin (time * 0.5 + t * 6.28) * variation * (1.0 - t) * t * 4.0

        -- Combine and clamp
        result =
            baseEase + organicWave
    in
    Basics.max 0.0 (Basics.min 1.0 result)



-- Elastic ease out with organic feel


organicElasticOut : Float -> Float -> Float
organicElasticOut t variation =
    if t <= 0.0 then
        0.0

    else if t >= 1.0 then
        1.0

    else
        let
            -- Elastic parameters
            p =
                0.3

            s =
                p / 4.0

            -- Base elastic calculation
            baseElastic =
                (2.0 ^ (-10.0 * t)) * sin ((t - s) * (2.0 * pi) / p) + 1.0

            -- Add organic smoothing
            organicSmoothing =
                1.0 - ((1.0 - t) ^ 3.0) * variation
        in
        baseElastic * organicSmoothing



-- Bounce ease out with organic damping


organicBounceOut : Float -> Float -> Float
organicBounceOut t variation =
    let
        dampening =
            1.0 - variation * 0.3
    in
    if t < (1.0 / 2.75) then
        (7.5625 * t * t) * dampening

    else if t < (2.0 / 2.75) then
        let
            adjusted =
                t - (1.5 / 2.75)
        in
        (7.5625 * adjusted * adjusted + 0.75) * dampening

    else if t < (2.5 / 2.75) then
        let
            adjusted =
                t - (2.25 / 2.75)
        in
        (7.5625 * adjusted * adjusted + 0.9375) * dampening

    else
        let
            adjusted =
                t - (2.625 / 2.75)
        in
        (7.5625 * adjusted * adjusted + 0.984375) * dampening



-- Main organic easing function


applyOrganicEasing : Float -> Float -> Float -> String -> Float
applyOrganicEasing progress variation time easingType =
    case easingType of
        "organic" ->
            organicEaseInOut progress variation time

        "elastic" ->
            organicElasticOut progress variation

        "bounce" ->
            organicBounceOut progress variation

        _ ->
            -- Default smooth step
            progress * progress * (3.0 - 2.0 * progress)



-- ENHANCED UPDATE FUNCTION


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

                -- Handle transition state updates with organic easing
                updatedTransitionState =
                    updateTransitionStateOrganic delta model.transitionState model.transitionSpeed model.organicVariation newTime
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

                -- Check if any branch was clicked using floating center and time
                clickedBranch =
                    GoopNav.detectHoveredBranchWithTime adjustedMouse model.goopNavState.centerPosition model.time
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

        -- Enhanced transition messages
        StartTransition targetPage ->
            -- Only start transition if we're not already transitioning
            case model.transitionState of
                NoTransition ->
                    let
                        -- Load blog index if navigating to blog and not loaded yet
                        loadBlogIndexCmd =
                            if targetPage == Blog && List.isEmpty model.blogPostIndex && not model.blogIndexLoading then
                                Http.get
                                    { url = "/blog/posts.json"
                                    , expect = Http.expectJson BlogIndexLoaded blogPostIndexListDecoder
                                    }
                            else
                                Cmd.none
                    in
                    ( { model | transitionState = TransitioningOut 0.0 targetPage }
                    , loadBlogIndexCmd
                    )

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

        -- New organic transition controls
        SetTransitionSpeed speed ->
            ( { model | transitionSpeed = Basics.max 0.1 (Basics.min 3.0 speed) }, Cmd.none )

        SetOrganicVariation variation ->
            ( { model | organicVariation = Basics.max 0.0 (Basics.min 0.5 variation) }, Cmd.none )

        ContentBoundsChanged width height ->
            let
                newContentBounds =
                    Vec2.vec2 (toFloat width) (toFloat height)
            in
            ( { model | contentBounds = newContentBounds }, Cmd.none )

        -- Filter toggle messages
        ToggleBlogFilter tag ->
            let
                isActive =
                    List.any (\t -> t == tag) model.blogFilters

                newFilters =
                    if isActive then
                        List.filter (\t -> t /= tag) model.blogFilters

                    else
                        tag :: model.blogFilters
            in
            ( { model | blogFilters = newFilters }, Cmd.none )

        ToggleLinkFilter filter ->
            let
                isActive =
                    List.any (\f -> f == filter) model.linkFilters

                newFilters =
                    if isActive then
                        List.filter (\f -> f /= filter) model.linkFilters

                    else
                        filter :: model.linkFilters
            in
            ( { model | linkFilters = newFilters }, Cmd.none )

        -- Blog post loading messages
        LoadBlogPost slug ->
            ( { model
                | blogPostLoading = True
                , selectedBlogSlug = Just slug
                , blogError = Nothing
              }
            , Http.get
                { url = "/blog/posts/" ++ slug ++ ".org"
                , expect = Http.expectString BlogPostLoaded
                }
            )

        BlogPostLoaded result ->
            case result of
                Ok orgContent ->
                    case OrgParser.parseBlogPost orgContent of
                        Ok blogPost ->
                            ( { model
                                | currentBlogPost = Just blogPost
                                , blogPostLoading = False
                                , blogError = Nothing
                              }
                            , Cmd.none
                            )

                        Err parseError ->
                            -- Failed to parse the org file
                            ( { model
                                | blogPostLoading = False
                                , currentBlogPost = Nothing
                                , blogError = Just ("Failed to parse org file: " ++ Debug.toString parseError)
                              }
                            , Cmd.none
                            )

                Err httpError ->
                    -- Failed to load the org file
                    let
                        errorMessage =
                            case httpError of
                                Http.BadUrl url ->
                                    "Bad URL: " ++ url

                                Http.Timeout ->
                                    "Request timed out"

                                Http.NetworkError ->
                                    "Network error"

                                Http.BadStatus status ->
                                    "HTTP error " ++ String.fromInt status

                                Http.BadBody body ->
                                    "Bad response body: " ++ body
                    in
                    ( { model
                        | blogPostLoading = False
                        , currentBlogPost = Nothing
                        , blogError = Just errorMessage
                      }
                    , Cmd.none
                    )

        CloseBlogPost ->
            ( { model
                | currentBlogPost = Nothing
                , selectedBlogSlug = Nothing
                , blogError = Nothing
              }
            , Cmd.none
            )

        -- Blog index loading messages
        LoadBlogIndex ->
            ( { model | blogIndexLoading = True }
            , Http.get
                { url = "/blog/posts.json"
                , expect = Http.expectJson BlogIndexLoaded blogPostIndexListDecoder
                }
            )

        BlogIndexLoaded result ->
            case result of
                Ok posts ->
                    ( { model
                        | blogPostIndex = posts
                        , blogIndexLoading = False
                      }
                    , Cmd.none
                    )

                Err httpError ->
                    -- Failed to load blog index, keep empty list
                    ( { model | blogIndexLoading = False }
                    , Cmd.none
                    )



-- Enhanced helper function to update transition state with organic easing


updateTransitionStateOrganic : Float -> TransitionState -> Float -> Float -> Float -> TransitionState
updateTransitionStateOrganic delta transitionState speed organicVariation time =
    let
        -- Base progress increment
        baseProgressIncrement =
            delta * 0.001 * speed

        -- Add organic timing variation
        organicTimingVariation =
            sin (time * 0.3) * organicVariation * baseProgressIncrement

        -- Final progress increment with organic variation
        progressIncrement =
            baseProgressIncrement + organicTimingVariation
    in
    case transitionState of
        TransitioningOut progress targetPage ->
            let
                newProgress =
                    Basics.min 1.0 (progress + progressIncrement)

                -- Apply organic easing to the progress
                easedProgress =
                    applyOrganicEasing newProgress organicVariation time "organic"
            in
            TransitioningOut newProgress targetPage

        TransitioningIn progress fromPage ->
            let
                newProgress =
                    Basics.min 1.0 (progress + progressIncrement)

                -- Apply organic easing to the progress
                easedProgress =
                    applyOrganicEasing newProgress organicVariation time "organic"
            in
            TransitioningIn newProgress fromPage

        ShowingContent page contentTime ->
            ShowingContent page contentTime

        NoTransition ->
            NoTransition



-- Helper function to get eased progress for use in shaders


getEasedTransitionProgress : TransitionState -> Float -> Float -> String -> Float
getEasedTransitionProgress transitionState organicVariation time easingType =
    case transitionState of
        TransitioningOut progress _ ->
            applyOrganicEasing progress organicVariation time easingType

        TransitioningIn progress _ ->
            applyOrganicEasing progress organicVariation time easingType

        ShowingContent _ _ ->
            1.0

        NoTransition ->
            0.0
