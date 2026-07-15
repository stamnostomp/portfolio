module Pages.Games.Leaderboard exposing (Entry, Model, Msg, Theme, init, start, update, view)

{-| Shared game-over screen with leaderboard: fetches the top scores for a
game, asks the player for a name, and submits their score to the backend.

This is the whole end-of-run screen — the games no longer draw their own.
The `Theme` carries each game's title, accent color, and stats line.

The backend is the small Elixir service proxied at /api (see backend/).

-}

import Html exposing (Html, button, div, form, input, text)
import Html.Attributes as Attr
import Html.Events
import Http
import Json.Decode as Decode
import Json.Encode as Encode


type alias Entry =
    { name : String, score : Int }


type Model
    = Inactive
    | Active State


type alias State =
    { game : String
    , score : Int
    , name : String
    , board : Maybe (List Entry) -- Nothing until the first fetch resolves
    , phase : Phase
    }


type Phase
    = Entering
    | Submitting
    | Saved
    | Failed


type Msg
    = GotBoard (Result Http.Error (List Entry))
    | NameChanged String
    | Submit
    | Submitted (Result Http.Error (List Entry))
    | NoOp


init : Model
init =
    Inactive


{-| Open the overlay for a finished run and fetch the current top scores. -}
start : String -> Int -> ( Model, Cmd Msg )
start game score =
    ( Active { game = game, score = score, name = "", board = Nothing, phase = Entering }
    , Http.get { url = boardUrl game, expect = Http.expectJson GotBoard boardDecoder }
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Inactive ->
            ( model, Cmd.none )

        Active state ->
            case msg of
                GotBoard (Ok entries) ->
                    ( Active { state | board = Just entries }, Cmd.none )

                GotBoard (Err _) ->
                    -- Show the board as empty; submitting may still work.
                    ( Active { state | board = Just [] }, Cmd.none )

                NameChanged name ->
                    ( Active { state | name = String.left 16 name }, Cmd.none )

                Submit ->
                    if canSubmit state then
                        ( Active { state | phase = Submitting }
                        , Http.post
                            { url = boardUrl state.game
                            , body =
                                Http.jsonBody
                                    (Encode.object
                                        [ ( "name", Encode.string (String.trim state.name) )
                                        , ( "score", Encode.int state.score )
                                        ]
                                    )
                            , expect = Http.expectJson Submitted boardDecoder
                            }
                        )

                    else
                        ( model, Cmd.none )

                Submitted (Ok entries) ->
                    ( Active { state | board = Just entries, phase = Saved }, Cmd.none )

                Submitted (Err _) ->
                    ( Active { state | phase = Failed }, Cmd.none )

                NoOp ->
                    ( model, Cmd.none )


canSubmit : State -> Bool
canSubmit state =
    (state.phase == Entering || state.phase == Failed)
        && not (String.isEmpty (String.trim state.name))


boardUrl : String -> String
boardUrl game =
    "/api/leaderboard/" ++ game


boardDecoder : Decode.Decoder (List Entry)
boardDecoder =
    Decode.list
        (Decode.map2 Entry
            (Decode.field "name" Decode.string)
            (Decode.field "score" Decode.int)
        )



-- VIEW


{-| Per-game dressing for the shared game-over screen. -}
type alias Theme =
    { title : String
    , accent : String -- CSS color of the big title
    , glow : String -- CSS color of the title's glow
    , stats : Maybe String -- run summary line ("SCORE 900", "TIME 12s · ...")
    }


view : Theme -> Model -> Html Msg
view theme model =
    case model of
        Inactive ->
            text ""

        Active state ->
            div
                [ Attr.class "absolute absolute--fill flex flex-column items-center justify-center monospace tracked tc z-4"
                , Attr.style "background" "rgba(0,0,0,0.7)"

                -- Let clicks fall through to the game underneath (click to
                -- restart); only the high-scores card below is interactive.
                , Attr.style "pointer-events" "none"
                ]
                [ div
                    [ Attr.class "f1 fw6"
                    , Attr.style "color" theme.accent
                    , Attr.style "text-shadow" ("0 0 18px " ++ theme.glow)
                    ]
                    [ text theme.title ]
                , case theme.stats of
                    Just line ->
                        div
                            [ Attr.class "f4 mt3"
                            , Attr.style "color" "rgba(220,220,220,0.9)"
                            ]
                            [ text line ]

                    Nothing ->
                        text ""
                , viewCard state
                , div
                    [ Attr.class "f6 mt4 blink"
                    , Attr.style "color" "rgba(180,180,180,0.8)"
                    ]
                    [ text "CLICK TO RESTART" ]
                ]


viewCard : State -> Html Msg
viewCard state =
    div
        [ Attr.class "mt4 pa3"
        , Attr.style "width" "300px"
        , Attr.style "background" "rgba(0,0,0,0.85)"
        , Attr.style "border" "1px solid rgba(192,192,192,0.4)"
        , Attr.style "box-shadow" "0 0 24px rgba(0,0,0,0.7)"

        -- The interactive island in the click-through screen: keep its
        -- clicks away from the game container so typing doesn't restart.
        , Attr.style "pointer-events" "auto"
        , Html.Events.stopPropagationOn "mousedown" (Decode.succeed ( NoOp, True ))
        , Html.Events.stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
        ]
        [ div
            [ Attr.class "f6 fw6 tracked"
            , Attr.style "color" "rgba(228,228,228,0.95)"
            , Attr.style "text-shadow" "0 0 10px rgba(192,192,192,0.4)"
            ]
            [ text "HIGH SCORES" ]
        , viewSubmitRow state
        , viewBoard state
        ]


viewSubmitRow : State -> Html Msg
viewSubmitRow state =
    case state.phase of
        Submitting ->
            statusLine "SAVING..."

        Saved ->
            statusLine "SAVED"

        _ ->
            form
                [ Html.Events.onSubmit Submit
                , Attr.class "mt3 flex justify-center"
                , Attr.style "gap" "0.5rem"
                ]
                [ input
                    [ Attr.type_ "text"
                    , Attr.value state.name
                    , Attr.placeholder "YOUR NAME"
                    , Attr.maxlength 16
                    , Attr.autofocus True
                    , Attr.spellcheck False
                    , Attr.class "monospace tracked pa1 ph2 f6"
                    , Attr.style "width" "10rem"
                    , Attr.style "background" "rgba(0,0,0,0.6)"
                    , Attr.style "border" "1px solid rgba(192,192,192,0.4)"
                    , Attr.style "color" "rgba(228,228,228,0.95)"
                    , Attr.style "outline" "none"
                    , Html.Events.onInput NameChanged
                    ]
                    []
                , button
                    [ Attr.type_ "submit"
                    , Attr.class "monospace tracked pa1 ph2 f6 fw6 pointer ttu"
                    , Attr.style "background" "rgba(192,192,192,0.15)"
                    , Attr.style "border" "1px solid rgba(192,192,192,0.4)"
                    , Attr.style "color" "rgba(228,228,228,0.95)"
                    ]
                    [ text "SAVE" ]
                , if state.phase == Failed then
                    div
                        [ Attr.class "f7 mt1 w-100"
                        , Attr.style "color" "rgba(220,120,120,0.9)"
                        ]
                        [ text "COULD NOT SAVE — TRY AGAIN" ]

                  else
                    text ""
                ]


statusLine : String -> Html msg
statusLine label =
    div
        [ Attr.class "f6 mt3 tracked"
        , Attr.style "color" "rgba(200,200,200,0.85)"
        ]
        [ text label ]


viewBoard : State -> Html Msg
viewBoard state =
    case state.board of
        Nothing ->
            div [ Attr.class "f7 mt3 o-60" ] [ text "LOADING..." ]

        Just [] ->
            div [ Attr.class "f7 mt3 o-60" ] [ text "NO SCORES YET" ]

        Just entries ->
            div [ Attr.class "mt3" ]
                (List.indexedMap (viewEntry state) entries)


viewEntry : State -> Int -> Entry -> Html Msg
viewEntry state rank entry =
    let
        -- Highlight the row the player just put on the board.
        mine =
            state.phase
                == Saved
                && entry.name
                == String.trim state.name
                && entry.score
                == state.score

        color =
            if mine then
                "rgba(255,255,255,0.95)"

            else
                "rgba(190,190,190,0.85)"
    in
    div
        [ Attr.class "flex justify-between f7 tracked pv1 ph1"
        , Attr.style "color" color
        , Attr.style "border-bottom" "1px solid rgba(192,192,192,0.12)"
        , Attr.style "text-shadow"
            (if mine then
                "0 0 8px rgba(255,255,255,0.5)"

             else
                "none"
            )
        ]
        [ div [] [ text (String.padLeft 2 '0' (String.fromInt (rank + 1)) ++ " " ++ entry.name) ]
        , div [] [ text (String.fromInt entry.score) ]
        ]
