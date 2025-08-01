module Pages.Portfolio exposing (view)

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onFocus, onInput, stopPropagationOn)
import Json.Decode as Decode



-- Portfolio page with visual showcase grid and preview modals
-- Define a message type for internal use


type PortfolioMsg
    = NoOp
    | SelectProject String


view : Html PortfolioMsg
view =
    div
        [ Attr.class "h-100 w-100 flex flex-column monospace bg-transparent relative"
        ]
        [ -- Header with title and filter nodes
          div
            [ Attr.class "flex justify-between items-center pa1 ph2"
            , Attr.style "background" "rgba(0, 0, 0, 0.2)"
            , Attr.style "backdrop-filter" "blur(4px)"
            , Attr.style "border-bottom" "1px solid rgba(192, 192, 192, 0.1)"
            , Attr.style "margin" "1.5rem 3rem 0.5rem 3rem"
            , Attr.style "max-width" "90%"
            ]
            [ -- Left side: Title and filter nodes
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
                    [ text "PORTFOLIO" ]

                -- Filter category nodes
                , div [ Attr.class "flex gap1" ]
                    [ goopFilterNode "ALL" "filter-all" True
                    , goopFilterNode "WEBGL" "filter-webgl" False
                    , goopFilterNode "UI/UX" "filter-ui" False
                    , goopFilterNode "APPS" "filter-apps" False
                    ]
                ]

            -- Right side: Close button
            , button
                [ Attr.class "bg-transparent pa1 ph2 f8 fw6 monospace tracked pointer relative overflow-hidden ttu goop-close-button"
                , Attr.style "min-width" "50px"
                , Attr.style "height" "24px"
                ]
                [ text "✕ CLOSE" ]
            ]

        -- Main portfolio grid with scroll
        , div
            [ Attr.class "w-100 relative custom-scroll-container"
            , Attr.style "height" "calc(100vh - 140px)"
            , Attr.style "max-height" "620px"
            , Attr.style "margin" "0 3rem 0.5rem 3rem"
            , Attr.style "max-width" "90%"
            ]
            [ -- Top fade overlay
              div
                [ Attr.class "absolute top-0 left-0 right-0 z-2 pointer-events-none fade-overlay-top" ]
                []

            -- Scrollable portfolio grid
            , div
                [ Attr.class "custom-scroll-content transmission-interface"
                , Attr.style "height" "100%"
                , Attr.style "overflow-y" "auto"
                , Attr.style "overflow-x" "hidden"
                , Attr.style "padding" "1rem"
                , Attr.style "padding-right" "2rem"
                , Attr.style "margin-right" "-1rem"
                ]
                [ -- Portfolio grid
                  div
                    [ Attr.class "portfolio-grid" ]
                    [ -- Row 1
                      portfolioItem
                        "GOOP NAVIGATION SYSTEM"
                        "WebGL + Elm organic interface with real-time shader morphing"
                        "2025"
                        "webgl"
                        [ "WebGL", "Elm", "Shaders", "UI/UX" ]
                        ""
                    , portfolioItem
                        "Y2K RETRO DASHBOARD"
                        "Interactive dashboard with chrome effects and animated graphs"
                        "2025"
                        "ui"
                        [ "React", "D3.js", "CSS3", "Design" ]
                        ""
                    , portfolioItem
                        "FLUID PARTICLE SYSTEM"
                        "Real-time particle physics simulation with WebGL compute shaders"
                        "2024"
                        "webgl"
                        [ "WebGL", "Physics", "Shaders" ]
                        ""

                    -- Row 2
                    , portfolioItem
                        "ORGANIC FORM GENERATOR"
                        "Procedural 3D form generation tool for creative applications"
                        "2024"
                        "webgl"
                        [ "Three.js", "WebGL", "Generative" ]
                        ""
                    , portfolioItem
                        "CYBERPUNK CHAT APP"
                        "Real-time messaging with terminal-style interface design"
                        "2024"
                        "apps"
                        [ "Node.js", "Socket.io", "UI/UX" ]
                        ""
                    , portfolioItem
                        "HOLOGRAPHIC MENU SYSTEM"
                        "3D holographic navigation with gesture controls and haptic feedback"
                        "2024"
                        "ui"
                        [ "Three.js", "WebXR", "Gestures" ]
                        ""

                    -- Row 3
                    , portfolioItem
                        "NEON VISUALIZATION SUITE"
                        "Data visualization toolkit with neon aesthetics and smooth animations"
                        "2023"
                        "ui"
                        [ "D3.js", "Canvas", "Animations" ]
                        ""
                    , portfolioItem
                        "REACTIVE AUDIO VISUALIZER"
                        "Real-time audio analysis with WebGL reactive visuals"
                        "2023"
                        "webgl"
                        [ "Web Audio", "WebGL", "FFT" ]
                        ""
                    , portfolioItem
                        "CHROME INTERFACE TOOLKIT"
                        "Complete UI component library with metallic Y2K styling"
                        "2023"
                        "ui"
                        [ "React", "Styled Components", "Design System" ]
                        ""
                    ]
                ]

            -- Bottom fade overlay
            , div
                [ Attr.class "absolute bottom-0 left-0 right-0 z-2 pointer-events-none fade-overlay-bottom" ]
                []
            ]

        -- Enhanced CSS with portfolio-specific styling
        , node "style"
            []
            [ text """
                /* Portfolio grid layout */
                .portfolio-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
                    gap: 1rem;
                    padding-bottom: 1rem;
                }

                /* Responsive adjustments */
                @media (max-width: 800px) {
                    .portfolio-grid {
                        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                        gap: 1rem;
                    }
                }

                /* Portfolio items */
                .portfolio-item {
                    background: radial-gradient(ellipse at top left,
                        rgba(192, 192, 192, 0.08) 0%,
                        rgba(64, 64, 64, 0.05) 40%,
                        rgba(0, 0, 0, 0.1) 100%);
                    border: 1px solid rgba(192, 192, 192, 0.15);
                    backdrop-filter: blur(3px);
                    transition: all 0.5s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    position: relative;
                    overflow: hidden;
                    cursor: pointer;
                    animation: item-fade-in 0.8s ease-out forwards;
                    opacity: 0;
                }

                @keyframes item-fade-in {
                    from {
                        opacity: 0;
                        transform: translateY(20px) scale(0.95);
                    }
                    to {
                        opacity: 1;
                        transform: translateY(0) scale(1);
                    }
                }

                /* Staggered animation delays */
                .portfolio-item:nth-child(1) { animation-delay: 0.1s; }
                .portfolio-item:nth-child(2) { animation-delay: 0.2s; }
                .portfolio-item:nth-child(3) { animation-delay: 0.3s; }
                .portfolio-item:nth-child(4) { animation-delay: 0.4s; }
                .portfolio-item:nth-child(5) { animation-delay: 0.5s; }
                .portfolio-item:nth-child(6) { animation-delay: 0.6s; }
                .portfolio-item:nth-child(7) { animation-delay: 0.7s; }
                .portfolio-item:nth-child(8) { animation-delay: 0.8s; }
                .portfolio-item:nth-child(9) { animation-delay: 0.9s; }

                /* Hover effects with organic glow */
                .portfolio-item::before {
                    content: '';
                    position: absolute;
                    top: -50%;
                    left: -50%;
                    width: 200%;
                    height: 200%;
                    background: conic-gradient(
                        from 0deg at 50% 50%,
                        transparent 0deg,
                        rgba(192, 192, 192, 0.1) 45deg,
                        transparent 90deg,
                        rgba(192, 192, 192, 0.05) 135deg,
                        transparent 180deg,
                        rgba(192, 192, 192, 0.05) 225deg,
                        transparent 270deg,
                        rgba(192, 192, 192, 0.1) 315deg,
                        transparent 360deg
                    );
                    animation: item-rotate 12s linear infinite;
                    opacity: 0;
                    transition: opacity 0.5s ease;
                }

                .portfolio-item:hover::before {
                    opacity: 1;
                }

                @keyframes item-rotate {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }

                .portfolio-item:hover {
                    transform: translateY(-8px) scale(1.02);
                    border-color: rgba(192, 192, 192, 0.4);
                    background: radial-gradient(ellipse at top left,
                        rgba(192, 192, 192, 0.15) 0%,
                        rgba(64, 64, 64, 0.1) 40%,
                        rgba(0, 0, 0, 0.05) 100%);
                    box-shadow:
                        0 12px 32px rgba(0, 0, 0, 0.3),
                        0 0 40px rgba(192, 192, 192, 0.1),
                        inset 0 1px 0 rgba(255, 255, 255, 0.1);
                }

                .portfolio-item:hover * {
                    color: rgba(255, 255, 255, 0.95) !important;
                }

                .portfolio-item:hover .portfolio-icon {
                    transform: scale(1.2) rotate(5deg);
                    text-shadow: 0 0 20px rgba(192, 192, 192, 0.6);
                }

                /* Portfolio item content */
                .portfolio-icon {
                    font-size: 2.5rem;
                    margin-bottom: 1rem;
                    transition: all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    display: block;
                    text-align: center;
                    filter: drop-shadow(0 0 10px rgba(192, 192, 192, 0.2));
                }

                .portfolio-title {
                    color: rgba(255, 255, 255, 0.9) !important;
                    font-size: 14px !important;
                    letter-spacing: 0.05em;
                    text-transform: uppercase;
                    margin-bottom: 8px;
                    font-weight: 600;
                    line-height: 1.2;
                    position: relative;
                }

                .portfolio-title::after {
                    content: '';
                    position: absolute;
                    bottom: -4px;
                    left: 0;
                    width: 30px;
                    height: 1px;
                    background: linear-gradient(90deg,
                        rgba(192, 192, 192, 0.6) 0%,
                        transparent 100%);
                }

                .portfolio-year {
                    color: rgba(192, 192, 192, 0.5) !important;
                    font-size: 10px !important;
                    letter-spacing: 0.1em;
                    text-transform: uppercase;
                    margin-bottom: 10px;
                    font-family: monospace;
                }

                .portfolio-description {
                    color: rgba(192, 192, 192, 0.8) !important;
                    line-height: 1.4;
                    margin-bottom: 12px;
                    font-size: 12px;
                }

                .portfolio-tags {
                    display: flex;
                    gap: 4px;
                    flex-wrap: wrap;
                    margin-top: auto;
                }

                .portfolio-tag {
                    background: rgba(192, 192, 192, 0.1);
                    border: 1px solid rgba(192, 192, 192, 0.2);
                    color: rgba(192, 192, 192, 0.7);
                    padding: 2px 6px;
                    font-size: 9px;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                    transition: all 0.3s ease;
                }

                .portfolio-tag:hover {
                    background: rgba(192, 192, 192, 0.2);
                    color: rgba(255, 255, 255, 0.9);
                    border-color: rgba(192, 192, 192, 0.4);
                }

                /* Filter nodes */
                .goop-filter-node {
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.1) 0%,
                        rgba(64, 64, 64, 0.05) 50%,
                        transparent 100%);
                    border: 1px solid rgba(192, 192, 192, 0.15);
                    transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    backdrop-filter: blur(2px);
                    position: relative;
                    overflow: hidden;
                    cursor: pointer;
                }

                .goop-filter-node.active {
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.15) 0%,
                        rgba(64, 64, 64, 0.1) 50%,
                        rgba(0, 0, 0, 0.05) 100%);
                    border-color: rgba(192, 192, 192, 0.4);
                    color: rgba(192, 192, 192, 0.9) !important;
                    box-shadow: 0 0 15px rgba(192, 192, 192, 0.2);
                }

                .goop-filter-node:hover {
                    transform: translateY(-1px) scale(1.05);
                    border-color: rgba(192, 192, 192, 0.4);
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.2) 0%,
                        rgba(64, 64, 64, 0.1) 50%,
                        rgba(0, 0, 0, 0.05) 100%);
                }

                .goop-filter-node:hover * {
                    color: rgba(255, 255, 255, 0.95) !important;
                }

                /* Custom scroll styling - same as other pages */
                .custom-scroll-container {
                    position: relative;
                    border: 1px solid rgba(192, 192, 192, 0.1);
                    background: rgba(0, 0, 0, 0.05);
                    backdrop-filter: blur(2px);
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

                /* Smooth scroll behavior */
                .custom-scroll-content {
                    scroll-behavior: smooth;
                }

                /* Tachyons gap utilities */
                .gap2 { gap: 0.5rem; }
                .gap1 { gap: 0.25rem; }
            """ ]
        ]



-- Filter node component


goopFilterNode : String -> String -> Bool -> Html PortfolioMsg
goopFilterNode title nodeId isActive =
    div
        [ Attr.class
            ("db pa1 ph2 tc goop-filter-node"
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



-- Portfolio item component


portfolioItem : String -> String -> String -> String -> List String -> String -> Html PortfolioMsg
portfolioItem title description year category tags icon =
    div
        [ Attr.class "portfolio-item pa3 h5 flex flex-column"
        , Attr.attribute "data-category" category
        , stopPropagationOn "click" (Decode.succeed ( SelectProject title, True ))
        ]
        [ -- Icon
          span
            [ Attr.class "portfolio-icon" ]
            [ text icon ]

        -- Title
        , h3
            [ Attr.class "portfolio-title" ]
            [ text title ]

        -- Year
        , div
            [ Attr.class "portfolio-year" ]
            [ text year ]

        -- Description
        , p
            [ Attr.class "portfolio-description flex-auto" ]
            [ text description ]

        -- Tags
        , div
            [ Attr.class "portfolio-tags" ]
            (List.map portfolioTag tags)
        ]



-- Portfolio tag component


portfolioTag : String -> Html PortfolioMsg
portfolioTag tag =
    span
        [ Attr.class "portfolio-tag" ]
        [ text tag ]
