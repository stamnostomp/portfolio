module BlogContent.OrgParser exposing (parseBlogPost)

import BlogContent.Types exposing (..)
import Parser exposing (..)
import Set



-- Parse a complete org-mode blog post


parseBlogPost : String -> Result (List DeadEnd) BlogPost
parseBlogPost input =
    run blogPostParser input



-- Main parser for blog post


blogPostParser : Parser BlogPost
blogPostParser =
    succeed BlogPost
        |= metadataParser
        |= contentBlocksParser



-- Parse metadata section (#+TITLE:, #+DATE:, etc.)


metadataParser : Parser BlogMetadata
metadataParser =
    succeed buildMetadata
        |= many metadataLineParser
        |. spaces


buildMetadata : List ( String, String ) -> BlogMetadata
buildMetadata pairs =
    let
        get key =
            pairs
                |> List.filter (\( k, _ ) -> String.toUpper k == String.toUpper key)
                |> List.head
                |> Maybe.map Tuple.second

        getList key =
            get key
                |> Maybe.map (String.split "," >> List.map String.trim)
                |> Maybe.withDefault []

        title =
            get "TITLE" |> Maybe.withDefault "Untitled"

        slug =
            get "SLUG"
                |> Maybe.withDefault (titleToSlug title)

        draft =
            get "DRAFT"
                |> Maybe.map (String.toLower >> (==) "true")
                |> Maybe.withDefault False
    in
    { title = title
    , date = get "DATE" |> Maybe.withDefault ""
    , author = get "AUTHOR"
    , tags = getList "TAGS"
    , categories = getList "CATEGORIES"
    , summary = get "SUMMARY"
    , slug = slug
    , draft = draft
    }


titleToSlug : String -> String
titleToSlug title =
    title
        |> String.toLower
        |> String.replace " " "-"
        |> String.filter (\c -> Char.isAlphaNum c || c == '-')


metadataLineParser : Parser ( String, String )
metadataLineParser =
    succeed Tuple.pair
        |. symbol "#+"
        |= variable { start = Char.isAlpha, inner = Char.isAlphaNum, reserved = Set.empty }
        |. symbol ":"
        |. spaces
        |= getChompedString (chompUntil "\n")
        |. symbol "\n"



-- Parse content blocks


contentBlocksParser : Parser (List ContentBlock)
contentBlocksParser =
    many contentBlockParser


contentBlockParser : Parser ContentBlock
contentBlockParser =
    oneOf
        [ backtrackable codeBlockParser
        , backtrackable tableParser
        , backtrackable imageParser
        , backtrackable blockQuoteParser
        , backtrackable horizontalRuleParser
        , backtrackable headingParser
        , backtrackable unorderedListParser
        , backtrackable orderedListParser
        , backtrackable paragraphParser
        , emptyLineParser
        ]


emptyLineParser : Parser ContentBlock
emptyLineParser =
    succeed (Paragraph [ Text "" ])
        |. symbol "\n"



-- Parse headings (* Level 1, ** Level 2, etc.)


headingParser : Parser ContentBlock
headingParser =
    succeed Heading
        |= (getChompedString
                (succeed ()
                    |. chompIf ((==) '*')
                    |. chompWhile ((==) '*')
                )
                |> andThen (\stars -> succeed (String.length stars))
           )
        |. spaces
        |= getChompedString (chompUntil "\n")
        |. symbol "\n"



-- Parse paragraphs


paragraphParser : Parser ContentBlock
paragraphParser =
    succeed Paragraph
        |= inlineContentParser
        |. oneOf [ symbol "\n\n", symbol "\n", end ]



-- Parse inline content (bold, italic, links, etc.)


inlineContentParser : Parser (List InlineContent)
inlineContentParser =
    succeed (::)
        |= inlineElementParser
        |= many inlineElementParser


inlineElementParser : Parser InlineContent
inlineElementParser =
    oneOf
        [ backtrackable linkParser
        , backtrackable boldParser
        , backtrackable italicParser
        , backtrackable codeInlineParser
        , backtrackable strikethroughParser
        , backtrackable underlineParser
        , textParser
        ]


linkParser : Parser InlineContent
linkParser =
    succeed Link
        |. symbol "[["
        |= getChompedString (chompUntil "]")
        |. symbol "]"
        |. symbol "["
        |= getChompedString (chompUntil "]")
        |. symbol "]]"


boldParser : Parser InlineContent
boldParser =
    succeed Bold
        |. symbol "*"
        |= lazy (\_ -> many inlineElementParser)
        |. symbol "*"


italicParser : Parser InlineContent
italicParser =
    succeed Italic
        |. symbol "/"
        |= lazy (\_ -> many inlineElementParser)
        |. symbol "/"


codeInlineParser : Parser InlineContent
codeInlineParser =
    succeed Code
        |. symbol "="
        |= getChompedString (chompUntil "=")
        |. symbol "="


strikethroughParser : Parser InlineContent
strikethroughParser =
    succeed Strikethrough
        |. symbol "+"
        |= lazy (\_ -> many inlineElementParser)
        |. symbol "+"


underlineParser : Parser InlineContent
underlineParser =
    succeed Underline
        |. symbol "_"
        |= lazy (\_ -> many inlineElementParser)
        |. symbol "_"


textParser : Parser InlineContent
textParser =
    succeed Text
        |= getChompedString
            (succeed ()
                |. chompIf (\c -> c /= '\n' && c /= '*' && c /= '/' && c /= '=' && c /= '+' && c /= '_' && c /= '[')
                |. chompWhile (\c -> c /= '\n' && c /= '*' && c /= '/' && c /= '=' && c /= '+' && c /= '_' && c /= '[')
            )



-- Parse code blocks


codeBlockParser : Parser ContentBlock
codeBlockParser =
    succeed CodeBlock
        |. symbol "#+BEGIN_SRC"
        |. spaces
        |= getChompedString (chompUntil "\n")
        |. symbol "\n"
        |= getChompedString (chompUntil "#+END_SRC")
        |. symbol "#+END_SRC"
        |. symbol "\n"



-- Parse unordered lists


unorderedListParser : Parser ContentBlock
unorderedListParser =
    succeed UnorderedList
        |= (succeed (::)
                |= listItemParser
                |= many listItemParser
           )


listItemParser : Parser ListItem
listItemParser =
    succeed identity
        |. symbol "-"
        |. spaces
        |= inlineContentParser
        |. symbol "\n"



-- Parse ordered lists


orderedListParser : Parser ContentBlock
orderedListParser =
    succeed OrderedList
        |= (succeed (::)
                |= numberedListItemParser
                |= many numberedListItemParser
           )


numberedListItemParser : Parser ListItem
numberedListItemParser =
    succeed identity
        |. int
        |. symbol "."
        |. spaces
        |= inlineContentParser
        |. symbol "\n"



-- Parse tables


tableParser : Parser ContentBlock
tableParser =
    succeed Table
        |= tableHeaderParser
        |. tableSeparatorParser
        |= many tableRowParser


tableHeaderParser : Parser (List String)
tableHeaderParser =
    succeed identity
        |. symbol "|"
        |= (succeed (::)
                |= tableCellParser
                |= many tableCellParser
           )
        |. symbol "\n"


tableSeparatorParser : Parser ()
tableSeparatorParser =
    succeed ()
        |. symbol "|"
        |. chompWhile (\c -> c == '-' || c == '+' || c == '|')
        |. symbol "\n"


tableRowParser : Parser (List String)
tableRowParser =
    succeed identity
        |. symbol "|"
        |= (succeed (::)
                |= tableCellParser
                |= many tableCellParser
           )
        |. symbol "\n"


tableCellParser : Parser String
tableCellParser =
    succeed String.trim
        |= getChompedString (chompUntil "|")
        |. symbol "|"



-- Parse images


imageParser : Parser ContentBlock
imageParser =
    succeed Image
        |. symbol "[["
        |= getChompedString (chompUntil "]")
        |. symbol "]"
        |. symbol "["
        |= getChompedString (chompUntil "]")
        |. symbol "]]"
        |. symbol "\n"



-- Parse block quotes


blockQuoteParser : Parser ContentBlock
blockQuoteParser =
    succeed BlockQuote
        |. symbol "#+BEGIN_QUOTE"
        |. symbol "\n"
        |= inlineContentParser
        |. symbol "#+END_QUOTE"
        |. symbol "\n"



-- Parse horizontal rules


horizontalRuleParser : Parser ContentBlock
horizontalRuleParser =
    succeed HorizontalRule
        |. symbol "-----"
        |. chompWhile ((==) '-')
        |. symbol "\n"



-- Helper: parse many occurrences


many : Parser a -> Parser (List a)
many parser =
    loop [] (manyHelp parser)


manyHelp : Parser a -> List a -> Parser (Step (List a) (List a))
manyHelp parser acc =
    oneOf
        [ succeed (\item -> Loop (item :: acc))
            |= parser
        , succeed (Done (List.reverse acc))
        ]
