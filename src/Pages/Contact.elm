module Pages.Contact exposing (view)

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onFocus, onInput, stopPropagationOn)
import Json.Decode as Decode



-- Compact goop-themed contact page with Tachyons CSS
-- Define a message type for internal use


type ContactMsg
    = NoOp
    | Close


view : Html ContactMsg
view =
    div
        [ Attr.class "flex flex-column items-center justify-center h-100 pa3 monospace bg-transparent relative"
        ]
        [ -- Goop-style title with close button positioned with proper spacing
          div [ Attr.class "relative mb4 w-100 mw6" ]
            [ h1
                [ Attr.class "f2 tc tracked goop-title"
                , Attr.style "color" "transparent"
                , Attr.style "background" "linear-gradient(135deg, #c0c0c0, #606060, #404040)"
                , Attr.style "-webkit-background-clip" "text"
                , Attr.style "background-clip" "text"
                , Attr.style "text-shadow" "0 0 20px rgba(192, 192, 192, 0.3)"
                , Attr.style "filter" "drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3))"
                ]
                [ text "CONTACT" ]

            -- Close button positioned in top-right with proper spacing
            , button
                [ Attr.class "bg-transparent pa1 ph2 f7 fw6 monospace tracked pointer relative overflow-hidden ttu goop-close-button fr"
                , Attr.style "min-width" "70px"
                , Attr.style "height" "32px"
                , onClick Close
                , stopPropagationOn "click" (Decode.succeed ( Close, True ))
                ]
                [ text "✕ CLOSE" ]
            ]

        -- Contact node grid with Tachyons
        , div
            [ Attr.class "flex gap3 mb4 flex-wrap justify-center"
            ]
            [ goopContactNode "EMAIL" "stamno@stamno.com" "mailto:stamno@stamno.com" "node-1"
            , goopContactNode "GITHUB" "@stamnostomp" "https://github.com/stamnostomp" "node-2"
            , goopContactNode "DISCORD" "stamnostomp" "#" "node-3"
            ]

        -- Message interface with click-blocking container
        , div
            [ Attr.class "w-100 mw6 relative transmission-interface"
            ]
            [ -- Click-blocking container around form fields
              div
                [ Attr.class "pa3"
                , Attr.style "background" "rgba(0, 0, 0, 0.1)"
                , Attr.style "border" "1px solid rgba(192, 192, 192, 0.1)"
                , Attr.style "backdrop-filter" "blur(2px)"
                ]
                [ -- Form fields with proper event handling
                  goopFormField "NAME" "text" "Your name..." "field-1"
                , goopFormField "EMAIL" "email" "your@email.com..." "field-2"
                , goopTextArea "MESSAGE" "Your message..." "field-3"

                -- Send button with click event blocking
                , div
                    [ Attr.class "tc mt3"
                    , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
                    ]
                    [ button
                        [ Attr.class "bg-transparent pa3 ph4 f6 fw6 monospace tracked pointer relative overflow-hidden ttu transition-all transmit-button"
                        , Attr.style "color" "rgba(192, 192, 192, 0.9)"
                        , Attr.style "border" "2px solid rgba(192, 192, 192, 0.3)"
                        , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
                        ]
                        [ text "SEND" ]
                    ]
                ]
            ]

        -- Goop CSS effects with close button styling
        , node "style"
            []
            [ text """
                /* Tachyons gap utility */
                .gap3 { gap: 1rem; }

                /* Goop close button effects - positioned relative to contact content */
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

                /* Sharp-edged contact nodes */
                .goop-node {
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

                .goop-node::before {
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

                .goop-node:hover::before {
                    opacity: 1;
                }

                @keyframes node-rotate {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }

                .goop-node:hover {
                    transform: translateY(-2px) scale(1.02);
                    border-color: rgba(192, 192, 192, 0.6);
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.25) 0%,
                        rgba(64, 64, 64, 0.15) 50%,
                        rgba(0, 0, 0, 0.1) 100%);
                    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3),
                                0 0 20px rgba(192, 192, 192, 0.1);
                }

                .goop-node:hover * {
                    color: rgba(255, 255, 255, 0.95) !important;
                    text-shadow: 0 0 8px rgba(192, 192, 192, 0.4);
                }

                /* Sharp-edged form fields */
                .goop-field {
                    background: transparent;
                    border: 1px solid rgba(192, 192, 192, 0.25);
                    color: rgba(192, 192, 192, 0.9);
                    transition: all 0.4s ease;
                    backdrop-filter: blur(1px);
                    position: relative;
                }

                .goop-field:focus {
                    outline: none;
                    border-color: rgba(192, 192, 192, 0.6);
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.05) 0%,
                        transparent 70%);
                    box-shadow: 0 0 0 1px rgba(192, 192, 192, 0.1),
                                inset 0 0 20px rgba(192, 192, 192, 0.02);
                    color: rgba(255, 255, 255, 0.95);
                }

                .goop-field::placeholder {
                    color: rgba(192, 192, 192, 0.4);
                    font-style: italic;
                }

                /* Send button effects */
                .transmit-button {
                    background: linear-gradient(135deg,
                        rgba(192, 192, 192, 0.05) 0%,
                        rgba(64, 64, 64, 0.1) 50%,
                        rgba(0, 0, 0, 0.05) 100%) !important;
                }

                .transmit-button::before {
                    content: '';
                    position: absolute;
                    top: 0;
                    left: -100%;
                    width: 100%;
                    height: 100%;
                    background: linear-gradient(90deg,
                        transparent 0%,
                        rgba(192, 192, 192, 0.2) 50%,
                        transparent 100%);
                    transition: left 0.6s ease;
                }

                .transmit-button:hover::before {
                    left: 100%;
                }

                .transmit-button:hover {
                    border-color: rgba(192, 192, 192, 0.8) !important;
                    color: rgba(255, 255, 255, 0.95) !important;
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.15) 0%,
                        rgba(64, 64, 64, 0.1) 70%,
                        transparent 100%) !important;
                    box-shadow: 0 0 20px rgba(192, 192, 192, 0.2),
                                inset 0 0 15px rgba(192, 192, 192, 0.05);
                    text-shadow: 0 0 8px rgba(192, 192, 192, 0.3);
                    transform: translateY(-1px);
                }

                /* Form labels */
                .goop-label {
                    color: rgba(192, 192, 192, 0.7) !important;
                    font-size: 10px !important;
                    letter-spacing: 0.1em;
                    text-transform: uppercase;
                    margin-bottom: 6px;
                    display: block;
                    position: relative;
                }

                .goop-label::after {
                    content: '';
                    position: absolute;
                    bottom: -2px;
                    left: 0;
                    width: 16px;
                    height: 1px;
                    background: rgba(192, 192, 192, 0.3);
                }

                /* Breathing animation */
                .transmission-interface {
                    animation: interface-breathe 6s ease-in-out infinite;
                }

                @keyframes interface-breathe {
                    0%, 100% { opacity: 0.95; }
                    50% { opacity: 1; }
                }

                /* Transition utility for Tachyons */
                .transition-all {
                    transition: all 0.4s ease;
                }
            """ ]
        ]



-- Contact node with Tachyons


goopContactNode : String -> String -> String -> String -> Html ContactMsg
goopContactNode title value link nodeId =
    a
        [ Attr.href link
        , Attr.class "db pa3 ph4 no-underline color-inherit tc goop-node"
        , Attr.style "min-width" "120px"
        , Attr.id nodeId
        ]
        [ -- Title
          h3
            [ Attr.class "f7 mb2 tracked normal ttu"
            , Attr.style "color" "rgba(192, 192, 192, 0.8)"
            ]
            [ text title ]

        -- Value
        , p
            [ Attr.class "f6 ma0 fw5"
            , Attr.style "color" "rgba(192, 192, 192, 0.9)"
            ]
            [ text value ]
        ]



-- Form field with click event blocking


goopFormField : String -> String -> String -> String -> Html ContactMsg
goopFormField labelText inputType placeholder fieldId =
    div
        [ Attr.class "mb3"
        , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
        ]
        [ label
            [ Attr.class "goop-label"
            , Attr.for fieldId
            ]
            [ text labelText ]
        , input
            [ Attr.type_ inputType
            , Attr.placeholder placeholder
            , Attr.id fieldId
            , Attr.class "w-100 pa3 monospace f6 goop-field"
            , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
            , stopPropagationOn "focus" (Decode.succeed ( NoOp, True ))
            ]
            []
        ]



-- Textarea with click event blocking


goopTextArea : String -> String -> String -> Html ContactMsg
goopTextArea labelText placeholder fieldId =
    div
        [ Attr.class "mb3"
        , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
        ]
        [ label
            [ Attr.class "goop-label"
            , Attr.for fieldId
            ]
            [ text labelText ]
        , textarea
            [ Attr.placeholder placeholder
            , Attr.id fieldId
            , Attr.rows 3
            , Attr.class "w-100 pa3 monospace f6 goop-field"
            , Attr.style "resize" "vertical"
            , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
            , stopPropagationOn "focus" (Decode.succeed ( NoOp, True ))
            ]
            []
        ]
