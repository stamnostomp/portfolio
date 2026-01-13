-- src/Navigation/GoopNav.elm - Updated to include Portfolio page


module Navigation.GoopNav exposing
    ( GoopNavState
    , NavBranch(..)
    , branchToIndex
    , detectHoveredBranchWithTime
    , getBranchLabel
    , getBranchPage
    , getBranchPositions
    , getFloatingCenter
    , getHoveredBranch
    , initGoopNav
    , updateGoopNav
    )

import Math.Vector2 as Vec2
import Types exposing (Page(..))



-- Navigation branch type


type NavBranch
    = BranchAbout -- 0
    | BranchProjects -- 1
    | BranchPortfolio -- 2
    | BranchBlog -- 3
    | BranchContact -- 4
    | BranchGallery -- 5
    | BranchServices -- 6
    | BranchNews -- 7


-- Convert NavBranch to Page


getBranchPage : NavBranch -> Page
getBranchPage branch =
    case branch of
        BranchAbout ->
            About

        BranchProjects ->
            Projects

        BranchPortfolio ->
            Portfolio

        BranchBlog ->
            Blog

        BranchContact ->
            Contact

        BranchGallery ->
            Gallery

        BranchServices ->
            Services

        BranchNews ->
            Links


-- Convert NavBranch to index


branchToIndex : NavBranch -> Int
branchToIndex branch =
    case branch of
        BranchAbout ->
            0

        BranchProjects ->
            1

        BranchPortfolio ->
            2

        BranchBlog ->
            3

        BranchContact ->
            4

        BranchGallery ->
            5

        BranchServices ->
            6

        BranchNews ->
            7


-- Get branch label string


getBranchLabel : NavBranch -> String
getBranchLabel branch =
    case branch of
        BranchAbout ->
            "About"

        BranchProjects ->
            "Projects"

        BranchPortfolio ->
            "Portfolio"

        BranchBlog ->
            "Blog"

        BranchContact ->
            "Contact"

        BranchGallery ->
            "Gallery"

        BranchServices ->
            "Services"

        BranchNews ->
            "Links"


-- Get the currently hovered branch from state


getHoveredBranch : GoopNavState -> Maybe NavBranch
getHoveredBranch state =
    state.hoveredBranch



-- State for goop navigation


type alias GoopNavState =
    { centerPosition : Vec2.Vec2
    , hoveredBranch : Maybe NavBranch
    , mousePosition : Vec2.Vec2
    , animationTime : Float
    , isActive : Bool
    }



-- Initialize the goop navigation


initGoopNav : Vec2.Vec2 -> GoopNavState
initGoopNav resolution =
    { centerPosition = Vec2.vec2 0.0 0.0 -- Base center position
    , hoveredBranch = Nothing
    , mousePosition = Vec2.vec2 0.0 0.0
    , animationTime = 0.0
    , isActive = True
    }



-- Calculate the very subtle floating center position (matches shader)


getFloatingCenter : Vec2.Vec2 -> Float -> Vec2.Vec2
getFloatingCenter baseCenter time =
    let
        floatX =
            0.008 * sin (time * 0.15) + 0.004 * sin (time * 0.25)

        floatY =
            0.006 * cos (time * 0.18) + 0.005 * cos (time * 0.22)
    in
    Vec2.vec2
        (Vec2.getX baseCenter + floatX)
        (Vec2.getY baseCenter + floatY)



-- Update the goop navigation state - NOW WITH FLOATING CENTER


updateGoopNav : Float -> Float -> Vec2.Vec2 -> GoopNavState -> GoopNavState
updateGoopNav mouseX mouseY resolution state =
    let
        -- Convert mouse position to normalized coordinates (-1 to 1)
        normalizedMouse =
            Vec2.vec2
                ((mouseX / Vec2.getX resolution) * 2.0 - 1.0)
                (1.0 - (mouseY / Vec2.getY resolution) * 2.0)

        -- Adjust for aspect ratio
        aspectRatio =
            Vec2.getX resolution / Vec2.getY resolution

        adjustedMouse =
            Vec2.vec2
                (Vec2.getX normalizedMouse * aspectRatio)
                (Vec2.getY normalizedMouse)

        -- Get the current floating center position
        floatingCenter =
            getFloatingCenter state.centerPosition state.animationTime

        -- Check which branch (if any) is being hovered using FLOATING CENTER
        hoveredBranch =
            detectHoveredBranchWithTime adjustedMouse floatingCenter state.animationTime
    in
    { state
        | mousePosition = adjustedMouse
        , hoveredBranch = hoveredBranch
    }



-- Branch positions relative to floating center


getBranchPositions : Vec2.Vec2 -> Float -> List Vec2.Vec2
getBranchPositions baseCenter time =
    let
        -- Get the floating center position (matching shader calculations)
        floatingCenter =
            getFloatingCenter baseCenter time

        centerX =
            Vec2.getX floatingCenter

        centerY =
            Vec2.getY floatingCenter

        -- Calculate the same slower animation variations as in the shader
        var1 =
            0.025 * sin (time * 0.3 + 0.0)

        var2 =
            0.02 * sin (time * 0.4 + 2.1)

        var3 =
            0.03 * sin (time * 0.25 + 4.2)

        var4 =
            0.018 * sin (time * 0.35 + 6.3)

        var5 =
            0.025 * sin (time * 0.32 + 1.5)

        var6 =
            0.022 * sin (time * 0.38 + 3.6)

        var7 =
            0.028 * sin (time * 0.28 + 5.7)

        var8 =
            0.024 * sin (time * 0.33 + 0.9)
    in
    [ Vec2.vec2 centerX (centerY - 0.25 + var1) -- Top (About)
    , Vec2.vec2 (centerX + 0.18 + var2) (centerY - 0.16 + var2 * 0.4) -- Top Right (Projects)
    , Vec2.vec2 (centerX + 0.28 + var3) centerY -- Right (Portfolio)
    , Vec2.vec2 (centerX + 0.18 + var4) (centerY + 0.25 + var4 * 0.5) -- Bottom Right (Blog)
    , Vec2.vec2 centerX (centerY + 0.28 + var5) -- Bottom (Contact)
    , Vec2.vec2 (centerX - 0.18 - var6) (centerY + 0.25 + var6 * 0.4) -- Bottom Left (Gallery)
    , Vec2.vec2 (centerX - 0.28 - var7) centerY -- Left (Services)
    , Vec2.vec2 (centerX - 0.18 - var8) (centerY - 0.16 + var8 * 0.3) -- Top Left (News)
    ]



-- Detect which branch is being hovered using floating center


detectHoveredBranchWithTime : Vec2.Vec2 -> Vec2.Vec2 -> Float -> Maybe NavBranch
detectHoveredBranchWithTime mousePos floatingCenter time =
    let
        branches =
            [ BranchAbout
            , BranchProjects
            , BranchPortfolio
            , BranchBlog
            , BranchContact
            , BranchGallery
            , BranchServices
            , BranchNews
            ]

        -- Get current animated branch positions using floating center
        branchPositions =
            getBranchPositions (Vec2.vec2 0.0 0.0) time

        -- Base center, floating calculated internally
        -- Reasonable hit area since we're tracking actual positions
        isNearBranch pos =
            Vec2.distance mousePos pos < 0.08

        -- Nice tight detection
        findHoveredBranch positions branchList =
            case ( positions, branchList ) of
                ( pos :: restPos, branch :: restBranch ) ->
                    if isNearBranch pos then
                        Just branch

                    else
                        findHoveredBranch restPos restBranch

                _ ->
                    Nothing
    in
    findHoveredBranch branchPositions branches