-- src/Model.elm - Enhanced with organic transition settings


module Model exposing
    ( Model
    , Msg(..)
    , TransitionState(..)
    , init
    )

import Browser
import Math.Vector2 as Vec2
import Navigation.GoopNav as GoopNav
import Types exposing (Page(..), BlogTag, LinkFilter)
import BlogContent.Types exposing (BlogPost)
import Http



-- ENHANCED TRANSITION STATE


type TransitionState
    = NoTransition
    | TransitioningOut Float Page -- Progress (0.0 to 1.0) and target page
    | ShowingContent Page Float -- Page and how long it's been shown
    | TransitioningIn Float Page -- Progress (0.0 to 1.0) from content back to goop



-- ENHANCED MODEL WITH ORGANIC SETTINGS


type alias Model =
    { time : Float
    , currentPage : Page
    , menuOpen : Bool
    , loadingProgress : Float
    , isLoading : Bool
    , mouseX : Float
    , mouseY : Float
    , resolution : Vec2.Vec2
    , contentBounds : Vec2.Vec2 -- Actual content dimensions
    , mousePosition : Vec2.Vec2

    -- Goop navigation state
    , goopNavState : GoopNav.GoopNavState
    , showGoopNav : Bool

    -- Enhanced transition state
    , transitionState : TransitionState
    , transitionSpeed : Float -- How fast transitions happen
    , transitionEasing : String -- Type of easing to use
    , organicVariation : Float -- Amount of organic variation in transitions

    -- Filter state
    , blogFilters : List BlogTag
    , linkFilters : List LinkFilter

    -- Blog post loading state
    , currentBlogPost : Maybe BlogPost
    , blogPostLoading : Bool
    , selectedBlogSlug : Maybe String
    , blogError : Maybe String
    }



-- MSG


type Msg
    = Tick Float
    | ChangePage Page
    | ToggleMenu
    | IncrementLoading Float
    | FinishLoading
    | MouseMove Float Float
    | WindowResize Int Int
      -- Goop navigation messages
    | ToggleGoopNav
    | ClickBranch GoopNav.NavBranch
    | MouseClick Float Float
      -- Enhanced transition messages
    | StartTransition Page
    | CompleteTransitionOut
    | CompleteTransitionIn
    | CloseContent
      -- New organic transition controls
    | SetTransitionSpeed Float
    | SetOrganicVariation Float
      -- Content bounds detection
    | ContentBoundsChanged Int Int
      -- Filter messages
    | ToggleBlogFilter BlogTag
    | ToggleLinkFilter LinkFilter
      -- Blog post loading messages
    | LoadBlogPost String
    | BlogPostLoaded (Result Http.Error String)
    | CloseBlogPost



-- ENHANCED INIT WITH ORGANIC SETTINGS


init : { width : Int, height : Int } -> ( Model, Cmd Msg )
init flags =
    let
        resolution =
            Vec2.vec2 (toFloat flags.width) (toFloat flags.height)
    in
    ( { time = 0
      , currentPage = Home
      , menuOpen = False
      , loadingProgress = 100 -- Start loaded for immediate goop nav
      , isLoading = False -- Start with loading complete
      , mouseX = toFloat flags.width / 2 -- Center mouse initially
      , mouseY = toFloat flags.height / 2
      , resolution = resolution
      , contentBounds = resolution -- Start with window size, will be updated dynamically
      , mousePosition = Vec2.vec2 (toFloat flags.width / 2) (toFloat flags.height / 2)

      -- Initialize goop navigation
      , goopNavState = GoopNav.initGoopNav resolution
      , showGoopNav = True -- Show goop nav by default

      -- Enhanced organic transition settings
      , transitionState = NoTransition
      , transitionSpeed = 0.8 -- Slower, more organic transitions (~1.25 seconds)
      , transitionEasing = "organic" -- Use organic easing
      , organicVariation = 0.15 -- 15% organic variation in timing

      -- Initialize filters (empty = show all)
      , blogFilters = []
      , linkFilters = []

      -- Initialize blog post state
      , currentBlogPost = Nothing
      , blogPostLoading = False
      , selectedBlogSlug = Nothing
      , blogError = Nothing
      }
    , Cmd.none
    )
