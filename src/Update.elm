module Update exposing (update, errorToString)

import Http
import Math.Vector2 as Vec2
import Model exposing (Model, Msg(..))

-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick delta ->
            ( { model | time = model.time + delta * 0.001 }, Cmd.none )

        ChangePage page ->
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
            , if isComplete then
                Cmd.none
              else
                Cmd.none
            )

        FinishLoading ->
            ( { model | isLoading = False }, Cmd.none )

        MouseMove x y ->
            ( { model
                | mouseX = x
                , mouseY = y
                , mousePosition = Vec2.vec2 x y
              }
            , Cmd.none
            )

        GotGitHubCommits result ->
            case result of
                Ok commits ->
                    ( { model | gitHubCommits = commits, gitHubLoading = False, gitHubError = Nothing }, Cmd.none )

                Err httpError ->
                    ( { model | gitHubError = Just (errorToString httpError), gitHubLoading = False }, Cmd.none )

        WindowResize width height ->
            ( { model | resolution = Vec2.vec2 (toFloat width) (toFloat height) }, Cmd.none )


errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadUrl url ->
            "Bad URL: " ++ url

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus code ->
            "Bad status: " ++ String.fromInt code

        Http.BadBody message ->
            "Bad body: " ++ message
