module Pages.Games exposing (GamesMsg(..), view)

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onFocus, onInput, stopPropagationOn)
import Json.Decode as Decode



-- Games gallery: a grid of games; selecting one opens it.


type GamesMsg
    = NoOp
    | OpenGame String
    | Close


viewModeIndicator : String -> String -> Bool -> Html GamesMsg
viewModeIndicator title nodeId isActive =
    div
        [ Attr.class
            ("db pa1 ph2 tc view-mode-indicator"
                ++ (if isActive then
                        " active"

                    else
                        ""
                   )
            )
        , Attr.style "min-width" "50px"
        , Attr.id nodeId
        , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
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



-- Game preview component (simple monochrome tile)


gamePreview : String -> Html GamesMsg
gamePreview gameId =
    div
        [ Attr.class "game-canvas"
        , Attr.style "width" "100%"
        , Attr.style "height" "100%"
        , Attr.style "background" "radial-gradient(ellipse at center, rgba(192,192,192,0.12) 0%, rgba(0,0,0,0.5) 100%)"
        , Attr.style "display" "flex"
        , Attr.style "align-items" "center"
        , Attr.style "justify-content" "center"
        , Attr.style "border-radius" "4px"
        ]
        [ div
            [ Attr.style "font-size" "10px"
            , Attr.style "letter-spacing" "0.12em"
            , Attr.style "text-transform" "uppercase"
            , Attr.style "color" "rgba(192,192,192,0.7)"
            ]
            [ text gameId ]
        ]



-- Game item component


gameItem : String -> String -> String -> Html GamesMsg
gameItem title gameId description =
    div
        [ Attr.class "game-item"
        , Attr.attribute "data-game" gameId
        , stopPropagationOn "click" (Decode.succeed ( OpenGame gameId, True ))
        ]
        [ -- Game container
          div
            [ Attr.class "game-container"
            ]
            [ gamePreview gameId ]

        -- Title
        , div
            [ Attr.class "game-title"
            , Attr.style "color" "rgba(255, 255, 255, 0.9)"
            , Attr.style "font-size" "11px"
            , Attr.style "letter-spacing" "0.05em"
            , Attr.style "text-transform" "uppercase"
            , Attr.style "font-weight" "600"
            , Attr.style "text-align" "center"
            , Attr.style "line-height" "1.2"
            ]
            [ text title ]

        -- Description
        , div
            [ Attr.class "game-description"
            ]
            [ text description ]
        ]


view : Html GamesMsg
view =
    div
        [ Attr.class "h-100 w-100 flex flex-column monospace bg-transparent relative"
        ]
        [ -- Header with title and view mode indicators
          div
            [ Attr.class "flex justify-between items-center pa1 ph2"
            , Attr.style "background" "rgba(0, 0, 0, 0.2)"
            , Attr.style "backdrop-filter" "blur(4px)"
            , Attr.style "border-bottom" "1px solid rgba(192, 192, 192, 0.1)"
            , Attr.style "margin" "0.5rem 0 0.5rem 0"
            ]
            [ -- Left side: Title and view mode indicators
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
                    [ text "GAMES" ]

                -- View mode indicators
                , div [ Attr.class "flex gap1" ]
                    [ viewModeIndicator "GRID" "view-grid" True
                    , viewModeIndicator "WORKS" "view-works" False
                    , viewModeIndicator "EXPERIMENTS" "view-experiments" False
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

        -- Main games container with scroll
        , div
            [ Attr.class "w-100 relative custom-scroll-container"
            , Attr.style "height" "calc(100% - 80px)"
            , Attr.style "margin" "0 0 0.5rem 0"
            ]
            [ -- Top fade overlay
              div
                [ Attr.class "dn absolute top-0 left-0 right-0 z-2 pointer-events-none fade-overlay-top" ]
                []

            -- Scrollable games content
            , div
                [ Attr.class "custom-scroll-content transmission-interface"
                , Attr.style "height" "100%"
                , Attr.style "overflow-y" "auto"
                , Attr.style "overflow-x" "hidden"
                , Attr.style "padding" "1rem"
                , Attr.style "padding-right" "2rem"
                , Attr.style "margin-right" "-1rem"
                ]
                [ -- Games grid with water-drop hover effects
                  div
                    [ Attr.class "image-games" ]
                    [ -- Missile Command (playable)
                      gameItem "MISSILE COMMAND" "missile-command" "Defend your cities"
                    , gameItem "3D SHOOTER" "shooter" "A retro-style 3D shooter with WebGL"
                    , gameItem "SPACE INVADERS" "invaders" "Classic arcade shooter"
                    , gameItem "SNAKE" "snake" "Retro snake game"
                    , gameItem "PONG" "pong" "The classic paddle game"
                    , gameItem "BREAKOUT" "breakout" "Brick breaking action"
                    , gameItem "ASTEROIDS" "asteroids" "Space rock dodging"
                    , gameItem "TETRIS" "tetris" "Block stacking puzzle"
                    , gameItem "PACMAN" "pacman" "Maze chasing classic"
                    , gameItem "TIC-TAC-TOE" "tictactoe" "Simple strategy game"
                    , gameItem "MEMORY" "memory" "Card matching game"
                    , gameItem "SIMON" "simon" "Color sequence memory"
                    , gameItem "FLAPPY" "flappy" "Endless flyer game"
                    ]

                -- Bottom fade overlay
                , div
                    [ Attr.class "dn absolute bottom-0 left-0 right-0 z-2 pointer-events-none fade-overlay-bottom" ]
                    []
                ]
            ]

        -- Enhanced CSS with games-specific styling and water-drop effect
        , node "style"
            []
            [ text """
                    /* Image games grid layout with water-drop effect */
                    .image-games {
                        display: grid;
                        grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
                        gap: 1rem;
                        padding: 1rem 0;
                        position: relative;
                    }

                    @media (min-width: 768px) {
                        .image-games {
                            grid-template-columns: repeat(4, 1fr);
                            gap: 1.25rem;
                        }
                    }

                    @media (min-width: 1024px) {
                        .image-games {
                            grid-template-columns: repeat(5, 1fr);
                            gap: 1.5rem;
                        }
                    }

                    /* Game items with water-drop hover effect */
                    .game-item {
                        background: radial-gradient(ellipse at top left,
                            rgba(192, 192, 192, 0.08) 0%,
                            rgba(64, 64, 64, 0.05) 40%,
                            rgba(0, 0, 0, 0.1) 100%);
                        border: 1px solid rgba(192, 192, 192, 0.15);
                        backdrop-filter: blur(3px);
                        transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
                        position: relative;
                        overflow: hidden;
                        cursor: pointer;
                        animation: item-fade-in 0.8s ease-out forwards;
                        opacity: 0;
                        border-radius: 8px;
                        aspect-ratio: 1;
                        display: flex;
                        flex-direction: column;
                        justify-content: center;
                        align-items: center;
                        padding: 1rem;
                        text-decoration: none !important;
                        color: inherit !important;
                    }

                    @keyframes item-fade-in {
                        from {
                            opacity: 0;
                            transform: translateY(20px) scale(0.9);
                        }
                        to {
                            opacity: 1;
                            transform: translateY(0) scale(1);
                        }
                    }

                    /* Staggered animation delays */
                    .game-item:nth-child(1) { animation-delay: 0.1s; }
                    .game-item:nth-child(2) { animation-delay: 0.15s; }
                    .game-item:nth-child(3) { animation-delay: 0.2s; }
                    .game-item:nth-child(4) { animation-delay: 0.25s; }
                    .game-item:nth-child(5) { animation-delay: 0.3s; }
                    .game-item:nth-child(6) { animation-delay: 0.35s; }
                    .game-item:nth-child(7) { animation-delay: 0.4s; }
                    .game-item:nth-child(8) { animation-delay: 0.45s; }
                    .game-item:nth-child(9) { animation-delay: 0.5s; }
                    .game-item:nth-child(10) { animation-delay: 0.55s; }
                    .game-item:nth-child(11) { animation-delay: 0.6s; }
                    .game-item:nth-child(12) { animation-delay: 0.65s; }

                    /* Water-drop hover effect - grows and pushes others */
                    .game-item:hover {
                        transform: scale(1.15);
                        z-index: 10;
                        border-color: rgba(192, 192, 192, 0.4);
                        background: radial-gradient(ellipse at center,
                            rgba(192, 192, 192, 0.15) 0%,
                            rgba(64, 64, 64, 0.1) 40%,
                            rgba(0, 0, 0, 0.05) 100%);
                        box-shadow:
                            0 15px 35px rgba(0, 0, 0, 0.4),
                            0 0 50px rgba(192, 192, 192, 0.15),
                            inset 0 1px 0 rgba(255, 255, 255, 0.1);
                    }

                    /* Ripple effect for neighboring items */
                    .image-games:hover .game-item:not(:hover) {
                        transform: scale(0.95);
                        opacity: 0.8;
                        filter: blur(1px);
                    }

                    /* Enhanced ripple for immediate neighbors */
                    .game-item:hover + .game-item,
                    .game-item:has(+ .game-item:hover) {
                        transform: scale(0.9) !important;
                        opacity: 0.6 !important;
                    }

                    .game-item:hover * {
                        color: rgba(255, 255, 255, 0.95) !important;
                    }

                    /* Game container styling */
                    .game-container {
                        width: 100%;
                        height: 60%;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        margin-bottom: 0.5rem;
                        position: relative;
                    }

                    .game-canvas {
                        max-width: 100%;
                        max-height: 100%;
                        object-fit: contain;
                        opacity: 0.8;
                        transition: all 0.3s ease;
                        border-radius: 4px;
                    }

                    .game-item:hover .game-canvas {
                        opacity: 1 !important;
                        transform: scale(1.05);
                    }

                    .game-title {
                        transition: all 0.3s ease;
                    }

                    .game-item:hover .game-title {
                        color: rgba(255, 255, 255, 1) !important;
                        text-shadow: 0 0 10px rgba(192, 192, 192, 0.3);
                    }

                    .game-description {
                        font-size: 10px;
                        color: rgba(192, 192, 192, 0.7);
                        text-align: center;
                        margin-top: 0.25rem;
                        transition: all 0.3s ease;
                    }

                    .game-item:hover .game-description {
                        color: rgba(255, 255, 255, 0.8);
                    }

                    /* View mode indicators */
                    .view-mode-indicator {
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

                    .view-mode-indicator.active {
                        background: radial-gradient(ellipse at center,
                            rgba(192, 192, 192, 0.15) 0%,
                            rgba(64, 64, 64, 0.1) 50%,
                            rgba(0, 0, 0, 0.05) 100%);
                        border-color: rgba(192, 192, 192, 0.4);
                        color: rgba(192, 192, 192, 0.9) !important;
                        box-shadow: 0 0 10px rgba(192, 192, 192, 0.2);
                    }

                    .view-mode-indicator:hover {
                        transform: translateY(-1px) scale(1.05);
                        border-color: rgba(192, 192, 192, 0.4);
                        background: radial-gradient(ellipse at center,
                            rgba(192, 192, 192, 0.2) 0%,
                            rgba(64, 64, 64, 0.1) 50%,
                            rgba(0, 0, 0, 0.05) 100%);
                    }

                    /* Custom scroll styling */
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

                    /* Close button styling */
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

                    /* Game iframe styling */
                    .game-iframe {
                        border: none;
                        background: transparent;
                    }

                    /* Tachyons gap utilities */
                    .gap2 { gap: 0.5rem; }
                    .gap1 { gap: 0.25rem; }
                """
            ]
        ]
