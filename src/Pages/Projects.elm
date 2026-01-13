module Pages.Projects exposing (view)

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onFocus, onInput, stopPropagationOn)
import Json.Decode as Decode


-- Projects page with detailed technical project showcase
-- Define a message type for internal use


type ProjectMsg
    = NoOp
    | ViewDemo String
    | ViewCode String


view : Html ProjectMsg
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
            [ -- Left side: Title and status indicators
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
                    [ text "PROJECTS" ]

                -- Status indicators
                , div [ Attr.class "flex gap1" ]
                    [ statusIndicator "LIVE" "status-live" True
                    , statusIndicator "GITHUB" "status-github" False
                    , statusIndicator "FEATURED" "status-featured" False
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

        -- Main projects container with scroll
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

            -- Scrollable projects content
            , div
                [ Attr.class "custom-scroll-content transmission-interface"
                , Attr.style "height" "100%"
                , Attr.style "overflow-y" "auto"
                , Attr.style "overflow-x" "hidden"
                , Attr.style "padding" "1rem"
                , Attr.style "padding-right" "2rem"
                , Attr.style "margin-right" "-1rem"
                ]
                [ -- Projects list
                  div
                    [ Attr.class "projects-container" ]
                    [ projectItem
                        "GOOP NAVIGATION SYSTEM"
                        "Real-time WebGL fluid interface with organic morphing and interactive particle physics"
                        [ ( "Frontend", "Elm + WebGL" )
                        , ( "Shaders", "GLSL Fragment/Vertex" )
                        , ( "Math", "Vector Physics, Bezier Curves" )
                        , ( "Performance", "60fps @ 4K Resolution" )
                        ]
                        "https://stamno.com"
                        "https://github.com/stamno/goop-nav"
                        "2024-2025"
                        "live"
                        "This project represents 6+ months of intensive WebGL development, combining advanced shader programming with functional reactive programming in Elm. The organic navigation system uses real-time physics calculations to create fluid, responsive interactions that feel natural and intuitive."

                    , projectItem
                        "Y2K RETRO TERMINAL FRAMEWORK"
                        "Full-stack terminal aesthetic framework with authentic CRT effects and command interfaces"
                        [ ( "Backend", "Node.js + WebSocket" )
                        , ( "Frontend", "React + Canvas API" )
                        , ( "Effects", "CRT Scanlines, Text Rendering" )
                        , ( "Architecture", "Component Library" )
                        ]
                        "https://demo.y2k-terminal.dev"
                        "https://github.com/stamno/y2k-terminal"
                        "2024"
                        "github"
                        "A comprehensive framework for building retro terminal interfaces with authentic Y2K aesthetics. Features real-time command processing, customizable CRT effects, and a complete component library for rapid development of nostalgic user interfaces."

                    , projectItem
                        "DISTRIBUTED TASK ORCHESTRATOR"
                        "High-performance distributed computing system for parallel task execution and data processing"
                        [ ( "Backend", "Go + gRPC" )
                        , ( "Database", "PostgreSQL + Redis" )
                        , ( "Infrastructure", "Docker + Kubernetes" )
                        , ( "Monitoring", "Prometheus + Grafana" )
                        ]
                        ""
                        "https://github.com/stamno/task-orchestrator"
                        "2023-2024"
                        "github"
                        "Enterprise-grade distributed system handling 10,000+ concurrent tasks across multiple nodes. Built with Go for performance, featuring automatic failover, load balancing, and comprehensive monitoring. Used in production by several fintech companies."

                    , projectItem
                        "NEURAL PATTERN VISUALIZER"
                        "Interactive machine learning visualization tool for neural network analysis and debugging"
                        [ ( "ML Framework", "TensorFlow.js" )
                        , ( "Visualization", "D3.js + WebGL" )
                        , ( "Data Processing", "Python + FastAPI" )
                        , ( "Real-time", "WebSocket Updates" )
                        ]
                        "https://neural-viz.stamno.com"
                        "https://github.com/stamno/neural-visualizer"
                        "2023"
                        "live"
                        "Advanced visualization tool for understanding neural network behavior in real-time. Features interactive layer exploration, gradient flow visualization, and performance profiling. Helped debug training issues in several research projects."

                    , projectItem
                        "BLOCKCHAIN ANALYTICS PLATFORM"
                        "Real-time cryptocurrency analysis platform with advanced charting and portfolio tracking"
                        [ ( "Data Pipeline", "Apache Kafka + Spark" )
                        , ( "API", "GraphQL + TypeScript" )
                        , ( "Charts", "Custom WebGL Renderer" )
                        , ( "Real-time", "WebSocket Feeds" )
                        ]
                        ""
                        "https://github.com/stamno/crypto-analytics"
                        "2022-2023"
                        "featured"
                        "Comprehensive cryptocurrency analytics platform processing 1M+ transactions daily. Features custom high-performance charting engine, portfolio optimization algorithms, and real-time market analysis. Built scalable architecture handling petabytes of historical data."

                    , projectItem
                        "COLLABORATIVE CODE EDITOR"
                        "Real-time collaborative IDE with integrated version control and project management"
                        [ ( "Backend", "Rust + WebRTC" )
                        , ( "Frontend", "Vue.js + Monaco Editor" )
                        , ( "Collaboration", "CRDT + Operational Transform" )
                        , ( "Version Control", "Custom Git Integration" )
                        ]
                        "https://code.stamno.dev"
                        "https://github.com/stamno/collaborative-editor"
                        "2022"
                        "live"
                        "Real-time collaborative code editor supporting multiple programming languages with integrated project management. Features conflict-free collaborative editing, live code execution, and seamless version control integration."
                    ]
                ]

            -- Bottom fade overlay
            , div
                [ Attr.class "absolute bottom-0 left-0 right-0 z-2 pointer-events-none fade-overlay-bottom" ]
                []
            ]

        -- Enhanced CSS with projects-specific styling
        , node "style"
            []
            [ text """
                /* Projects container layout */
                .projects-container {
                    display: flex;
                    flex-direction: column;
                    gap: 2rem;
                    padding-bottom: 2rem;
                }

                /* Project items */
                .project-item {
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
                    padding: 1.5rem;
                    border-radius: 4px;
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
                .project-item:nth-child(1) { animation-delay: 0.1s; }
                .project-item:nth-child(2) { animation-delay: 0.2s; }
                .project-item:nth-child(3) { animation-delay: 0.3s; }
                .project-item:nth-child(4) { animation-delay: 0.4s; }
                .project-item:nth-child(5) { animation-delay: 0.5s; }
                .project-item:nth-child(6) { animation-delay: 0.6s; }

                /* Project hover effects */
                .project-item:hover {
                    transform: translateY(-4px);
                    border-color: rgba(192, 192, 192, 0.4);
                    background: radial-gradient(ellipse at top left,
                        rgba(192, 192, 192, 0.12) 0%,
                        rgba(64, 64, 64, 0.08) 40%,
                        rgba(0, 0, 0, 0.05) 100%);
                    box-shadow:
                        0 8px 24px rgba(0, 0, 0, 0.3),
                        0 0 30px rgba(192, 192, 192, 0.1);
                }

                .project-item:hover * {
                    color: rgba(255, 255, 255, 0.95) !important;
                }

                /* Project content styling */
                .project-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: flex-start;
                    margin-bottom: 1rem;
                }

                .project-title {
                    color: rgba(255, 255, 255, 0.9) !important;
                    font-size: 16px !important;
                    letter-spacing: 0.05em;
                    text-transform: uppercase;
                    margin-bottom: 0.5rem;
                    font-weight: 600;
                    line-height: 1.2;
                }

                .project-year {
                    color: rgba(192, 192, 192, 0.6) !important;
                    font-size: 11px !important;
                    letter-spacing: 0.1em;
                    text-transform: uppercase;
                    font-family: monospace;
                }

                .project-subtitle {
                    color: rgba(192, 192, 192, 0.8) !important;
                    font-size: 14px;
                    line-height: 1.4;
                    margin-bottom: 1rem;
                    font-style: italic;
                }

                .project-description {
                    color: rgba(192, 192, 192, 0.85) !important;
                    line-height: 1.5;
                    margin-bottom: 1.5rem;
                    font-size: 13px;
                }

                .project-tech {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
                    gap: 0.5rem;
                    margin-bottom: 1.5rem;
                }

                .tech-item {
                    display: flex;
                    justify-content: space-between;
                    padding: 0.25rem 0;
                    border-bottom: 1px solid rgba(192, 192, 192, 0.1);
                }

                .tech-label {
                    color: rgba(192, 192, 192, 0.7);
                    font-size: 11px;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                }

                .tech-value {
                    color: rgba(255, 255, 255, 0.85);
                    font-size: 11px;
                    font-weight: 500;
                }

                .project-links {
                    display: flex;
                    gap: 1rem;
                    margin-top: auto;
                }

                .project-link {
                    background: rgba(192, 192, 192, 0.1);
                    border: 1px solid rgba(192, 192, 192, 0.2);
                    color: rgba(192, 192, 192, 0.8);
                    padding: 0.5rem 1rem;
                    font-size: 10px;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                    transition: all 0.3s ease;
                    text-decoration: none;
                    cursor: pointer;
                }

                .project-link:hover {
                    background: rgba(192, 192, 192, 0.2);
                    color: rgba(255, 255, 255, 0.95);
                    border-color: rgba(192, 192, 192, 0.4);
                    transform: translateY(-1px);
                }

                .project-link.disabled {
                    opacity: 0.4;
                    cursor: not-allowed;
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

                /* Active state - matches blog and links pages */
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

                /* Tachyons gap utilities */
                .gap2 { gap: 0.5rem; }
                .gap1 { gap: 0.75rem; }
            """ ]
        ]



-- Status indicator component


statusIndicator : String -> String -> Bool -> Html ProjectMsg
statusIndicator title nodeId isActive =
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



-- Project item component


projectItem : String -> String -> List ( String, String ) -> String -> String -> String -> String -> String -> Html ProjectMsg
projectItem title subtitle techSpecs demoUrl repoUrl year status description =
    div
        [ Attr.class "project-item"
        , Attr.attribute "data-status" status
        ]
        [ -- Project header
          div
            [ Attr.class "project-header" ]
            [ div []
                [ h3
                    [ Attr.class "project-title" ]
                    [ text title ]
                , div
                    [ Attr.class "project-year" ]
                    [ text year ]
                ]
            ]

        -- Subtitle
        , div
            [ Attr.class "project-subtitle" ]
            [ text subtitle ]

        -- Description
        , p
            [ Attr.class "project-description" ]
            [ text description ]

        -- Technical specifications
        , div
            [ Attr.class "project-tech" ]
            (List.map techSpecItem techSpecs)

        -- Action links
        , div
            [ Attr.class "project-links" ]
            [ if String.isEmpty demoUrl then
                span
                    [ Attr.class "project-link disabled" ]
                    [ text "Live Demo" ]

              else
                a
                    [ Attr.class "project-link"
                    , Attr.href demoUrl
                    , Attr.target "_blank"
                    , stopPropagationOn "click" (Decode.succeed ( ViewDemo demoUrl, True ))
                    ]
                    [ text "Live Demo" ]
            , if String.isEmpty repoUrl then
                span
                    [ Attr.class "project-link disabled" ]
                    [ text "Source Code" ]

              else
                a
                    [ Attr.class "project-link"
                    , Attr.href repoUrl
                    , Attr.target "_blank"
                    , stopPropagationOn "click" (Decode.succeed ( ViewCode repoUrl, True ))
                    ]
                    [ text "Source Code" ]
            ]
        ]



-- Technical specification item component


techSpecItem : ( String, String ) -> Html ProjectMsg
techSpecItem ( label, value ) =
    div
        [ Attr.class "tech-item" ]
        [ span
            [ Attr.class "tech-label" ]
            [ text label ]
        , span
            [ Attr.class "tech-value" ]
            [ text value ]
        ]