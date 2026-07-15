-- src/Update.elm - Enhanced with organic easing and smoother transitions


module Update exposing (update)

import Math.Vector2 as Vec2
import Model exposing (Model, Msg(..), TransitionState(..), blogPostIndexListDecoder)
import Navigation.GoopNav as GoopNav
import Types exposing (Page(..))
import Http
import BlogContent.OrgParser as OrgParser
import Dict
import Pages.Contact
import Pages.Games.Leaderboard as Leaderboard
import Pages.Games.MissileCommand as MissileCommand
import Pages.Games.RatSnatcher as RatSnatcher
import Pages.Games.Shooter as Shooter
import Pages.Links
import Ports



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

                -- Ease the goop rectangle out to the game panel's border
                -- while a game is open, and back when it closes.
                expandTarget =
                    case ( model.transitionState, model.selectedGame ) of
                        ( ShowingContent Games _, Just id ) ->
                            if List.member id [ "missile-command", "shooter", "rat-snatcher" ] then
                                1

                            else
                                0

                        _ ->
                            0

                newGameExpand =
                    model.gameExpand
                        + (expandTarget - model.gameExpand)
                        * Basics.min 1 (1 - Basics.e ^ (-delta / 150))
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
                            , gameExpand = newGameExpand
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | time = newTime
                            , goopNavState = updatedGoopState
                            , transitionState = updatedTransitionState
                            , gameExpand = newGameExpand
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
                            , gameExpand = newGameExpand
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | time = newTime
                            , goopNavState = updatedGoopState
                            , transitionState = updatedTransitionState
                            , gameExpand = newGameExpand
                          }
                        , Cmd.none
                        )

                ShowingContent page contentTime ->
                    ( { model
                        | time = newTime
                        , goopNavState = updatedGoopState
                        , transitionState = ShowingContent page (contentTime + delta * 0.001)
                        , gameExpand = newGameExpand
                      }
                    , Cmd.none
                    )

                NoTransition ->
                    ( { model
                        | time = newTime
                        , goopNavState = updatedGoopState
                        , transitionState = updatedTransitionState
                        , gameExpand = newGameExpand
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

                -- Calculate content square bounds to check if click is inside
                -- Must match the calculation in Main.elm's calculateContentSquareDimensions
                centerX =
                    Vec2.getX model.resolution / 2

                centerY =
                    Vec2.getY model.resolution / 2

                viewportWidth =
                    Vec2.getX model.resolution

                viewportHeight =
                    Vec2.getY model.resolution

                -- Match shader's rectangle calculation exactly
                -- Rectangle half-height in shader units: 0.76
                squareHeight =
                    viewportHeight * 0.76

                -- Rectangle half-width in shader units: 0.80 * aspectRatio
                squareWidth =
                    viewportWidth * 0.80

                leftPos =
                    centerX - squareWidth / 2

                topPos =
                    centerY - squareHeight / 2

                -- Check if click is inside content square
                isInsideContentSquare =
                    x >= leftPos && x <= (leftPos + squareWidth) &&
                    y >= topPos && y <= (topPos + squareHeight)
            in
            case clickedBranch of
                Just branch ->
                    -- The game owns all clicks; don't let a margin click navigate.
                    case model.transitionState of
                        ShowingContent Games _ ->
                            ( model, Cmd.none )

                        _ ->
                            update (ClickBranch branch) model

                Nothing ->
                    -- Check if we're in content mode and should close
                    case model.transitionState of
                        ShowingContent Games _ ->
                            -- The game owns the whole screen; clicks aim/fire.
                            -- It is closed with Esc or its corner button only.
                            ( model, Cmd.none )

                        ShowingContent _ _ ->
                            -- Only close if click is outside the content square
                            if isInsideContentSquare then
                                ( model, Cmd.none )
                            else
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

                        -- Check link statuses if navigating to Links and not already checking
                        checkLinksCmd =
                            if targetPage == Links && Dict.isEmpty model.linkStatuses then
                                update CheckAllLinkStatuses model
                                    |> Tuple.second
                            else
                                Cmd.none

                        allCmds =
                            Cmd.batch [ loadBlogIndexCmd, checkLinksCmd ]
                    in
                    ( { model | transitionState = TransitioningOut 0.0 targetPage }
                    , allCmds
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
            -- Start transition back to goop nav (and clear any open game)
            case model.transitionState of
                ShowingContent fromPage _ ->
                    ( { model | transitionState = TransitioningIn 0.0 fromPage, selectedGame = Nothing }, Cmd.none )

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

        SetPortfolioFilter filter ->
            ( { model | portfolioFilter = filter }, Cmd.none )

        ToggleProjectFilter filter ->
            let
                isActive =
                    List.any (\f -> f == filter) model.projectFilters

                newFilters =
                    if isActive then
                        List.filter (\f -> f /= filter) model.projectFilters

                    else
                        filter :: model.projectFilters
            in
            ( { model | projectFilters = newFilters }, Cmd.none )

        -- Link status checking messages
        CheckAllLinkStatuses ->
            let
                checkCommands =
                    Pages.Links.allLinks
                        |> List.map (\link ->
                            Http.request
                                { method = "GET"
                                , headers = []
                                , url = Maybe.withDefault link.url link.checkUrl
                                , body = Http.emptyBody

                                -- Result is keyed by link.url, the same key the view uses
                                , expect = Http.expectWhatever (LinkStatusResult link.url)
                                , timeout = Just 5000
                                , tracker = Nothing
                                }
                        )

                -- Mark all as checking initially
                initialStatuses =
                    Pages.Links.allLinks
                        |> List.map (\link -> (link.url, Pages.Links.Checking))
                        |> Dict.fromList
            in
            ( { model | linkStatuses = initialStatuses }
            , Cmd.batch checkCommands
            )

        CheckLinkStatus url ->
            let
                checkCmd =
                    Http.request
                        { method = "GET"
                        , headers = []
                        , url = url
                        , body = Http.emptyBody
                        , expect = Http.expectWhatever (LinkStatusResult url)
                        , timeout = Just 5000
                        , tracker = Nothing
                        }
            in
            ( { model | linkStatuses = Dict.insert url Pages.Links.Checking model.linkStatuses }
            , checkCmd
            )

        LinkStatusResult url result ->
            let
                status =
                    case result of
                        Ok () ->
                            Pages.Links.Online

                        Err (Http.BadStatus code) ->
                            if code >= 200 && code < 300 then
                                Pages.Links.Online
                            else
                                Pages.Links.Offline

                        Err Http.Timeout ->
                            Pages.Links.Offline

                        Err Http.NetworkError ->
                            Pages.Links.CorsError

                        Err _ ->
                            Pages.Links.Offline
            in
            ( { model | linkStatuses = Dict.insert url status model.linkStatuses }
            , Cmd.none
            )

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
                                , blogError = Just "Failed to parse org file"
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

        -- Games
        MissileGameMsg subMsg ->
            let
                ( newGameState, gameCmd ) =
                    MissileCommand.update subMsg model.missileGame
            in
            ( { model | missileGame = newGameState }
            , Cmd.map MissileGameMsg gameCmd
            )
                |> withLeaderboard "missile-command"
                    (MissileCommand.finalScore model.missileGame)
                    (MissileCommand.finalScore newGameState)

        ShooterGameMsg subMsg ->
            let
                ( newGameState, gameCmd ) =
                    Shooter.update subMsg model.shooterGame
            in
            ( { model | shooterGame = newGameState }
            , Cmd.map ShooterGameMsg gameCmd
            )
                |> withLeaderboard "shooter"
                    (Shooter.finalScore model.shooterGame)
                    (Shooter.finalScore newGameState)

        RatGameMsg subMsg ->
            let
                ( newGameState, gameCmd ) =
                    RatSnatcher.update subMsg model.ratGame
            in
            ( { model | ratGame = newGameState }
            , Cmd.map RatGameMsg gameCmd
            )
                |> withLeaderboard "rat-snatcher"
                    (RatSnatcher.finalScore model.ratGame)
                    (RatSnatcher.finalScore newGameState)

        LeaderboardMsg subMsg ->
            let
                ( leaderboard, lbCmd ) =
                    Leaderboard.update subMsg model.leaderboard
            in
            ( { model | leaderboard = leaderboard }
            , Cmd.map LeaderboardMsg lbCmd
            )

        ContactPageMsg subMsg ->
            case subMsg of
                Pages.Contact.Close ->
                    update CloseContent model

                _ ->
                    let
                        ( contactForm, contactCmd ) =
                            Pages.Contact.update subMsg model.contactForm
                    in
                    ( { model | contactForm = contactForm }
                    , Cmd.map ContactPageMsg contactCmd
                    )

        OpenGame id ->
            -- Start the chosen game fresh; ignore ids without a game yet.
            case id of
                "missile-command" ->
                    ( { model | selectedGame = Just id, missileGame = Tuple.first MissileCommand.init, leaderboard = Leaderboard.init }
                    , Cmd.none
                    )

                "shooter" ->
                    ( { model | selectedGame = Just id, shooterGame = Tuple.first Shooter.init, leaderboard = Leaderboard.init }
                    , Cmd.none
                    )

                "rat-snatcher" ->
                    let
                        ( ratGame, ratCmd ) =
                            RatSnatcher.init
                    in
                    ( { model | selectedGame = Just id, ratGame = ratGame, leaderboard = Leaderboard.init }
                    , Cmd.map RatGameMsg ratCmd
                    )

                _ ->
                    ( model, Cmd.none )

        CloseGame ->
            -- Back to the games list (without leaving the Games page)
            ( { model | selectedGame = Nothing, leaderboard = Leaderboard.init }, Cmd.none )

        EscapePressed ->
            -- Esc backs out of an open game to the list, otherwise closes the page.
            case model.selectedGame of
                Just _ ->
                    update CloseGame model

                Nothing ->
                    update CloseContent model



{-| Open the leaderboard overlay when a game's run just ended (its final score
went from Nothing to Just), and dismiss it when a new run starts. Releases the
pointer lock on game over so the player can click and type in the name form.
-}
withLeaderboard : String -> Maybe Int -> Maybe Int -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
withLeaderboard game before after ( model, cmd ) =
    case ( before, after ) of
        ( Nothing, Just score ) ->
            let
                ( leaderboard, lbCmd ) =
                    Leaderboard.start game score
            in
            ( { model | leaderboard = leaderboard }
            , Cmd.batch [ cmd, Cmd.map LeaderboardMsg lbCmd, Ports.exitPointerLock () ]
            )

        ( Just _, Nothing ) ->
            ( { model | leaderboard = Leaderboard.init }, cmd )

        _ ->
            ( model, cmd )



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
