-- src/Types.elm - Shared types to avoid import cycles


module Types exposing (Page(..))

-- Page type used across the application


type Page
    = Home
    | Projects
    | About
    | Contact
    | Services
