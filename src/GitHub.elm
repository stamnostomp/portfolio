module GitHub exposing (Commit, fetchCommits, decodeCommits, formatDate)

import Http
import Json.Decode as Decode
import Task
import Time


-- MODEL

type alias Commit =
    { message : String
    , date : String
    , sha : String
    , url : String
    , repoName : String
    }


-- CONFIGURATION

-- When using elm-live with proxy mode, we can use a relative URL
-- This works with: elm-live --proxy-prefix=/api --proxy-host=http://localhost:8001
proxyUrl : String
proxyUrl =
    "/api/all-commits"


-- API

fetchCommits : (Result Http.Error (List Commit) -> msg) -> Cmd msg
fetchCommits toMsg =
    -- Real implementation using the proxy server
    Http.get
        { url = proxyUrl
        , expect = Http.expectJson toMsg decodeCommits
        }


-- DECODERS AND FORMATTERS

-- Decoder for GitHub API commits response through our proxy
decodeCommits : Decode.Decoder (List Commit)
decodeCommits =
    Decode.list
        (Decode.map5 Commit
            (Decode.at [ "commit", "message" ] Decode.string)
            (Decode.at [ "commit", "author", "date" ] Decode.string)
            (Decode.field "sha" Decode.string)
            (Decode.field "html_url" Decode.string)
            (Decode.at [ "repository", "name" ] Decode.string)
        )


-- Format dates to Y2K style
formatDate : String -> String
formatDate isoDate =
    -- Simple date formatting function
    -- In a real app, you'd want to use a proper date formatting library
    let
        dateParts =
            String.split "T" isoDate

        datePart =
            Maybe.withDefault "" (List.head dateParts)

        parts =
            String.split "-" datePart
    in
    case parts of
        [ year, month, day ] ->
            month ++ "." ++ day ++ "." ++ year

        _ ->
            isoDate
