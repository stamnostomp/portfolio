-- Simplified src/Model.elm (no HTTP dependencies)


module Model exposing
    ( Model
    , Msg(..)
    , Page(..)
    , init
    )

import Browser
import Math.Vector2 as Vec2
import Navigation.GoopNav as GoopNav



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

    -- Add goop navigation state
    , goopNavState : GoopNav.GoopNavState
    , showGoopNav : Bool
    }


type Page
    = Home
    | Projects
    | About
    | Contact



-- MSG


type Msg
    = Tick Float
    | ChangePage Page
    | ToggleMenu
    | IncrementLoading Float
    | FinishLoading
    | MouseMove Float Float
    | WindowResize Int Int
      -- Add goop navigation messages
    | ToggleGoopNav
    | ClickBranch GoopNav.NavBranch
    | MouseClick Float Float



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
      , loadingProgress = 0
      , isLoading = True
      , mouseX = 0
      , mouseY = 0
      , resolution = resolution
      , mousePosition = Vec2.vec2 0 0

      -- Initialize goop navigation
      , goopNavState = GoopNav.initGoopNav resolution
      , showGoopNav = True -- Show by default, can be toggled
      }
    , Cmd.none
      -- No HTTP commands needed
    )
