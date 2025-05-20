module View.Home exposing (view)

import GitHub
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (Model, Msg(..))
import View.Common exposing (..)


view : Model -> Html Msg
view model =
    div [ class "flex flex-wrap" ]
        [ div [ class "w-100 w-60-ns pa2" ]
            [ div [ class "pa3 br2 bg-navy blue mb3 relative overflow-hidden" ]
                [ h2 [ class "mt0 mb3 f3 pink" ] [ text "VIRTUAL DELIGHT" ]
                , p [ class "measure" ] [ text "Welcome to the digital utopia of tomorrow, where beauty is evolutionized and style is your interface to the world." ]
                , p [ class "measure" ] [ text "Browse the collections. Mix the fabrics. Create your virtual self." ]
                , div [ class "absolute top-0 right-0 pa2 o-70 f7" ]
                    [ text "ID: 1001100"
                    ]
                ]
            , div [ class "pa3 br2 bg-dark-blue light-blue" ]
                [ h3 [ class "mt0 mb2 f4 yellow" ] [ text "SYSTEM STATUS" ]
                , div [ class "flex flex-wrap" ]
                    [ statusBlock "Memory" "87%" "bg-pink"
                    , statusBlock "CPU" "42%" "bg-green"
                    , statusBlock "Network" "91%" "bg-gold"
                    , statusBlock "Data" "53%" "bg-light-purple"
                    ]
                ]
            ]
        , div [ class "w-100 w-40-ns pa2" ]
            [ div [ class "pa3 br2 bg-dark-gray near-white mb3 commits-container" ]
                [ h3 [ class "mt0 mb3 f4 light-green" ] [ text "LATEST UPDATES" ]
                , if model.gitHubLoading then
                    div [ class "tc pa3" ]
                        [ text "LOADING REPOSITORY DATA..."
                        , div [ class "w-100 h1 bg-white mt2 overflow-hidden" ]
                            [ div [ class "bg-hot-pink h-100 loading-progress" ] [] ]
                        ]
                  else if model.gitHubError /= Nothing then
                    div [ class "tc pa3 light-red" ]
                        [ text "ERROR ACCESSING REPOSITORY"
                        , div [ class "f7 mt2" ]
                            [ text (Maybe.withDefault "Unknown error" model.gitHubError) ]
                        ]
                  else
                    div [ class "commits-list", style "max-height" "340px", style "overflow-y" "auto" ]
                        [ ul [ class "list pl0 pr2" ]
                            (List.map
                                (\commit ->
                                    let
                                        -- Truncate long commit messages
                                        truncatedMessage =
                                            if String.length commit.message > 40 then
                                                String.left 37 commit.message ++ "..."
                                            else
                                                commit.message
                                    in
                                    updateItem truncatedMessage (GitHub.formatDate commit.date) (Just commit.url)
                                )
                                model.gitHubCommits
                            )
                        ]
                , div [ class "mt3 tc f7 o-70 pt2 bt b--gray" ]
                    [ text "GITHUB://STAMNOSTOMP" ]
                ]
            , colorPalette
            ]
        , div [ class "w-100 pa2 mt3" ]
            [ div [ class "flex justify-center" ]
                [ navArrow "◀" "Previous"
                , navArrow "▲" "Up"
                , navArrow "▶" "Next"
                ]
            ]
        ]
