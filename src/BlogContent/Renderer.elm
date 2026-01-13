module BlogContent.Renderer exposing
    ( renderPost
    , renderSummary
    , renderContentBlock
    , renderInlineContent
    )

import BlogContent.Types exposing (..)
import Html exposing (..)
import Html.Attributes as Attr


-- Render full blog post


renderPost : BlogPost -> Html msg
renderPost post =
    article
        [ Attr.class "blog-post-full" ]
        [ renderPostHeader post.metadata
        , div
            [ Attr.class "blog-post-content" ]
            (List.map renderContentBlock post.content)
        ]


-- Render post header with metadata


renderPostHeader : BlogMetadata -> Html msg
renderPostHeader metadata =
    header
        [ Attr.class "blog-post-header" ]
        [ h1
            [ Attr.class "blog-post-title" ]
            [ text metadata.title ]
        , div
            [ Attr.class "blog-post-meta" ]
            [ span
                [ Attr.class "blog-post-date" ]
                [ text metadata.date ]
            , case metadata.author of
                Just author ->
                    span
                        [ Attr.class "blog-post-author" ]
                        [ text (" by " ++ author) ]

                Nothing ->
                    text ""
            ]
        , if List.isEmpty metadata.tags then
            text ""

          else
            div
                [ Attr.class "blog-post-tags" ]
                (List.map renderTag metadata.tags)
        ]


renderTag : String -> Html msg
renderTag tag =
    span
        [ Attr.class "blog-tag" ]
        [ text tag ]


-- Render summary card for blog list


renderSummary : BlogPost -> Html msg
renderSummary post =
    article
        [ Attr.class "blog-post-summary" ]
        [ h2
            [ Attr.class "blog-summary-title" ]
            [ text post.metadata.title ]
        , div
            [ Attr.class "blog-summary-meta" ]
            [ text post.metadata.date ]
        , case post.metadata.summary of
            Just summary ->
                p
                    [ Attr.class "blog-summary-text" ]
                    [ text summary ]

            Nothing ->
                -- Extract first paragraph as summary
                case List.head post.content of
                    Just (Paragraph inlineContent) ->
                        p
                            [ Attr.class "blog-summary-text" ]
                            (List.map renderInlineContent inlineContent)

                    _ ->
                        text ""
        , if List.isEmpty post.metadata.tags then
            text ""

          else
            div
                [ Attr.class "blog-summary-tags" ]
                (List.map renderTag post.metadata.tags)
        ]


-- Render a content block


renderContentBlock : ContentBlock -> Html msg
renderContentBlock block =
    case block of
        Heading level content ->
            renderHeading level content

        Paragraph inlineContent ->
            p
                [ Attr.class "blog-paragraph" ]
                (List.map renderInlineContent inlineContent)

        UnorderedList items ->
            ul
                [ Attr.class "blog-list" ]
                (List.map renderListItem items)

        OrderedList items ->
            ol
                [ Attr.class "blog-list blog-list-ordered" ]
                (List.map renderListItem items)

        CodeBlock language code ->
            renderCodeBlock language code

        Table headers rows ->
            renderTable headers rows

        Image src alt ->
            figure
                [ Attr.class "blog-image" ]
                [ img
                    [ Attr.src src
                    , Attr.alt alt
                    , Attr.class "blog-image-img"
                    ]
                    []
                , if String.isEmpty alt then
                    text ""

                  else
                    figcaption
                        [ Attr.class "blog-image-caption" ]
                        [ text alt ]
                ]

        BlockQuote inlineContent ->
            blockquote
                [ Attr.class "blog-blockquote" ]
                (List.map renderInlineContent inlineContent)

        HorizontalRule ->
            hr [ Attr.class "blog-hr" ] []


-- Render heading based on level


renderHeading : Int -> String -> Html msg
renderHeading level content =
    let
        headingClass =
            "blog-heading blog-heading-" ++ String.fromInt level

        headingElement =
            case level of
                1 ->
                    h1

                2 ->
                    h2

                3 ->
                    h3

                4 ->
                    h4

                5 ->
                    h5

                _ ->
                    h6
    in
    headingElement
        [ Attr.class headingClass ]
        [ text content ]


-- Render code block with syntax highlighting class


renderCodeBlock : String -> String -> Html msg
renderCodeBlock language code =
    pre
        [ Attr.class "blog-codeblock" ]
        [ Html.code
            [ Attr.class ("language-" ++ language) ]
            [ text code ]
        ]


-- Render table


renderTable : List String -> List (List String) -> Html msg
renderTable headers rows =
    table
        [ Attr.class "blog-table" ]
        [ thead []
            [ tr []
                (List.map
                    (\header ->
                        th [ Attr.class "blog-table-header" ] [ text header ]
                    )
                    headers
                )
            ]
        , tbody []
            (List.map renderTableRow rows)
        ]


renderTableRow : List String -> Html msg
renderTableRow cells =
    tr []
        (List.map
            (\cell ->
                td [ Attr.class "blog-table-cell" ] [ text cell ]
            )
            cells
        )


-- Render list item


renderListItem : ListItem -> Html msg
renderListItem item =
    li
        [ Attr.class "blog-list-item" ]
        (List.map renderInlineContent item)


-- Render inline content


renderInlineContent : InlineContent -> Html msg
renderInlineContent inline =
    case inline of
        Text str ->
            text str

        Bold content ->
            strong
                [ Attr.class "blog-bold" ]
                (List.map renderInlineContent content)

        Italic content ->
            em
                [ Attr.class "blog-italic" ]
                (List.map renderInlineContent content)

        Code str ->
            Html.code
                [ Attr.class "blog-code-inline" ]
                [ text str ]

        Link url linkText ->
            a
                [ Attr.href url
                , Attr.class "blog-link"
                , Attr.target
                    (if String.startsWith "http" url then
                        "_blank"

                     else
                        "_self"
                    )
                ]
                [ text linkText ]

        Strikethrough content ->
            Html.s
                [ Attr.class "blog-strikethrough" ]
                (List.map renderInlineContent content)

        Underline content ->
            Html.u
                [ Attr.class "blog-underline" ]
                (List.map renderInlineContent content)
