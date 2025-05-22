-- src/Navigation/GoopNav.elm - Fixed version importing Page from Types


module Navigation.GoopNav exposing
    ( GoopNavState
    , NavBranch(..)
    , branchToIndex
    , detectHoveredBranch
    , getBranchLabel
    , getBranchPage
    , getBranchPositions
    , getHoveredBranch
    , initGoopNav
    , isPointInBranch
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
    { centerPosition = Vec2.vec2 0.0 0.0 -- Center of screen in normalized coords
    , hoveredBranch = Nothing
    , mousePosition = Vec2.vec2 0.0 0.0
    , animationTime = 0.0
    , isActive = True
    }



-- Update the goop navigation state


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

        -- Check which branch (if any) is being hovered
        hoveredBranch =
            detectHoveredBranch adjustedMouse state.centerPosition
    in
    { state
        | mousePosition = adjustedMouse
        , hoveredBranch = hoveredBranch
    }



-- Branch positions relative to center (same as in shader)


getBranchPositions : Vec2.Vec2 -> List Vec2.Vec2
getBranchPositions center =
    let
        centerX =
            Vec2.getX center

        centerY =
            Vec2.getY center
    in
    [ Vec2.vec2 centerX (centerY - 0.15) -- Top (About)
    , Vec2.vec2 (centerX + 0.12) (centerY - 0.1) -- Top Right (Projects)
    , Vec2.vec2 (centerX + 0.18) centerY -- Right (Portfolio)
    , Vec2.vec2 (centerX + 0.12) (centerY + 0.15) -- Bottom Right (Blog)
    , Vec2.vec2 centerX (centerY + 0.18) -- Bottom (Contact)
    , Vec2.vec2 (centerX - 0.12) (centerY + 0.15) -- Bottom Left (Gallery)
    , Vec2.vec2 (centerX - 0.18) centerY -- Left (Services)
    , Vec2.vec2 (centerX - 0.12) (centerY - 0.1) -- Top Left (News)
    ]



-- Detect which branch is being hovered


detectHoveredBranch : Vec2.Vec2 -> Vec2.Vec2 -> Maybe NavBranch
detectHoveredBranch mousePos center =
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

        branchPositions =
            getBranchPositions center

        -- Check if mouse is within hover distance of any branch
        isNearBranch pos =
            Vec2.distance mousePos pos < 0.06

        -- Slightly larger hit area
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



-- Check if a point is within a branch's hit area


isPointInBranch : Vec2.Vec2 -> NavBranch -> Vec2.Vec2 -> Bool
isPointInBranch point branch center =
    let
        branchPositions =
            getBranchPositions center

        branchIndex =
            branchToIndex branch

        branchPos =
            branchPositions
                |> List.drop branchIndex
                |> List.head
                |> Maybe.withDefault center
    in
    Vec2.distance point branchPos < 0.06



-- Get the hovered branch as a float for the shader


getHoveredBranch : GoopNavState -> Float
getHoveredBranch state =
    case state.hoveredBranch of
        Nothing ->
            -1.0

        Just branch ->
            toFloat (branchToIndex branch)



-- Convert branch to index


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



-- Get the page associated with a branch


getBranchPage : NavBranch -> Page
getBranchPage branch =
    case branch of
        BranchAbout ->
            About

        BranchProjects ->
            Projects

        BranchPortfolio ->
            Projects

        BranchBlog ->
            Home

        BranchContact ->
            Contact

        BranchGallery ->
            Projects

        BranchServices ->
            About

        BranchNews ->
            Home



-- Get branch label for UI


getBranchLabel : NavBranch -> String
getBranchLabel branch =
    case branch of
        BranchAbout ->
            "ABOUT"

        BranchProjects ->
            "PROJECTS"

        BranchPortfolio ->
            "PORTFOLIO"

        BranchBlog ->
            "BLOG"

        BranchContact ->
            "CONTACT"

        BranchGallery ->
            "GALLERY"

        BranchServices ->
            "SERVICES"

        BranchNews ->
            "NEWS"
