module Pages.Blog exposing (BlogMsg(..), view)

import BlogContent.Renderer as Renderer
import BlogContent.Types as BlogContent
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onFocus, onInput, stopPropagationOn)
import Json.Decode as Decode
import Types exposing (BlogTag(..))
import Model exposing (BlogPostIndexItem)



-- Blog page with full-screen scrolling interface - FIXED SCROLLING
-- Define a message type for internal use


type BlogMsg
    = NoOp
    | ToggleFilter BlogTag
    | LoadPost String
    | ClosePost
    | Close



-- Convert category string to BlogTag


categoryStringToTag : String -> Maybe BlogTag
categoryStringToTag str =
    case String.toLower str of
        "tech" ->
            Just TechTag

        "design" ->
            Just DesignTag

        "thoughts" ->
            Just ThoughtsTag

        _ ->
            Nothing


-- Convert BlogPostIndexItem to our local representation with BlogTag enums
convertIndexItem : BlogPostIndexItem -> { title : String, date : String, slug : String, summary : String, tags : List String, categories : List BlogTag }
convertIndexItem item =
    { title = item.title
    , date = item.date
    , slug = item.slug
    , summary = item.summary
    , tags = item.tags
    , categories = List.filterMap categoryStringToTag item.categories
    }



-- Helper to check if a tag is in the active filters


tagIsActive : BlogTag -> List BlogTag -> Bool
tagIsActive tag activeFilters =
    List.any (\t -> t == tag) activeFilters



-- Filter posts based on active filters


filteredPosts activeFilters posts =
    let
        convertedPosts =
            List.map convertIndexItem posts
    in
    if List.isEmpty activeFilters then
        convertedPosts

    else
        convertedPosts
            |> List.filter
                (\post ->
                    post.categories
                        |> List.any (\cat -> tagIsActive cat activeFilters)
                )


view : List BlogTag -> Maybe BlogContent.BlogPost -> Bool -> Maybe String -> List BlogPostIndexItem -> Html BlogMsg
view activeFilters currentBlogPost blogPostLoading blogError blogPostIndex =
    div
        [ Attr.class "h-100 w-100 flex flex-column monospace bg-transparent relative"
        ]
        [ -- Compact header bar
          div
            [ Attr.class "flex justify-between items-center pa1 ph2"
            , Attr.style "background" "rgba(0, 0, 0, 0.2)"
            , Attr.style "backdrop-filter" "blur(4px)"
            , Attr.style "border-bottom" "1px solid rgba(192, 192, 192, 0.1)"
            , Attr.style "margin" "0.5rem 0 0.5rem 0"
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

                -- Show filters only when viewing list (not when viewing a post)
                , case currentBlogPost of
                    Nothing ->
                        div [ Attr.class "flex gap1" ]
                            [ goopBlogCategoryNode "TECH" TechTag activeFilters
                            , goopBlogCategoryNode "DESIGN" DesignTag activeFilters
                            , goopBlogCategoryNode "THOUGHTS" ThoughtsTag activeFilters
                            ]

                    Just _ ->
                        text ""
                ]

            -- Right side: Show close button when viewing list, or back button when viewing post
            , case currentBlogPost of
                Nothing ->
                    button
                        [ Attr.class "bg-transparent pa1 ph2 f8 fw6 monospace tracked pointer relative overflow-hidden ttu goop-close-button"
                        , Attr.style "min-width" "50px"
                        , Attr.style "height" "24px"
                        , onClick Close
                        , stopPropagationOn "click" (Decode.succeed ( Close, True ))
                        ]
                        [ text "✕ CLOSE" ]

                Just _ ->
                    button
                        [ Attr.class "bg-transparent pa1 ph2 f8 fw6 monospace tracked pointer back-to-list-button"
                        , Attr.style "cursor" "pointer"
                        , Attr.style "color" "rgba(255, 255, 255, 0.9)"
                        , Attr.style "min-width" "100px"
                        , Attr.style "height" "24px"
                        , onClick ClosePost
                        , stopPropagationOn "click" (Decode.succeed ( ClosePost, True ))
                        ]
                        [ text "← BACK TO LIST" ]
            ]

        -- FIXED: Main scrollable content area with explicit height
        , div
            [ Attr.class "w-100 relative custom-scroll-container"
            , Attr.style "height" "calc(100% - 80px)"
            , Attr.style "margin" "0 0 0.5rem 0"
            ]
            [ -- Top fade overlay
              div
                [ Attr.class "dn absolute top-0 left-0 right-0 z-2 pointer-events-none fade-overlay-top" ]
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
                -- Render filtered blog posts or full post
                (case ( currentBlogPost, blogPostLoading, blogError ) of
                    ( Just blogPost, _, _ ) ->
                        [ viewFullBlogPost blogPost ]

                    ( Nothing, True, _ ) ->
                        [ loadingView ]

                    ( Nothing, False, Just error ) ->
                        [ errorView error ]

                    ( Nothing, False, Nothing ) ->
                        if List.isEmpty blogPostIndex then
                            [ div
                                [ Attr.class "flex items-center justify-center pa4"
                                , Attr.style "color" "rgba(192, 192, 192, 0.6)"
                                ]
                                [ text "No blog posts found. Loading..." ]
                            ]
                        else
                            filteredPosts activeFilters blogPostIndex
                                |> List.map blogPostCard
                )

            -- Bottom fade overlay
            , div
                [ Attr.class "dn absolute bottom-0 left-0 right-0 z-2 pointer-events-none fade-overlay-bottom" ]
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
                    border: none;
                    background: transparent;
                    backdrop-filter: none;
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

                /* Back to list button with pulsing blue border */
                .back-to-list-button {
                    border: 2px solid rgba(120, 160, 200, 0.5) !important;
                    animation: pulse-blue-border 2s ease-in-out infinite;
                    box-shadow: 0 0 10px rgba(120, 160, 200, 0.2),
                                inset 0 0 10px rgba(120, 160, 200, 0.08);
                }

                .back-to-list-button:hover {
                    border-color: rgba(140, 180, 220, 0.7) !important;
                    box-shadow: 0 0 20px rgba(120, 160, 200, 0.4),
                                inset 0 0 15px rgba(120, 160, 200, 0.15);
                    transform: scale(1.05);
                }

                @keyframes pulse-blue-border {
                    0%, 100% {
                        border-color: rgba(120, 160, 200, 0.5);
                        box-shadow: 0 0 10px rgba(120, 160, 200, 0.2),
                                    inset 0 0 10px rgba(120, 160, 200, 0.08);
                    }
                    50% {
                        border-color: rgba(140, 180, 220, 0.7);
                        box-shadow: 0 0 20px rgba(120, 160, 200, 0.4),
                                    inset 0 0 15px rgba(120, 160, 200, 0.15);
                    }
                }

                /* Blog post full content styling - muted pastels */
                .blog-post-full {
                    padding: 1rem;
                    max-width: 900px;
                    margin: 0 auto;
                }

                .blog-post-header {
                    margin-bottom: 2rem;
                    padding-bottom: 1rem;
                    border-bottom: 1px solid rgba(180, 160, 200, 0.2);
                }

                .blog-post-title {
                    color: rgba(220, 200, 230, 0.95);
                    font-size: 28px;
                    font-weight: 600;
                    letter-spacing: 0.05em;
                    text-transform: uppercase;
                    margin-bottom: 0.75rem;
                    text-shadow: 0 0 20px rgba(180, 160, 200, 0.3);
                }

                .blog-post-meta {
                    color: rgba(160, 180, 190, 0.7);
                    font-size: 11px;
                    letter-spacing: 0.1em;
                    text-transform: uppercase;
                }

                .blog-post-date,
                .blog-post-author {
                    margin-right: 1rem;
                }

                .blog-post-tags {
                    display: flex;
                    gap: 6px;
                    flex-wrap: wrap;
                    margin-top: 0.75rem;
                }

                .blog-post-content {
                    line-height: 1.8;
                }

                /* Headings - cycling pastel colors: purple → blue → green → lavender */
                .blog-heading {
                    font-weight: 600;
                    margin-top: 2.5rem;
                    margin-bottom: 1rem;
                    letter-spacing: 0.03em;
                    line-height: 1.4;
                }

                /* Level 1 (* in org) - Soft Purple */
                .blog-heading-1 {
                    color: rgba(200, 180, 220, 0.95);
                    font-size: 24px;
                    text-transform: uppercase;
                    letter-spacing: 0.08em;
                    border-bottom: 2px solid rgba(180, 160, 200, 0.3);
                    padding-bottom: 0.5rem;
                    margin-top: 3rem;
                    text-shadow: 0 0 15px rgba(180, 160, 200, 0.2);
                }

                /* Level 2 (** in org) - Soft Blue */
                .blog-heading-2 {
                    color: rgba(160, 190, 220, 0.9);
                    font-size: 20px;
                    border-bottom: 1px solid rgba(140, 170, 200, 0.25);
                    padding-bottom: 0.4rem;
                    margin-top: 2.5rem;
                    text-shadow: 0 0 12px rgba(160, 190, 220, 0.15);
                }

                /* Level 3 (*** in org) - Soft Green */
                .blog-heading-3 {
                    color: rgba(170, 210, 190, 0.85);
                    font-size: 17px;
                    margin-top: 2rem;
                    text-shadow: 0 0 10px rgba(170, 210, 190, 0.12);
                }

                /* Level 4 (**** in org) - Soft Lavender (purple cycle) */
                .blog-heading-4 {
                    color: rgba(190, 180, 210, 0.8);
                    font-size: 15px;
                    margin-top: 1.5rem;
                    text-shadow: 0 0 8px rgba(190, 180, 210, 0.1);
                }

                /* Level 5 (***** in org) - Soft Cyan (blue cycle) */
                .blog-heading-5 {
                    color: rgba(170, 200, 210, 0.75);
                    font-size: 14px;
                    margin-top: 1.5rem;
                }

                /* Level 6 (****** in org) - Soft Mint (green cycle) */
                .blog-heading-6 {
                    color: rgba(180, 210, 190, 0.7);
                    font-size: 13px;
                    margin-top: 1.2rem;
                }

                /* Level 7 (******* in org) - Soft Mauve (purple cycle) */
                .blog-heading-7 {
                    color: rgba(190, 175, 200, 0.65);
                    font-size: 13px;
                    margin-top: 1rem;
                    font-weight: 500;
                }

                /* Level 8 (******** in org) - Soft Sky (blue cycle) */
                .blog-heading-8 {
                    color: rgba(175, 195, 210, 0.6);
                    font-size: 12px;
                    margin-top: 0.9rem;
                    font-weight: 500;
                }

                /* Level 9 (********* in org) - Soft Sage (green cycle) */
                .blog-heading-9 {
                    color: rgba(180, 200, 185, 0.55);
                    font-size: 12px;
                    margin-top: 0.8rem;
                    font-weight: 400;
                }

                /* Level 10 (********** in org) - Soft Lilac (purple cycle) */
                .blog-heading-10 {
                    color: rgba(185, 175, 195, 0.5);
                    font-size: 11px;
                    margin-top: 0.7rem;
                    font-weight: 400;
                }

                /* Paragraphs */
                .blog-paragraph {
                    color: rgba(200, 200, 200, 0.85);
                    margin-bottom: 1.2rem;
                    font-size: 14px;
                    line-height: 1.8;
                }

                /* Bold text - soft purple/pink tint */
                .blog-bold {
                    color: rgba(220, 200, 220, 0.95);
                    font-weight: 600;
                    text-shadow: 0 0 10px rgba(200, 180, 200, 0.15);
                }

                /* Italic text - soft blue tint */
                .blog-italic {
                    color: rgba(180, 200, 220, 0.9);
                    font-style: italic;
                }

                /* Inline code - soft green tint */
                .blog-code-inline {
                    background: rgba(160, 200, 180, 0.08);
                    border: 1px solid rgba(160, 200, 180, 0.2);
                    color: rgba(180, 220, 200, 0.9);
                    padding: 2px 8px;
                    border-radius: 3px;
                    font-family: 'Courier New', monospace;
                    font-size: 13px;
                }

                /* Code blocks - soft green theme */
                .blog-codeblock {
                    background: rgba(0, 0, 0, 0.25);
                    border: 1px solid rgba(160, 200, 180, 0.2);
                    border-left: 3px solid rgba(160, 200, 180, 0.4);
                    border-radius: 4px;
                    padding: 1.25rem;
                    margin: 1.5rem 0;
                    overflow-x: auto;
                    font-family: 'Courier New', monospace;
                    font-size: 13px;
                    line-height: 1.6;
                }

                .blog-codeblock code {
                    color: rgba(180, 220, 200, 0.9);
                    background: none;
                    padding: 0;
                }

                /* Links - soft cyan */
                .blog-link {
                    color: rgba(160, 200, 220, 0.9);
                    text-decoration: none;
                    border-bottom: 1px solid rgba(160, 200, 220, 0.3);
                    transition: all 0.2s;
                }

                .blog-link:hover {
                    color: rgba(180, 220, 240, 1);
                    border-bottom-color: rgba(180, 220, 240, 0.6);
                    text-shadow: 0 0 10px rgba(160, 200, 220, 0.3);
                }

                /* Lists - soft colors */
                .blog-list {
                    color: rgba(200, 200, 200, 0.85);
                    margin-bottom: 1.2rem;
                    margin-left: 1.5rem;
                    padding-left: 1rem;
                }

                .blog-list-item {
                    margin-bottom: 0.5rem;
                    font-size: 14px;
                    line-height: 1.7;
                }

                .blog-list-item::marker {
                    color: rgba(180, 160, 200, 0.6);
                }

                /* Blockquotes - soft lavender */
                .blog-blockquote {
                    border-left: 3px solid rgba(180, 160, 200, 0.4);
                    padding-left: 1.2rem;
                    margin: 1.5rem 0;
                    color: rgba(200, 180, 210, 0.85);
                    font-style: italic;
                    background: rgba(180, 160, 200, 0.03);
                    padding: 1rem 1rem 1rem 1.2rem;
                    border-radius: 0 4px 4px 0;
                }

                /* Tables - soft pastel theme */
                .blog-table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 1.5rem 0;
                    font-size: 13px;
                }

                .blog-table-header {
                    background: rgba(180, 160, 200, 0.08);
                    color: rgba(220, 200, 230, 0.9);
                    border: 1px solid rgba(180, 160, 200, 0.25);
                    padding: 0.6rem 0.8rem;
                    text-align: left;
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                    font-size: 12px;
                }

                .blog-table-cell {
                    border: 1px solid rgba(180, 180, 200, 0.15);
                    padding: 0.6rem 0.8rem;
                    color: rgba(200, 200, 200, 0.85);
                }

                .blog-table tbody tr:nth-child(even) {
                    background: rgba(180, 180, 200, 0.02);
                }

                /* Horizontal rules - soft gradient */
                .blog-hr {
                    border: none;
                    height: 1px;
                    background: linear-gradient(90deg,
                        transparent 0%,
                        rgba(180, 180, 200, 0.3) 50%,
                        transparent 100%);
                    margin: 2.5rem 0;
                }

                /* Strikethrough - muted */
                .blog-strikethrough {
                    color: rgba(180, 180, 180, 0.5);
                    text-decoration: line-through;
                }

                /* Underline - soft emphasis */
                .blog-underline {
                    color: rgba(200, 190, 210, 0.9);
                    text-decoration: underline;
                    text-decoration-color: rgba(180, 160, 200, 0.4);
                }

                /* Images */
                .blog-image {
                    margin: 2rem 0;
                    text-align: center;
                }

                .blog-image-img {
                    max-width: 100%;
                    border: 1px solid rgba(180, 180, 200, 0.2);
                    border-radius: 4px;
                    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
                }

                .blog-image-caption {
                    color: rgba(180, 180, 200, 0.7);
                    font-size: 12px;
                    margin-top: 0.75rem;
                    font-style: italic;
                }
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



-- Blog post card component (summary for list view)


blogPostCard : { title : String, date : String, slug : String, summary : String, tags : List String, categories : List BlogTag } -> Html BlogMsg
blogPostCard post =
    article
        [ Attr.class "mb3 pa3 blog-post"
        , Attr.style "cursor" "pointer"
        , onClick (LoadPost post.slug)
        , stopPropagationOn "click" (Decode.succeed ( LoadPost post.slug, True ))
        ]
        [ h2
            [ Attr.class "blog-title" ]
            [ text post.title ]
        , div
            [ Attr.class "blog-date" ]
            [ text post.date ]
        , p
            [ Attr.class "blog-content lh-copy mb2"
            ]
            [ text post.summary ]
        , div
            [ Attr.class "blog-tags" ]
            (List.map blogTag post.tags)
        ]



-- Loading indicator view


loadingView : Html BlogMsg
loadingView =
    div
        [ Attr.class "flex items-center justify-center pa4"
        , Attr.style "color" "rgba(192, 192, 192, 0.8)"
        ]
        [ text "LOADING POST..." ]



-- Error view


errorView : String -> Html BlogMsg
errorView error =
    div
        [ Attr.class "pa4 ma3"
        , Attr.style "border" "1px solid rgba(192, 0, 0, 0.5)"
        , Attr.style "background" "rgba(192, 0, 0, 0.1)"
        , Attr.style "color" "rgba(255, 192, 192, 0.9)"
        ]
        [ h3
            [ Attr.class "f5 mb2" ]
            [ text "ERROR LOADING BLOG POST" ]
        , p
            [ Attr.class "f6 lh-copy" ]
            [ text error ]
        , p
            [ Attr.class "f7 mt3"
            , Attr.style "color" "rgba(192, 192, 192, 0.6)"
            ]
            [ text "Please check that the .org file exists in /blog/posts/" ]
        ]



-- Full blog post view using the renderer


viewFullBlogPost : BlogContent.BlogPost -> Html BlogMsg
viewFullBlogPost blogPost =
    div
        [ Attr.class "blog-post-full"
        , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
        ]
        [ Html.map (\_ -> NoOp) (Renderer.renderPost blogPost) ]



-- Blog tag component


blogTag : String -> Html BlogMsg
blogTag tag =
    span
        [ Attr.class "blog-tag" ]
        [ text tag ]
