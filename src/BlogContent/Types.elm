module BlogContent.Types exposing
    ( BlogPost
    , BlogMetadata
    , ContentBlock(..)
    , InlineContent(..)
    , ListItem
    )

-- Blog post with metadata and content


type alias BlogPost =
    { metadata : BlogMetadata
    , content : List ContentBlock
    }


-- Metadata extracted from org-mode headers


type alias BlogMetadata =
    { title : String
    , date : String -- YYYY-MM-DD format
    , author : Maybe String
    , tags : List String
    , categories : List String -- tech, design, thoughts
    , summary : Maybe String
    , slug : String
    , draft : Bool
    }


-- Content blocks (top-level structural elements)


type ContentBlock
    = Heading Int String -- level, text
    | Paragraph (List InlineContent)
    | UnorderedList (List ListItem)
    | OrderedList (List ListItem)
    | CodeBlock String String -- language, code
    | Table (List String) (List (List String)) -- headers, rows
    | Image String String -- src, alt
    | BlockQuote (List InlineContent)
    | HorizontalRule


-- Inline content (within paragraphs, list items, etc.)


type InlineContent
    = Text String
    | Bold (List InlineContent)
    | Italic (List InlineContent)
    | Code String
    | Link String String -- url, text
    | Strikethrough (List InlineContent)
    | Underline (List InlineContent)


-- List items can contain inline content


type alias ListItem =
    List InlineContent
