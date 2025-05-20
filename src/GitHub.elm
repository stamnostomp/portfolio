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
    }


-- API

fetchCommits : (Result Http.Error (List Commit) -> msg) -> Cmd msg
fetchCommits toMsg =
    -- For demonstration, we'll use mock data
    -- In a real app, you would make an HTTP request to GitHub's API
    Task.perform
        (\_ ->
            toMsg (Ok
                [ { message = "Add new y2k filter effect", date = "2025-05-18T15:30:00Z", sha = "a1b2c3d4", url = "https://github.com/stamnostomp/stamnostomp/commit/a1b2c3d4" }
                , { message = "Fix display issue on Projects page", date = "2025-05-17T09:22:18Z", sha = "e5f6g7h8", url = "https://github.com/stamnostomp/stamnostomp/commit/e5f6g7h8" }
                , { message = "Update color palette for retro aesthetic", date = "2025-05-15T14:45:33Z", sha = "i9j0k1l2", url = "https://github.com/stamnostomp/stamnostomp/commit/i9j0k1l2" }
                , { message = "Implement scanline effect", date = "2025-05-12T11:18:45Z", sha = "m3n4o5p6", url = "https://github.com/stamnostomp/stamnostomp/commit/m3n4o5p6" }
                , { message = "Initial Y2K portfolio structure", date = "2025-05-10T08:30:22Z", sha = "q7r8s9t0", url = "https://github.com/stamnostomp/stamnostomp/commit/q7r8s9t0" }
                , { message = "Add web-1.0 style form elements", date = "2025-05-08T16:42:10Z", sha = "u1v2w3x4", url = "https://github.com/stamnostomp/stamnostomp/commit/u1v2w3x4" }
                , { message = "Implement CRT screen effect with WebGL", date = "2025-05-06T14:15:30Z", sha = "y5z6a7b8", url = "https://github.com/stamnostomp/stamnostomp/commit/y5z6a7b8" }
                , { message = "Add animated cursor trail effect", date = "2025-05-04T09:10:25Z", sha = "c9d0e1f2", url = "https://github.com/stamnostomp/stamnostomp/commit/c9d0e1f2" }
                , { message = "Fix mouse position tracking in WebGL shader", date = "2025-05-02T11:20:45Z", sha = "g3h4i5j6", url = "https://github.com/stamnostomp/stamnostomp/commit/g3h4i5j6" }
                , { message = "Update loading screen animations", date = "2025-04-30T10:05:15Z", sha = "k7l8m9n0", url = "https://github.com/stamnostomp/stamnostomp/commit/k7l8m9n0" }
                , { message = "Add retro hit counter", date = "2025-04-28T16:33:22Z", sha = "o1p2q3r4", url = "https://github.com/stamnostomp/stamnostomp/commit/o1p2q3r4" }
                , { message = "Implement glitch text effect on hover", date = "2025-04-26T13:47:56Z", sha = "s5t6u7v8", url = "https://github.com/stamnostomp/stamnostomp/commit/s5t6u7v8" }
                ]
            )
        )
        (Task.succeed ())

-- This is how you would implement real GitHub API calls with proper error handling:
-- (Commented out to use the mock data above instead)
{-
fetchCommitsReal : (Result Http.Error (List Commit) -> msg) -> Cmd msg
fetchCommitsReal toMsg =
    Http.get
        { url = "https://api.github.com/repos/stamnostomp/your-repo-name/commits"
        , expect = Http.expectJson toMsg decodeCommits
        }
-}


decodeCommits : Decode.Decoder (List Commit)
decodeCommits =
    Decode.list
        (Decode.map4 Commit
            (Decode.at [ "commit", "message" ] Decode.string)
            (Decode.at [ "commit", "author", "date" ] Decode.string)
            (Decode.field "sha" Decode.string)
            (Decode.field "html_url" Decode.string)
        )


decodeCommits : Decode.Decoder (List Commit)
decodeCommits =
    Decode.list
        (Decode.map3 Commit
            (Decode.at [ "commit", "message" ] Decode.string)
            (Decode.at [ "commit", "author", "date" ] Decode.string)
            (Decode.field "sha" Decode.string)
        )


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
