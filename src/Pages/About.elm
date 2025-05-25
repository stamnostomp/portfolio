module Pages.About exposing (view)

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onFocus, onInput, stopPropagationOn)
import Json.Decode as Decode



-- About page with multiple information areas - same style as Contact
-- Define a message type for internal use


type AboutMsg
    = NoOp


view : Html AboutMsg
view =
    div
        [ Attr.class "flex flex-column items-center justify-center h-100 pa2 monospace bg-transparent relative"
        ]
        [ -- Goop-style title with close button (more compact)
          div [ Attr.class "relative mb3 w-100 mw6" ]
            [ h1
                [ Attr.class "f3 tc tracked goop-title"
                , Attr.style "color" "transparent"
                , Attr.style "background" "linear-gradient(135deg, #c0c0c0, #606060, #404040)"
                , Attr.style "-webkit-background-clip" "text"
                , Attr.style "background-clip" "text"
                , Attr.style "text-shadow" "0 0 20px rgba(192, 192, 192, 0.3)"
                , Attr.style "filter" "drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3))"
                ]
                [ text "ABOUT" ]

            -- Close button positioned in top-right
            , button
                [ Attr.class "bg-transparent pa1 ph2 f7 fw6 monospace tracked pointer relative overflow-hidden ttu goop-close-button fr"
                , Attr.style "min-width" "70px"
                , Attr.style "height" "32px"
                ]
                [ text "✕ CLOSE" ]
            ]

        -- Skills/Tech node grid (more compact)
        , div
            [ Attr.class "flex gap2 mb3 flex-wrap justify-center"
            ]
            [ goopInfoNode "FRONTEND" "React, Elm, WebGL" "node-1"
            , goopInfoNode "BACKEND" "Node.js, Elixir, Haskell" "node-2"
            , goopInfoNode "DESIGN" "UI/UX, Shaders" "node-3"
            ]

        -- Compact information areas with scroll
        , div
            [ Attr.class "w-100 mw6 relative transmission-interface overflow-auto"
            , Attr.style "max-height" "60vh"
            ]
            [ -- Bio section (more compact)
              infoSection "BIO" " I LOVE EATING BUGS"

            -- Experience section (more compact)
            , infoSection "EXPERIENCE" "I HAVE EAT 5 BUGS"

            -- Philosophy section (more compact)
            , infoSection "PHILOSOPHY" "I THINK BUGS ARE COOL"

            -- Current section (more compact)
            , infoSection "CURRENTLY" "EATING 1 MORE BUG"
            ]

        -- Goop CSS effects with close button styling
        , node "style"
            []
            [ text """
                /* Tachyons gap utilities */
                .gap3 { gap: 1rem; }
                .gap2 { gap: 0.5rem; }

                /* Goop close button effects */
                .goop-close-button {
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.15) 0%,
                        rgba(64, 64, 64, 0.1) 50%,
                        rgba(0, 0, 0, 0.1) 100%) !important;
                    transition: all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    backdrop-filter: blur(2px);
                    animation: close-button-float 3s ease-in-out infinite;
                    border: 1px solid rgba(192, 192, 192, 0.4) !important;
                    color: rgba(192, 192, 192, 0.9) !important;
                    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2),
                                inset 0 1px 0 rgba(255, 255, 255, 0.1);
                }

                .goop-close-button::before {
                    content: '';
                    position: absolute;
                    top: -50%;
                    left: -50%;
                    width: 200%;
                    height: 200%;
                    background: conic-gradient(
                        from 0deg at 50% 50%,
                        transparent 0deg,
                        rgba(192, 192, 192, 0.1) 90deg,
                        transparent 180deg,
                        rgba(192, 192, 192, 0.05) 270deg,
                        transparent 360deg
                    );
                    animation: close-button-rotate 6s linear infinite;
                    opacity: 0;
                    transition: opacity 0.3s;
                }

                .goop-close-button:hover::before {
                    opacity: 1;
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
                                0 0 20px rgba(192, 192, 192, 0.2),
                                inset 0 1px 0 rgba(255, 255, 255, 0.2);
                    text-shadow: 0 0 10px rgba(192, 192, 192, 0.4);
                }

                @keyframes close-button-float {
                    0%, 100% { transform: translateY(0px); }
                    50% { transform: translateY(-1px); }
                }

                @keyframes close-button-rotate {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }

                /* Goop title animation */
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

                /* Info nodes (similar to contact nodes) */
                .goop-info-node {
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.15) 0%,
                        rgba(64, 64, 64, 0.1) 50%,
                        transparent 100%);
                    border: 1px solid rgba(192, 192, 192, 0.2);
                    transition: all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    backdrop-filter: blur(2px);
                    position: relative;
                    overflow: hidden;
                }

                .goop-info-node::before {
                    content: '';
                    position: absolute;
                    top: -50%;
                    left: -50%;
                    width: 200%;
                    height: 200%;
                    background: conic-gradient(
                        from 0deg at 50% 50%,
                        transparent 0deg,
                        rgba(192, 192, 192, 0.1) 60deg,
                        transparent 120deg,
                        rgba(192, 192, 192, 0.05) 180deg,
                        transparent 240deg,
                        rgba(192, 192, 192, 0.1) 300deg,
                        transparent 360deg
                    );
                    animation: node-rotate 8s linear infinite;
                    opacity: 0;
                    transition: opacity 0.4s;
                }

                .goop-info-node:hover::before {
                    opacity: 1;
                }

                @keyframes node-rotate {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }

                .goop-info-node:hover {
                    transform: translateY(-2px) scale(1.02);
                    border-color: rgba(192, 192, 192, 0.6);
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.25) 0%,
                        rgba(64, 64, 64, 0.15) 50%,
                        rgba(0, 0, 0, 0.1) 100%);
                    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3),
                                0 0 20px rgba(192, 192, 192, 0.1);
                }

                .goop-info-node:hover * {
                    color: rgba(255, 255, 255, 0.95) !important;
                    text-shadow: 0 0 8px rgba(192, 192, 192, 0.4);
                }

                /* Info sections */
                .info-section {
                    background: rgba(0, 0, 0, 0.1);
                    border: 1px solid rgba(192, 192, 192, 0.1);
                    backdrop-filter: blur(2px);
                    transition: all 0.3s ease;
                }

                .info-section:hover {
                    background: rgba(0, 0, 0, 0.15);
                    border-color: rgba(192, 192, 192, 0.2);
                    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
                }

                /* Section titles */
                .section-title {
                    color: rgba(192, 192, 192, 0.8) !important;
                    font-size: 11px !important;
                    letter-spacing: 0.15em;
                    text-transform: uppercase;
                    margin-bottom: 12px;
                    display: block;
                    position: relative;
                }

                .section-title::after {
                    content: '';
                    position: absolute;
                    bottom: -4px;
                    left: 0;
                    width: 24px;
                    height: 1px;
                    background: rgba(192, 192, 192, 0.4);
                }

                /* Breathing animation */
                .transmission-interface {
                    animation: interface-breathe 6s ease-in-out infinite;
                }

                @keyframes interface-breathe {
                    0%, 100% { opacity: 0.95; }
                    50% { opacity: 1; }
                }
            """ ]
        ]



-- Info node (like contact node but for skills/tech)


goopInfoNode : String -> String -> String -> Html AboutMsg
goopInfoNode title description nodeId =
    div
        [ Attr.class "db pa2 ph3 tc goop-info-node"
        , Attr.style "min-width" "100px"
        , Attr.id nodeId
        , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
        ]
        [ -- Title
          h3
            [ Attr.class "f7 mb1 tracked normal ttu"
            , Attr.style "color" "rgba(192, 192, 192, 0.8)"
            ]
            [ text title ]

        -- Description
        , p
            [ Attr.class "f7 ma0 fw5"
            , Attr.style "color" "rgba(192, 192, 192, 0.9)"
            , Attr.style "line-height" "1.2"
            ]
            [ text description ]
        ]



-- Information section with click blocking (more compact)


infoSection : String -> String -> Html AboutMsg
infoSection title content =
    div
        [ Attr.class "mb3 pa3 info-section"
        , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
        ]
        [ h3
            [ Attr.class "section-title" ]
            [ text title ]
        , p
            [ Attr.class "f6 lh-copy ma0"
            , Attr.style "color" "rgba(192, 192, 192, 0.9)"
            ]
            [ text content ]
        ]
