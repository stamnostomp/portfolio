module Pages.Blog exposing (view, BlogMsg(..))

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onFocus, onInput, stopPropagationOn)
import Json.Decode as Decode
import Types exposing (BlogTag(..))



-- Blog page with full-screen scrolling interface - FIXED SCROLLING
-- Define a message type for internal use


type BlogMsg
    = NoOp
    | ToggleFilter BlogTag


-- Blog post data structure with categories


type alias BlogPost =
    { title : String
    , date : String
    , content : String
    , tags : List String
    , categories : List BlogTag
    }


-- All blog posts with categorization


allPosts : List BlogPost
allPosts =
    [ { title = "THE ORGANIC WEB: BEYOND STATIC INTERFACES"
      , date = "2025.03.15"
      , content = "Exploring how organic, fluid interfaces can create more intuitive user experiences. This goop navigation system represents a shift away from rigid menu structures toward something more natural and responsive to user interaction. By embracing fluid, organic forms, we can create interfaces that feel more alive and engaging."
      , tags = [ "WebGL", "UI/UX", "Interactive Design" ]
      , categories = [ TechTag, DesignTag ]
      }
    , { title = "SHADER PROGRAMMING FOR CREATIVE CODING"
      , date = "2025.03.10"
      , content = "Diving deep into fragment shaders and how they can be used to create mesmerizing visual effects. From basic color manipulation to complex procedural animations, shaders open up infinite possibilities for web-based art. Understanding the GPU pipeline is key to creating performant visual experiences."
      , tags = [ "WebGL", "Shaders", "Creative Coding" ]
      , categories = [ TechTag ]
      }
    , { title = "FUNCTIONAL REACTIVE PROGRAMMING IN ELM"
      , date = "2025.03.05"
      , content = "Why Elm's architecture makes complex state management feel effortless. Moving from imperative to functional thinking changes how we approach user interfaces and application state. The Elm Architecture provides a robust foundation for building reliable, maintainable applications."
      , tags = [ "Elm", "Functional Programming", "Architecture" ]
      , categories = [ TechTag ]
      }
    , { title = "THE AESTHETICS OF Y2K DESIGN REVIVAL"
      , date = "2025.02.28"
      , content = "Analyzing the return of millennium bug era design principles in modern web interfaces. Chrome effects, organic shapes, and digital mysticism are making a comeback, but with modern technical capabilities. This revival represents a nostalgic longing for optimistic futurism."
      , tags = [ "Design", "Y2K", "Aesthetics" ]
      , categories = [ DesignTag, ThoughtsTag ]
      }
    , { title = "BUILDING RESPONSIVE 3D INTERFACES"
      , date = "2025.02.20"
      , content = "How to create WebGL interfaces that adapt to different screen sizes and input methods. From mobile touch to desktop precision, 3D interfaces need to be as responsive as their 2D counterparts. Performance considerations become critical when dealing with complex 3D scenes."
      , tags = [ "WebGL", "Responsive Design", "3D" ]
      , categories = [ TechTag ]
      }
    , { title = "PERFORMANCE OPTIMIZATION FOR COMPLEX ANIMATIONS"
      , date = "2025.02.15"
      , content = "Techniques for maintaining 60fps in browser-based animations. GPU acceleration, efficient rendering loops, and smart resource management for smooth interactive experiences. Understanding browser rendering pipelines is essential for creating fluid animations."
      , tags = [ "Performance", "Animation", "Optimization" ]
      , categories = [ TechTag ]
      }
    , { title = "THE PSYCHOLOGY OF ORGANIC NAVIGATION"
      , date = "2025.02.10"
      , content = "How fluid, organic interfaces can reduce cognitive load and create more intuitive user experiences. Research into spatial navigation and visual hierarchy in non-linear interfaces. Users naturally gravitate toward organic, flowing navigation patterns."
      , tags = [ "UX Research", "Psychology", "Navigation" ]
      , categories = [ ThoughtsTag, DesignTag ]
      }
    , { title = "CREATIVE CODING WITH MATHEMATICAL BEAUTY"
      , date = "2025.02.05"
      , content = "Exploring the intersection of mathematics and visual art in code. From fractals to fluid dynamics, how mathematical concepts can inspire beautiful, interactive experiences. Mathematics provides the foundation for creating compelling generative art."
      , tags = [ "Mathematics", "Creative Coding", "Generative Art" ]
      , categories = [ TechTag, ThoughtsTag ]
      }
    , { title = "ADVANCED WEBGL TECHNIQUES"
      , date = "2025.01.30"
      , content = "Deep dive into advanced WebGL programming techniques including custom shaders, texture manipulation, and performance optimization. Creating complex visual effects requires understanding both the artistic and technical aspects of real-time graphics programming."
      , tags = [ "WebGL", "Graphics Programming", "Advanced Techniques" ]
      , categories = [ TechTag ]
      }
    , { title = "THE FUTURE OF WEB INTERFACES"
      , date = "2025.01.25"
      , content = "Predictions for how web interfaces will evolve over the next decade. Virtual reality, augmented reality, and spatial computing will reshape how we interact with digital content. The web is becoming increasingly immersive and three-dimensional."
      , tags = [ "Future Tech", "VR/AR", "Web Evolution" ]
      , categories = [ ThoughtsTag ]
      }
    ]


-- Helper to check if a tag is in the active filters


tagIsActive : BlogTag -> List BlogTag -> Bool
tagIsActive tag activeFilters =
    List.any (\t -> t == tag) activeFilters


-- Filter posts based on active filters


filteredPosts : List BlogTag -> List BlogPost -> List BlogPost
filteredPosts activeFilters posts =
    if List.isEmpty activeFilters then
        posts

    else
        posts
            |> List.filter
                (\post ->
                    post.categories
                        |> List.any (\cat -> tagIsActive cat activeFilters)
                )


view : List BlogTag -> Html BlogMsg
view activeFilters =
    div
        [ Attr.class "h-100 w-100 flex flex-column monospace bg-transparent relative"
        ]
        [ -- Compact header bar
          div
            [ Attr.class "flex justify-between items-center pa1 ph2"
            , Attr.style "background" "rgba(0, 0, 0, 0.2)"
            , Attr.style "backdrop-filter" "blur(4px)"
            , Attr.style "border-bottom" "1px solid rgba(192, 192, 192, 0.1)"
            , Attr.style "margin" "1.5rem 3rem 0.5rem 3rem"
            , Attr.style "max-width" "90%"
            ]
            [ -- Left side: Title and blog navigation
              div [ Attr.class "flex items-center gap1" ]
                [ h1
                    [ Attr.class "f6 tracked goop-title ma0 mr2"
                    , Attr.style "color" "transparent"
                    , Attr.style "background" "linear-gradient(135deg, #c0c0c0, #606060, #404040)"
                    , Attr.style "-webkit-background-clip" "text"
                    , Attr.style "background-clip" "text"
                    , Attr.style "text-shadow" "0 0 20px rgba(192, 192, 192, 0.3)"
                    , Attr.style "filter" "drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3))"
                    ]
                    [ text "BLOG" ]

                -- Blog category nodes (smaller)
                , div [ Attr.class "flex gap1" ]
                    [ goopBlogCategoryNode "TECH" TechTag activeFilters
                    , goopBlogCategoryNode "DESIGN" DesignTag activeFilters
                    , goopBlogCategoryNode "THOUGHTS" ThoughtsTag activeFilters
                    ]
                ]

            -- Right side: Close button (smaller)
            , button
                [ Attr.class "bg-transparent pa1 ph2 f8 fw6 monospace tracked pointer relative overflow-hidden ttu goop-close-button"
                , Attr.style "min-width" "50px"
                , Attr.style "height" "24px"
                ]
                [ text "✕ CLOSE" ]
            ]

        -- FIXED: Main scrollable content area with explicit height
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

            -- FIXED: Scrollable blog content with explicit height and hidden scrollbar
            , div
                [ Attr.class "custom-scroll-content transmission-interface"
                , Attr.style "height" "100%"
                , Attr.style "overflow-y" "auto"
                , Attr.style "overflow-x" "hidden"
                , Attr.style "padding" "1rem"
                , Attr.style "padding-right" "2rem"
                , Attr.style "margin-right" "-1rem"
                ]
                -- Render filtered blog posts
                (filteredPosts activeFilters allPosts
                    |> List.map (\post -> blogPost post.title post.date post.content post.tags)
                )

            -- Bottom fade overlay
            , div
                [ Attr.class "absolute bottom-0 left-0 right-0 z-2 pointer-events-none fade-overlay-bottom" ]
                []
            ]

        -- FIXED: Enhanced CSS with visible scrollbar like Services page
        , node "style"
            []
            [ text """
                /* Tachyons gap utilities */
                .gap2 { gap: 0.5rem; }
                .gap1 { gap: 0.75rem; }

                /* FIXED: Custom scroll container - same as Services page */
                .custom-scroll-container {
                    position: relative;
                    border: 1px solid rgba(192, 192, 192, 0.1);
                    background: rgba(0, 0, 0, 0.05);
                    backdrop-filter: blur(2px);
                }

                /* FIXED: Hide scrollbar completely like Services page */
                .custom-scroll-content {
                    scrollbar-width: none; /* Firefox */
                    -ms-overflow-style: none; /* Internet Explorer 10+ */
                }

                .custom-scroll-content::-webkit-scrollbar {
                    display: none; /* WebKit */
                }

                /* Enhanced fade overlays for better scroll indication */
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

                /* Blog category nodes (smaller, inline) */
                .goop-blog-category {
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.1) 0%,
                        rgba(64, 64, 64, 0.05) 50%,
                        transparent 100%);
                    border: 1px solid rgba(192, 192, 192, 0.15);
                    transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    backdrop-filter: blur(2px);
                    position: relative;
                    overflow: hidden;
                }

                .goop-blog-category::before {
                    content: '';
                    position: absolute;
                    top: -50%;
                    left: -50%;
                    width: 200%;
                    height: 200%;
                    background: conic-gradient(
                        from 0deg at 50% 50%,
                        transparent 0deg,
                        rgba(192, 192, 192, 0.05) 60deg,
                        transparent 120deg,
                        rgba(192, 192, 192, 0.03) 180deg,
                        transparent 240deg,
                        rgba(192, 192, 192, 0.05) 300deg,
                        transparent 360deg
                    );
                    animation: node-rotate 10s linear infinite;
                    opacity: 0;
                    transition: opacity 0.4s;
                }

                .goop-blog-category:hover::before {
                    opacity: 1;
                }

                .goop-blog-category:hover {
                    transform: translateY(-1px) scale(1.05);
                    border-color: rgba(192, 192, 192, 0.4);
                    background: radial-gradient(ellipse at center,
                        rgba(192, 192, 192, 0.2) 0%,
                        rgba(64, 64, 64, 0.1) 50%,
                        rgba(0, 0, 0, 0.05) 100%);
                    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2),
                                0 0 15px rgba(192, 192, 192, 0.05);
                }

                .goop-blog-category:hover * {
                    color: rgba(255, 255, 255, 0.95) !important;
                    text-shadow: 0 0 6px rgba(192, 192, 192, 0.3);
                }

                /* Active filter state - matches links page styling */
                .goop-blog-category.active-filter {
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

                .goop-blog-category.active-filter::before {
                    opacity: 1;
                }

                .goop-blog-category.active-filter * {
                    color: rgba(255, 255, 255, 1) !important;
                }

                /* Blog post styling (enhanced for better readability) */
                .blog-post {
                    background: rgba(0, 0, 0, 0.08);
                    border: 1px solid rgba(192, 192, 192, 0.08);
                    backdrop-filter: blur(2px);
                    transition: all 0.4s ease;
                    opacity: 0.9;
                    animation: post-fade-in 0.8s ease-out forwards;
                    border-radius: 4px;
                }

                @keyframes post-fade-in {
                    from {
                        opacity: 0;
                        transform: translateY(15px);
                    }
                    to {
                        opacity: 0.9;
                        transform: translateY(0);
                    }
                }

                .blog-post:hover {
                    background: rgba(0, 0, 0, 0.12);
                    border-color: rgba(192, 192, 192, 0.15);
                    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2),
                                0 0 20px rgba(192, 192, 192, 0.03);
                    opacity: 1;
                    transform: translateY(-2px);
                }

                /* Blog post titles */
                .blog-title {
                    color: rgba(255, 255, 255, 0.9) !important;
                    font-size: 13px !important;
                    letter-spacing: 0.05em;
                    text-transform: uppercase;
                    margin-bottom: 6px;
                    display: block;
                    position: relative;
                    font-weight: 600;
                    line-height: 1.3;
                }

                .blog-title::after {
                    content: '';
                    position: absolute;
                    bottom: -3px;
                    left: 0;
                    width: 24px;
                    height: 1px;
                    background: linear-gradient(90deg,
                        rgba(192, 192, 192, 0.6) 0%,
                        transparent 100%);
                }

                /* Blog dates */
                .blog-date {
                    color: rgba(192, 192, 192, 0.6) !important;
                    font-size: 9px !important;
                    letter-spacing: 0.1em;
                    text-transform: uppercase;
                    margin-bottom: 8px;
                    font-family: monospace;
                }

                /* Blog content (better readability) */
                .blog-content {
                    color: rgba(192, 192, 192, 0.85) !important;
                    line-height: 1.5;
                    margin-bottom: 10px;
                    font-size: 12px;
                }

                /* Blog tags */
                .blog-tags {
                    display: flex;
                    gap: 6px;
                    flex-wrap: wrap;
                }

                .blog-tag {
                    background: rgba(192, 192, 192, 0.08);
                    border: 1px solid rgba(192, 192, 192, 0.15);
                    color: rgba(192, 192, 192, 0.8);
                    padding: 3px 6px;
                    font-size: 9px;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                    border-radius: 2px;
                    transition: all 0.3s ease;
                }

                .blog-tag:hover {
                    background: rgba(192, 192, 192, 0.15);
                    color: rgba(255, 255, 255, 0.9);
                    border-color: rgba(192, 192, 192, 0.3);
                }

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

                /* Smooth animations */
                @keyframes node-rotate {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }

                /* Breathing animation for interface */
                .transmission-interface {
                    animation: interface-breathe 8s ease-in-out infinite;
                }

                @keyframes interface-breathe {
                    0%, 100% { opacity: 0.9; }
                    50% { opacity: 1; }
                }

                /* Smooth scroll behavior */
                .custom-scroll-content {
                    scroll-behavior: smooth;
                }

                /* Content staggered fade-in animation */
                .blog-post:nth-child(1) { animation-delay: 0.1s; }
                .blog-post:nth-child(2) { animation-delay: 0.15s; }
                .blog-post:nth-child(3) { animation-delay: 0.2s; }
                .blog-post:nth-child(4) { animation-delay: 0.25s; }
                .blog-post:nth-child(5) { animation-delay: 0.3s; }
                .blog-post:nth-child(6) { animation-delay: 0.35s; }
                .blog-post:nth-child(7) { animation-delay: 0.4s; }
                .blog-post:nth-child(8) { animation-delay: 0.45s; }
                .blog-post:nth-child(9) { animation-delay: 0.5s; }
                .blog-post:nth-child(10) { animation-delay: 0.55s; }
            """ ]
        ]



-- Blog category node (small, for header)


goopBlogCategoryNode : String -> BlogTag -> List BlogTag -> Html BlogMsg
goopBlogCategoryNode title tag activeFilters =
    let
        isActive =
            tagIsActive tag activeFilters
    in
    div
        [ Attr.class
            ("db pa1 ph1 tc goop-blog-category"
                ++ (if isActive then
                        " active-filter"

                    else
                        ""
                   )
            )
        , Attr.style "min-width" "40px"
        , Attr.style "cursor" "pointer"
        , onClick (ToggleFilter tag)
        , stopPropagationOn "click" (Decode.succeed ( ToggleFilter tag, True ))
        ]
        [ span
            [ Attr.class "f9 tracked ttu"
            , Attr.style "color" "rgba(192, 192, 192, 0.8)"
            ]
            [ text title ]
        ]



-- Blog post component with enhanced styling


blogPost : String -> String -> String -> List String -> Html BlogMsg
blogPost title date content tags =
    article
        [ Attr.class "mb3 pa3 blog-post"
        , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
        ]
        [ h2
            [ Attr.class "blog-title" ]
            [ text title ]
        , div
            [ Attr.class "blog-date" ]
            [ text date ]
        , p
            [ Attr.class "blog-content lh-copy mb2"
            ]
            [ text content ]
        , div
            [ Attr.class "blog-tags" ]
            (List.map blogTag tags)
        ]



-- Blog tag component


blogTag : String -> Html BlogMsg
blogTag tag =
    span
        [ Attr.class "blog-tag" ]
        [ text tag ]
