module Model exposing
    ( Model
    , Msg(..)
    , Page(..)
    , init
    )

import Browser
import GitHub
import Http
import Math.Vector2 as Vec2

-- MODEL

type alias Model =
    { time : Float
    , currentPage : Page
    , menuOpen : Bool
    , loadingProgress : Float
    , isLoading : Bool
    , mouseX : Float
    , mouseY : Float
    , gitHubCommits : List GitHub.Commit
    , gitHubError : Maybe String
    , gitHubLoading : Bool
    , resolution : Vec2.Vec2
    , mousePosition : Vec2.Vec2
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
    | GotGitHubCommits (Result Http.Error (List GitHub.Commit))
    | WindowResize Int Int


-- INIT

init : { width : Int, height : Int } -> ( Model, Cmd Msg )
init flags =
    ( { time = 0
      , currentPage = Home
      , menuOpen = False
      , loadingProgress = 0
      , isLoading = True
      , mouseX = 0
      , mouseY = 0
      , gitHubCommits = []
      , gitHubError = Nothing
      , gitHubLoading = True
      , resolution = Vec2.vec2 (toFloat flags.width) (toFloat flags.height)
      , mousePosition = Vec2.vec2 0 0
      }
    , GitHub.fetchCommits GotGitHubCommits
    )
