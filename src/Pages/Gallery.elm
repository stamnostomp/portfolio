module Pages.Gallery exposing (view)

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onFocus, onInput, stopPropagationOn)
import Json.Decode as Decode


-- Gallery page showcasing visual works and projects
-- Define a message type for internal use


type GalleryMsg
    = NoOp
    | ViewImage String


view : Html GalleryMsg
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
            , Attr.style "margin" "1.5rem 3rem 0.5rem 3rem"
            , Attr.style "max-width" "90%"
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
                    [ text "GALLERY" ]

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
                ]
                [ text "✕ CLOSE" ]
            ]

        -- Main gallery container with scroll
        , div
            [ Attr.class "w-100 relative custom-scroll-container"
            , Attr.style "height" "calc(100vh - 140px)"
            , Attr.style "max-height" "620px"
            , Attr.style "margin" "0 3rem 0.5rem 3rem"
            , Attr.style "max-width" "90%"
            ]
            [ -- Top fade overlay
              div
                [ Attr.class "dn absolute top-0 left-0 right-0 z-2 pointer-events-none fade-overlay-top" ]
                []

            -- Scrollable gallery content
            , div
                [ Attr.class "custom-scroll-content transmission-interface"
                , Attr.style "height" "100%"
                , Attr.style "overflow-y" "auto"
                , Attr.style "overflow-x" "hidden"
                , Attr.style "padding" "1rem"
                , Attr.style "padding-right" "2rem"
                , Attr.style "margin-right" "-1rem"
                ]
                [ -- Interactive image gallery grid with water-drop hover effects
                  div
                    [ Attr.class "image-gallery" ]
                    [ -- Visual Works as clickable images
                      imageItem "GOOP INTERFACE" "https://stamno.com/projects/goop-interface" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23111'/%3E%3Ccircle cx='150' cy='100' r='60' fill='none' stroke='%23c0c0c0' stroke-width='2' opacity='0.3'/%3E%3Cpath d='M120 80 Q150 60 180 80 Q170 100 180 120 Q150 140 120 120 Q130 100 120 80' fill='%23606060' opacity='0.5'/%3E%3Ctext x='150' y='170' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3EGOOP INTERFACE%3C/text%3E%3C/svg%3E"

                    , imageItem "Y2K AESTHETICS" "https://stamno.com/projects/y2k-design" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23000'/%3E%3Cg transform='translate(150,100)'%3E%3Crect x='-80' y='-50' width='160' height='100' fill='url(%23chrome)' rx='10'/%3E%3C/g%3E%3Cdefs%3E%3ClinearGradient id='chrome' x1='0' y1='0' x2='1' y2='1'%3E%3Cstop offset='0%25' stop-color='%23c0c0c0'/%3E%3Cstop offset='50%25' stop-color='%23808080'/%3E%3Cstop offset='100%25' stop-color='%23404040'/%3E%3C/linearGradient%3E%3C/defs%3E%3Ctext x='150' y='170' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3EY2K AESTHETICS%3C/text%3E%3C/svg%3E"

                    , imageItem "SHADER ART" "https://stamno.com/projects/shaders" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23111'/%3E%3Cg%3E%3Cpath d='M50 50 Q150 30 250 50 Q230 100 250 150 Q150 170 50 150 Q70 100 50 50' fill='url(%23gradient1)' opacity='0.7'/%3E%3Cpath d='M80 80 Q150 60 220 80 Q200 100 220 120 Q150 140 80 120 Q100 100 80 80' fill='url(%23gradient2)' opacity='0.5'/%3E%3C/g%3E%3Cdefs%3E%3CradialGradient id='gradient1'%3E%3Cstop offset='0%25' stop-color='%23c0c0c0'/%3E%3Cstop offset='100%25' stop-color='%23404040'/%3E%3C/radialGradient%3E%3CradialGradient id='gradient2'%3E%3Cstop offset='0%25' stop-color='%23808080'/%3E%3Cstop offset='100%25' stop-color='%23202020'/%3E%3C/radialGradient%3E%3C/defs%3E%3Ctext x='150' y='170' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3ESHADER ART%3C/text%3E%3C/svg%3E"

                    , imageItem "TERMINAL UI" "https://stamno.com/projects/terminal" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23000'/%3E%3Crect x='20' y='30' width='260' height='140' fill='%23111' stroke='%23c0c0c0' stroke-width='1'/%3E%3Ctext x='30' y='50' fill='%23c0c0c0' font-size='10' font-family='monospace'%3E%3E stamno@dev:~%24%3C/text%3E%3Ctext x='30' y='70' fill='%23808080' font-size='10' font-family='monospace'%3E%3E ls -la%3C/text%3E%3Ctext x='30' y='90' fill='%23808080' font-size='10' font-family='monospace'%3E%3E ./run-server%3C/text%3E%3Crect x='30' y='100' width='6' height='12' fill='%23c0c0c0'/%3E%3Ctext x='150' y='190' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3ETERMINAL UI%3C/text%3E%3C/svg%3E"

                    , imageItem "PARTICLE SYS" "https://stamno.com/projects/particles" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23111'/%3E%3Cg%3E%3Ccircle cx='150' cy='100' r='3' fill='%23c0c0c0'/%3E%3Ccircle cx='130' cy='80' r='2' fill='%23a0a0a0'/%3E%3Ccircle cx='170' cy='90' r='2' fill='%23a0a0a0'/%3E%3Ccircle cx='140' cy='120' r='2' fill='%23808080'/%3E%3Ccircle cx='180' cy='110' r='2' fill='%23808080'/%3E%3Ccircle cx='120' cy='100' r='1' fill='%23606060'/%3E%3Ccircle cx='160' cy='70' r='1' fill='%23606060'/%3E%3Ccircle cx='190' cy='130' r='1' fill='%23606060'/%3E%3Cpath d='M150 100 L130 80 M150 100 L170 90 M150 100 L140 120' stroke='%23404040' stroke-width='1' opacity='0.3'/%3E%3C/g%3E%3Ctext x='150' y='180' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3EPARTICLE SYS%3C/text%3E%3C/svg%3E"

                    , imageItem "CYBERPUNK UI" "https://stamno.com/projects/cyberpunk" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23000'/%3E%3Cpolygon points='50,60 100,50 150,60 200,50 250,60 250,80 200,70 150,80 100,70 50,80' fill='%23404040' stroke='%23c0c0c0' stroke-width='1'/%3E%3Cpolygon points='60,100 120,90 180,100 240,90 240,110 180,120 120,110 60,120' fill='%23606060' stroke='%23c0c0c0' stroke-width='1'/%3E%3Cpolygon points='70,140 130,130 170,140 230,130 230,150 170,160 130,150 70,160' fill='%23404040' stroke='%23c0c0c0' stroke-width='1'/%3E%3Ctext x='150' y='180' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3ECYBERPUNK UI%3C/text%3E%3C/svg%3E"

                    , imageItem "DATA VIZ" "https://stamno.com/projects/dataviz" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23111'/%3E%3Cg%3E%3Cpath d='M50 150 L80 120 L110 130 L140 90 L170 100 L200 70 L230 80 L250 50' stroke='%23c0c0c0' stroke-width='2' fill='none'/%3E%3Cpath d='M50 150 L80 120 L110 130 L140 90 L170 100 L200 70 L230 80 L250 50 L250 150 L50 150' fill='url(%23chartGrad)' opacity='0.3'/%3E%3C/g%3E%3Cg%3E%3Crect x='50' y='160' width='15' height='20' fill='%23808080'/%3E%3Crect x='80' y='155' width='15' height='25' fill='%23a0a0a0'/%3E%3Crect x='110' y='150' width='15' height='30' fill='%23808080'/%3E%3Crect x='140' y='145' width='15' height='35' fill='%23c0c0c0'/%3E%3C/g%3E%3Cdefs%3E%3ClinearGradient id='chartGrad' x1='0' y1='0' x2='0' y2='1'%3E%3Cstop offset='0%25' stop-color='%23c0c0c0'/%3E%3Cstop offset='100%25' stop-color='%23404040'/%3E%3C/linearGradient%3E%3C/defs%3E%3Ctext x='150' y='195' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3EDATA VIZ%3C/text%3E%3C/svg%3E"

                    , imageItem "GENERATIVE" "https://stamno.com/projects/generative" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23111'/%3E%3Cg transform='translate(150,100)'%3E%3Cpath d='M-60,-40 Q0,-60 60,-40 Q40,0 60,40 Q0,60 -60,40 Q-40,0 -60,-40' fill='none' stroke='%23c0c0c0' stroke-width='1'/%3E%3Cpath d='M-40,-30 Q0,-45 40,-30 Q30,0 40,30 Q0,45 -40,30 Q-30,0 -40,-30' fill='none' stroke='%23808080' stroke-width='1'/%3E%3Cpath d='M-20,-15 Q0,-25 20,-15 Q15,0 20,15 Q0,25 -20,15 Q-15,0 -20,-15' fill='none' stroke='%23606060' stroke-width='1'/%3E%3C/g%3E%3Ctext x='150' y='180' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3EGENERATIVE%3C/text%3E%3C/svg%3E"

                    , imageItem "CHROME STUDY" "https://stamno.com/projects/chrome" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 200 200'%3E%3Crect width='300' height='200' fill='%23000'/%3E%3Cellipse cx='150' cy='100' rx='80' ry='50' fill='url(%23chromeGrad)' stroke='%23c0c0c0' stroke-width='2'/%3E%3Cellipse cx='150' cy='100' rx='60' ry='35' fill='url(%23chromeGrad2)' opacity='0.7'/%3E%3Cellipse cx='150' cy='100' rx='40' ry='20' fill='url(%23chromeGrad3)' opacity='0.5'/%3E%3Cdefs%3E%3ClinearGradient id='chromeGrad' x1='0' y1='0' x2='1' y2='1'%3E%3Cstop offset='0%25' stop-color='%23e0e0e0'/%3E%3Cstop offset='30%25' stop-color='%23c0c0c0'/%3E%3Cstop offset='70%25' stop-color='%23808080'/%3E%3Cstop offset='100%25' stop-color='%23404040'/%3E%3C/linearGradient%3E%3ClinearGradient id='chromeGrad2' x1='0' y1='0' x2='1' y2='1'%3E%3Cstop offset='0%25' stop-color='%23ffffff'/%3E%3Cstop offset='100%25' stop-color='%23808080'/%3E%3C/linearGradient%3E%3ClinearGradient id='chromeGrad3' x1='0' y1='0' x2='1' y2='1'%3E%3Cstop offset='0%25' stop-color='%23ffffff'/%3E%3Cstop offset='100%25' stop-color='%23c0c0c0'/%3E%3C/linearGradient%3E%3C/defs%3E%3Ctext x='150' y='180' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3ECHROME STUDY%3C/text%3E%3C/svg%3E"

                    , imageItem "GLITCH FX" "https://stamno.com/projects/glitch" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23000'/%3E%3Cg%3E%3Crect x='50' y='60' width='200' height='20' fill='%23c0c0c0'/%3E%3Crect x='52' y='62' width='196' height='16' fill='%23000'/%3E%3Crect x='70' y='90' width='180' height='15' fill='%23808080'/%3E%3Crect x='72' y='92' width='176' height='11' fill='%23000'/%3E%3Crect x='60' y='115' width='190' height='18' fill='%23a0a0a0'/%3E%3Crect x='62' y='117' width='186' height='14' fill='%23000'/%3E%3Cpath d='M50 60 L60 62 M250 60 L240 62 M70 90 L80 92 M250 90 L240 92' stroke='%23404040' stroke-width='1'/%3E%3C/g%3E%3Ctext x='150' y='180' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3EGLITCH FX%3C/text%3E%3C/svg%3E"

                    , imageItem "GRID SYSTEMS" "https://stamno.com/projects/grids" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23111'/%3E%3Cg stroke='%23c0c0c0' stroke-width='1' fill='none'%3E%3Crect x='50' y='50' width='40' height='30'/%3E%3Crect x='100' y='50' width='40' height='30'/%3E%3Crect x='150' y='50' width='40' height='30'/%3E%3Crect x='200' y='50' width='40' height='30'/%3E%3Crect x='50' y='90' width='40' height='30'/%3E%3Crect x='100' y='90' width='40' height='30'/%3E%3Crect x='150' y='90' width='40' height='30'/%3E%3Crect x='200' y='90' width='40' height='30'/%3E%3Crect x='50' y='130' width='40' height='30'/%3E%3Crect x='100' y='130' width='40' height='30'/%3E%3Crect x='150' y='130' width='40' height='30'/%3E%3Crect x='200' y='130' width='40' height='30'/%3E%3C/g%3E%3Cg fill='%23404040' opacity='0.3'%3E%3Crect x='100' y='50' width='40' height='30'/%3E%3Crect x='200' y='90' width='40' height='30'/%3E%3Crect x='50' y='130' width='40' height='30'/%3E%3C/g%3E%3Ctext x='150' y='185' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3EGRID SYSTEMS%3C/text%3E%3C/svg%3E"

                    , imageItem "COLOR THEORY" "https://stamno.com/projects/color" "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'%3E%3Crect width='300' height='200' fill='%23111'/%3E%3Cg%3E%3Crect x='50' y='70' width='30' height='60' fill='%23404040'/%3E%3Crect x='90' y='70' width='30' height='60' fill='%23606060'/%3E%3Crect x='130' y='70' width='30' height='60' fill='%23808080'/%3E%3Crect x='170' y='70' width='30' height='60' fill='%23a0a0a0'/%3E%3Crect x='210' y='70' width='30' height='60' fill='%23c0c0c0'/%3E%3C/g%3E%3Ctext x='150' y='155' text-anchor='middle' fill='%23c0c0c0' font-size='12' font-family='monospace'%3ECOLOR THEORY%3C/text%3E%3C/svg%3E"
                    ]
                ]

            -- Bottom fade overlay
            , div
                [ Attr.class "dn absolute bottom-0 left-0 right-0 z-2 pointer-events-none fade-overlay-bottom" ]
                []
            ]

        -- Enhanced CSS with gallery-specific styling and water-drop effect
        , node "style"
            []
            [ text """
                /* Image gallery grid layout with water-drop effect */
                .image-gallery {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
                    gap: 1rem;
                    padding: 1rem 0;
                    position: relative;
                }

                @media (min-width: 768px) {
                    .image-gallery {
                        grid-template-columns: repeat(4, 1fr);
                        gap: 1.25rem;
                    }
                }

                @media (min-width: 1024px) {
                    .image-gallery {
                        grid-template-columns: repeat(5, 1fr);
                        gap: 1.5rem;
                    }
                }

                /* Image items with water-drop hover effect */
                .image-item {
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
                .image-item:nth-child(1) { animation-delay: 0.1s; }
                .image-item:nth-child(2) { animation-delay: 0.15s; }
                .image-item:nth-child(3) { animation-delay: 0.2s; }
                .image-item:nth-child(4) { animation-delay: 0.25s; }
                .image-item:nth-child(5) { animation-delay: 0.3s; }
                .image-item:nth-child(6) { animation-delay: 0.35s; }
                .image-item:nth-child(7) { animation-delay: 0.4s; }
                .image-item:nth-child(8) { animation-delay: 0.45s; }
                .image-item:nth-child(9) { animation-delay: 0.5s; }
                .image-item:nth-child(10) { animation-delay: 0.55s; }
                .image-item:nth-child(11) { animation-delay: 0.6s; }
                .image-item:nth-child(12) { animation-delay: 0.65s; }

                /* Water-drop hover effect - grows and pushes others */
                .image-item:hover {
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
                .image-gallery:hover .image-item:not(:hover) {
                    transform: scale(0.95);
                    opacity: 0.8;
                    filter: blur(1px);
                }

                /* Enhanced ripple for immediate neighbors */
                .image-item:hover + .image-item,
                .image-item:has(+ .image-item:hover) {
                    transform: scale(0.9) !important;
                    opacity: 0.6 !important;
                }

                .image-item:hover * {
                    color: rgba(255, 255, 255, 0.95) !important;
                }

                /* Remove link styling */
                .image-item, .image-item:visited, .image-item:active, .image-item:focus {
                    text-decoration: none !important;
                    color: inherit !important;
                    outline: none;
                }

                /* Image container styling */
                .image-container img {
                    border-radius: 4px;
                    transition: all 0.3s ease;
                }

                .image-item:hover .image-container img {
                    opacity: 1 !important;
                    transform: scale(1.05);
                }

                .image-title {
                    transition: all 0.3s ease;
                }

                .image-item:hover .image-title {
                    color: rgba(255, 255, 255, 1) !important;
                    text-shadow: 0 0 10px rgba(192, 192, 192, 0.3);
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
                .gap1 { gap: 0.25rem; }
            """ ]
        ]



-- View mode indicator component


viewModeIndicator : String -> String -> Bool -> Html GalleryMsg
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



-- Image item component with click-through to project homepage


imageItem : String -> String -> String -> Html GalleryMsg
imageItem title projectUrl imageSrc =
    a
        [ Attr.class "image-item"
        , Attr.href projectUrl
        , Attr.target "_blank"
        , Attr.attribute "data-title" title
        , stopPropagationOn "click" (Decode.succeed ( ViewImage title, True ))
        ]
        [ -- Image container
          div
            [ Attr.class "image-container"
            , Attr.style "width" "100%"
            , Attr.style "height" "60%"
            , Attr.style "display" "flex"
            , Attr.style "align-items" "center"
            , Attr.style "justify-content" "center"
            , Attr.style "margin-bottom" "0.5rem"
            ]
            [ img
                [ Attr.src imageSrc
                , Attr.alt title
                , Attr.style "max-width" "100%"
                , Attr.style "max-height" "100%"
                , Attr.style "object-fit" "contain"
                , Attr.style "opacity" "0.8"
                , Attr.style "transition" "opacity 0.3s ease"
                ]
                []
            ]

        -- Title
        , div
            [ Attr.class "image-title"
            , Attr.style "color" "rgba(255, 255, 255, 0.9)"
            , Attr.style "font-size" "11px"
            , Attr.style "letter-spacing" "0.05em"
            , Attr.style "text-transform" "uppercase"
            , Attr.style "font-weight" "600"
            , Attr.style "text-align" "center"
            , Attr.style "line-height" "1.2"
            ]
            [ text title ]
        ]