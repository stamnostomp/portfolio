-- src/Types.elm - Shared types to avoid import cycles with Blog page added


module Types exposing (Page(..), BlogTag(..), LinkFilter(..))

-- Page type used across the application


type Page
    = Home
    | Projects
    | About
    | Contact
    | Services
    | Blog
    | Portfolio
    | Links
    | Gallery


-- Blog filter types


type BlogTag
    = TechTag
    | DesignTag
    | ThoughtsTag


-- Link filter types (combination of status and category)


type LinkFilter
    = OnlineStatus
    | MediaCategory
    | StorageCategory
