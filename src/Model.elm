-- src/Model.elm - Fixed version with Page from Types module


module Model exposing
    ( Model
    , Msg(..)
    , init
    )

import Browser
import Math.Vector2 as Vec2
import Navigation.GoopNav as GoopNav
import Types exposing (Page(..))



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
      }
    , Cmd.none
    )
