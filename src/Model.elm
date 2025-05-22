-- src/Model.elm - Enhanced with transition state


module Model exposing
    ( Model
    , Msg(..)
    , TransitionState(..)
    , init
    )

import Browser
import Math.Vector2 as Vec2
import Navigation.GoopNav as GoopNav
import Types exposing (Page(..))



-- TRANSITION STATE


type TransitionState
    = NoTransition
    | TransitioningOut Float Page -- Progress (0.0 to 1.0) and target page
    | ShowingContent Page Float -- Page and how long it's been shown
    | TransitioningIn Float Page -- Progress (0.0 to 1.0) from content back to goop



-- MODEL


type alias Model =
    { time : Float
    , currentPage : Page
    , menuOpen : Bool
    , loadingProgress : Float
    , isLoading : Bool
    , mouseX : Float
    , mouseY : Float
    , resolution : Vec2.Vec2
    , mousePosition : Vec2.Vec2

    -- Goop navigation state
    , goopNavState : GoopNav.GoopNavState
    , showGoopNav : Bool

    -- NEW: Transition state
    , transitionState : TransitionState
    , transitionSpeed : Float -- How fast transitions happen
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
      -- NEW: Transition messages
    | StartTransition Page
    | CompleteTransitionOut
    | CompleteTransitionIn
    | CloseContent



-- INIT


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
      , mousePosition = Vec2.vec2 (toFloat flags.width / 2) (toFloat flags.height / 2)

      -- Initialize goop navigation
      , goopNavState = GoopNav.initGoopNav resolution
      , showGoopNav = True -- Show goop nav by default

      -- NEW: Initialize transition state
      , transitionState = NoTransition
      , transitionSpeed = 1.5 -- Transitions take ~0.67 seconds
      }
    , Cmd.none
    )
