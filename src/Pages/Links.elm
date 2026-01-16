module Pages.Links exposing (view, LinksMsg(..), allLinks, LinkStatus(..))

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onFocus, onInput, stopPropagationOn)
import Json.Decode as Decode
import Types exposing (LinkFilter(..))
import Dict exposing (Dict)


-- Links page showcasing live services and platforms
-- Define a message type for internal use


type LinksMsg
    = NoOp
    | OpenLink String
    | ToggleFilter LinkFilter
    | CheckLinkStatus String
    | LinkStatusChecked String LinkStatus
    | Close


type LinkStatus
    = Checking
    | Online
    | Offline
    | CorsError


-- Link data structure with categories


type alias LinkItem =
    { title : String
    , url : String
    , categories : List LinkFilter
    }


-- All links with categorization


allLinks : List LinkItem
allLinks =
    [ { title = "MEDIA STREAMING"
      , url = "https://media.stamno.com"
      , categories = [ OnlineStatus, MediaCategory ]
      }
    , { title = "MUSIC SERVER"
      , url = "https://music.stamno.com"
      , categories = [ OnlineStatus, MediaCategory ]
      }
    , { title = "PHOTO GALLERY"
      , url = "https://photos.stamno.com"
      , categories = [ OnlineStatus, MediaCategory ]
      }
    , { title = "CLOUD STORAGE"
      , url = "https://files.stamno.com"
      , categories = [ OnlineStatus, StorageCategory ]
      }
    , { title = "FILE SHARING"
      , url = "https://share.stamno.com"
      , categories = [ OnlineStatus, StorageCategory ]
      }
    , { title = "BACKUP SYSTEM"
      , url = "https://backup.stamno.com"
      , categories = [ StorageCategory ]
      }
    , { title = "GIT REPOS"
      , url = "https://git.stamno.com"
      , categories = [ OnlineStatus ]
      }
    , { title = "CODE REVIEW"
      , url = "https://review.stamno.com"
      , categories = [ OnlineStatus ]
      }
    , { title = "MONITORING"
      , url = "https://monitor.stamno.com"
      , categories = [ OnlineStatus ]
      }
    , { title = "MATRIX CHAT"
      , url = "https://matrix.stamno.com"
      , categories = [ OnlineStatus ]
      }
    , { title = "RSS FEEDS"
      , url = "https://feeds.stamno.com"
      , categories = [ OnlineStatus ]
      }
    , { title = "BOOKMARKS"
      , url = "https://bookmarks.stamno.com"
      , categories = [ OnlineStatus ]
      }
    ]


-- Helper to check if a filter is in the active filters


filterIsActive : LinkFilter -> List LinkFilter -> Bool
filterIsActive filter activeFilters =
    List.any (\f -> f == filter) activeFilters


-- Filter links based on active filters


filteredLinks : List LinkFilter -> List LinkItem -> List LinkItem
filteredLinks activeFilters links =
    if List.isEmpty activeFilters then
        links

    else
        links
            |> List.filter
                (\link ->
                    link.categories
                        |> List.any (\cat -> filterIsActive cat activeFilters)
                )


view : List LinkFilter -> Dict String LinkStatus -> Html LinksMsg
view activeFilters linkStatuses =
    div
        [ Attr.class "h-100 w-100 flex flex-column monospace bg-transparent relative"
        ]
        [ -- Header with title and service status indicators
          div
            [ Attr.class "flex justify-between items-center pa1 ph2"
            , Attr.style "background" "rgba(0, 0, 0, 0.2)"
            , Attr.style "backdrop-filter" "blur(4px)"
            , Attr.style "border-bottom" "1px solid rgba(192, 192, 192, 0.1)"
            , Attr.style "margin" "0.5rem 0 0.5rem 0"
            ]
            [ -- Left side: Title and service status indicators
              div [ Attr.class "flex items-center gap2" ]
                [ h1
                    [ Attr.class "f6 tracked goop-title ma0 mr2"
                    , Attr.style "color" "transparent"
                    , Attr.style "background" "linear-gradient(135deg, #c0c0c0, #606060, #404040)"
                    , Attr.style "-webkit-background-clip" "text"
                    , Attr.style "background-clip" "text"
                    , Attr.style "text-shadow" "0 0 20px rgba(192, 192, 192, 0.3)"
                    , Attr.style "filter" "drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3))"
                    ]
                    [ text "LINKS" ]

                -- Service status indicators
                , div [ Attr.class "flex gap1" ]
                    [ statusIndicator "ONLINE" OnlineStatus activeFilters
                    , statusIndicator "MEDIA" MediaCategory activeFilters
                    , statusIndicator "STORAGE" StorageCategory activeFilters
                    ]
                ]

            -- Right side: Close button
            , button
                [ Attr.class "bg-transparent pa1 ph2 f8 fw6 monospace tracked pointer relative overflow-hidden ttu goop-close-button"
                , Attr.style "min-width" "50px"
                , Attr.style "height" "24px"
                , onClick Close
                , stopPropagationOn "click" (Decode.succeed ( Close, True ))
                ]
                [ text "✕ CLOSE" ]
            ]

        -- Main links container with scroll
        , div
            [ Attr.class "w-100 relative custom-scroll-container"
            , Attr.style "height" "calc(100% - 80px)"
            , Attr.style "margin" "0 0 0.5rem 0"
            ]
            [ -- Top fade overlay
              div
                [ Attr.class "dn absolute top-0 left-0 right-0 z-2 pointer-events-none fade-overlay-top" ]
                []

            -- Scrollable links content
            , div
                [ Attr.class "custom-scroll-content transmission-interface"
                , Attr.style "height" "100%"
                , Attr.style "overflow-y" "auto"
                , Attr.style "overflow-x" "hidden"
                , Attr.style "padding" "1rem"
                , Attr.style "padding-right" "2rem"
                , Attr.style "margin-right" "-1rem"
                ]
                [ -- Compact grid of service links with filtering
                  div
                    [ Attr.class "links-grid" ]
                    (filteredLinks activeFilters allLinks
                        |> List.map (\link ->
                            let
                                status = Dict.get link.url linkStatuses |> Maybe.withDefault Checking
                            in
                            compactLinkItem link.title link.url status)
                    )
                ]

            -- Bottom fade overlay
            , div
                [ Attr.class "dn absolute bottom-0 left-0 right-0 z-2 pointer-events-none fade-overlay-bottom" ]
                []
            ]

        -- Enhanced CSS with links-specific styling
        , node "style"
            []
            [ text """
                /* Compact grid layout */
                .links-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
                    gap: 1rem;
                    padding: 0.5rem 0;
                }

                @media (min-width: 768px) {
                    .links-grid {
                        grid-template-columns: repeat(4, 1fr);
                        gap: 1.25rem;
                    }
                }

                @media (min-width: 1024px) {
                    .links-grid {
                        grid-template-columns: repeat(6, 1fr);
                        gap: 1.5rem;
                    }
                }

                /* Compact link items */
                .compact-link-item {
                    background: radial-gradient(ellipse at top left,
                        rgba(192, 192, 192, 0.12) 0%,
                        rgba(64, 64, 64, 0.08) 40%,
                        rgba(0, 0, 0, 0.15) 100%);
                    border: 2px solid rgba(192, 192, 192, 0.25);
                    backdrop-filter: blur(3px);
                    transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    position: relative;
                    overflow: hidden;
                    cursor: pointer;
                    animation: item-fade-in 0.8s ease-out forwards;
                    opacity: 0;
                    padding: 1rem;
                    border-radius: 8px;
                    text-decoration: none !important;
                    display: flex;
                    flex-direction: column;
                    justify-content: space-between;
                    min-height: 80px;
                    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
                }

                @keyframes item-fade-in {
                    from {
                        opacity: 0;
                        transform: translateY(20px);
                    }
                    to {
                        opacity: 1;
                        transform: translateY(0);
                    }
                }

                /* Staggered animation delays */
                .link-item:nth-child(1) { animation-delay: 0.1s; }
                .link-item:nth-child(2) { animation-delay: 0.2s; }
                .link-item:nth-child(3) { animation-delay: 0.3s; }
                .link-item:nth-child(4) { animation-delay: 0.4s; }
                .link-item:nth-child(5) { animation-delay: 0.5s; }
                .link-item:nth-child(6) { animation-delay: 0.6s; }

                /* Compact link hover effects */
                .compact-link-item:hover {
                    transform: translateY(-4px) scale(1.05);
                    border-color: rgba(192, 192, 192, 0.5);
                    background: radial-gradient(ellipse at top left,
                        rgba(192, 192, 192, 0.18) 0%,
                        rgba(64, 64, 64, 0.12) 40%,
                        rgba(0, 0, 0, 0.08) 100%);
                    box-shadow:
                        0 8px 20px rgba(0, 0, 0, 0.4),
                        0 0 30px rgba(192, 192, 192, 0.15),
                        inset 0 1px 0 rgba(255, 255, 255, 0.1);
                    text-decoration: none !important;
                }

                .compact-link-item:hover * {
                    color: rgba(255, 255, 255, 0.95) !important;
                }

                /* Remove all default link styling */
                .compact-link-item, .compact-link-item:visited, .compact-link-item:active, .compact-link-item:focus {
                    text-decoration: none !important;
                    color: inherit !important;
                    outline: none;
                }

                .compact-link-item * {
                    text-decoration: none !important;
                }

                /* Compact link content styling */
                .compact-link-title {
                    color: rgba(255, 255, 255, 0.9) !important;
                    font-size: 13px !important;
                    letter-spacing: 0.05em;
                    text-transform: uppercase;
                    font-weight: 600;
                    line-height: 1.2;
                    margin-bottom: 0.5rem;
                }

                .compact-link-status {
                    font-size: 9px;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                    padding: 0.25rem 0.5rem;
                    border-radius: 3px;
                    font-weight: 600;
                    text-align: center;
                }

                .compact-link-status.online {
                    color: rgba(144, 238, 144, 0.9);
                    background: rgba(144, 238, 144, 0.15);
                    border: 1px solid rgba(144, 238, 144, 0.4);
                }

                .compact-link-status.maintenance {
                    color: rgba(255, 193, 7, 0.9);
                    background: rgba(255, 193, 7, 0.15);
                    border: 1px solid rgba(255, 193, 7, 0.4);
                }

                .compact-link-status.offline {
                    color: rgba(220, 53, 69, 0.9);
                    background: rgba(220, 53, 69, 0.15);
                    border: 1px solid rgba(220, 53, 69, 0.4);
                }


                /* Status indicators */
                .status-indicator {
                    background: rgba(192, 192, 192, 0.1);
                    border: 1px solid rgba(192, 192, 192, 0.15);
                    transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    backdrop-filter: blur(2px);
                    position: relative;
                    overflow: hidden;
                    cursor: pointer;
                    padding: 0.25rem 0.5rem;
                    font-size: 9px;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                }

                /* Simple active state - bigger with subtle blue glow */
                .status-indicator.active {
                    background: radial-gradient(ellipse at center,
                        rgba(100, 150, 180, 0.15) 0%,
                        rgba(80, 120, 140, 0.08) 50%,
                        rgba(60, 100, 120, 0.03) 100%);
                    border: 2px solid rgba(100, 150, 180, 0.5);
                    color: rgba(255, 255, 255, 1) !important;
                    transform: scale(1.1);
                    box-shadow: 0 0 15px rgba(100, 150, 180, 0.4),
                                0 0 30px rgba(100, 150, 180, 0.2);
                }

                .status-indicator.active * {
                    color: rgba(255, 255, 255, 1) !important;
                }

                .status-indicator:hover {
                    transform: translateY(-1px) scale(1.05);
                    border-color: rgba(192, 192, 192, 0.4);
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.2) 0%,
                        rgba(64, 64, 64, 0.1) 50%,
                        rgba(0, 0, 0, 0.05) 100%);
                }

                .status-indicator.active:hover {
                    transform: scale(1.12);
                }

                /* Custom scroll styling - same as other pages */
                .custom-scroll-container {
                    position: relative;
                    border: none;
                    background: transparent;
                    backdrop-filter: none;
                }

                .custom-scroll-content {
                    scrollbar-width: none;
                    -ms-overflow-style: none;
                }

                .custom-scroll-content::-webkit-scrollbar {
                    display: none;
                }

                .fade-overlay-top {
                    height: 20px;
                    background: linear-gradient(to bottom,
                        rgba(0, 0, 0, 0.9) 0%,
                        rgba(0, 0, 0, 0.6) 40%,
                        rgba(0, 0, 0, 0.2) 70%,
                        transparent 100%);
                    z-index: 10;
                }

                .fade-overlay-bottom {
                    height: 20px;
                    background: linear-gradient(to top,
                        rgba(0, 0, 0, 0.9) 0%,
                        rgba(0, 0, 0, 0.6) 40%,
                        rgba(0, 0, 0, 0.2) 70%,
                        transparent 100%);
                    z-index: 10;
                }

                /* Close button styling - same as other pages */
                .goop-close-button {
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.15) 0%,
                        rgba(64, 64, 64, 0.1) 50%,
                        rgba(0, 0, 0, 0.1) 100%) !important;
                    transition: all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    backdrop-filter: blur(2px);
                    border: 1px solid rgba(192, 192, 192, 0.4) !important;
                    color: rgba(192, 192, 192, 0.9) !important;
                }

                .goop-close-button:hover {
                    transform: translateY(-2px) scale(1.05);
                    border-color: rgba(192, 192, 192, 0.8) !important;
                    color: rgba(255, 255, 255, 0.95) !important;
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.25) 0%,
                        rgba(64, 64, 64, 0.15) 50%,
                        rgba(0, 0, 0, 0.1) 100%) !important;
                    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.3),
                                0 0 20px rgba(192, 192, 192, 0.2);
                    text-shadow: 0 0 10px rgba(192, 192, 192, 0.4);
                }

                /* Title animation */
                .goop-title {
                    animation: goop-shimmer 4s ease-in-out infinite alternate;
                }

                @keyframes goop-shimmer {
                    0% {
                        filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3))
                               drop-shadow(0 0 10px rgba(192, 192, 192, 0.2));
                    }
                    100% {
                        filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.4))
                               drop-shadow(0 0 20px rgba(192, 192, 192, 0.4));
                    }
                }

                /* Breathing animation for interface */
                .transmission-interface {
                    animation: interface-breathe 8s ease-in-out infinite;
                }

                @keyframes interface-breathe {
                    0%, 100% { opacity: 0.95; }
                    50% { opacity: 1; }
                }

                /* Tachyons gap utilities */
                .gap2 { gap: 0.5rem; }
                .gap1 { gap: 0.75rem; }
            """ ]
        ]



-- Status indicator component


statusIndicator : String -> LinkFilter -> List LinkFilter -> Html LinksMsg
statusIndicator title filter activeFilters =
    let
        isActive =
            filterIsActive filter activeFilters
    in
    div
        [ Attr.class
            ("db pa1 ph2 tc status-indicator"
                ++ (if isActive then
                        " active"

                    else
                        ""
                   )
            )
        , Attr.style "min-width" "50px"
        , Attr.style "cursor" "pointer"
        , onClick (ToggleFilter filter)
        , stopPropagationOn "click" (Decode.succeed ( ToggleFilter filter, True ))
        ]
        [ span
            [ Attr.class "f8 tracked ttu"
            , Attr.style "color"
                (if isActive then
                    "rgba(192, 192, 192, 0.9)"

                 else
                    "rgba(192, 192, 192, 0.8)"
                )
            ]
            [ text title ]
        ]



-- Helper to convert LinkStatus to string


linkStatusToString : LinkStatus -> String
linkStatusToString status =
    case status of
        Checking ->
            "checking"

        Online ->
            "online"

        Offline ->
            "offline"

        CorsError ->
            "cors-error"


-- Helper to get status display text


linkStatusToDisplay : LinkStatus -> String
linkStatusToDisplay status =
    case status of
        Checking ->
            "checking..."

        Online ->
            "online"

        Offline ->
            "offline"

        CorsError ->
            "blocked"


-- Compact link item component


compactLinkItem : String -> String -> LinkStatus -> Html LinksMsg
compactLinkItem title url status =
    a
        [ Attr.class "compact-link-item"
        , Attr.href url
        , Attr.target "_blank"
        , Attr.attribute "data-status" (linkStatusToString status)
        , stopPropagationOn "click" (Decode.succeed ( OpenLink url, True ))
        ]
        [ -- Link title
          div
            [ Attr.class "compact-link-title" ]
            [ text title ]

        -- Status indicator
        , div
            [ Attr.class ("compact-link-status " ++ linkStatusToString status) ]
            [ text (linkStatusToDisplay status) ]
        ]