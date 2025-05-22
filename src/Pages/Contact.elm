module Pages.Contact exposing (view)

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onInput)



-- Contact page view matching the goop aesthetic


view : Html msg
view =
    div
        [ Attr.style "position" "relative"
        , Attr.style "width" "100%"
        , Attr.style "height" "100vh"
        , Attr.style "margin" "0"
        , Attr.style "padding" "0"
        , Attr.style "overflow" "hidden"
        ]
        [ -- OpenGL Canvas
          canvas
            [ Attr.style "position" "fixed"
            , Attr.style "top" "0"
            , Attr.style "left" "0"
            , Attr.style "width" "100%"
            , Attr.style "height" "100%"
            , Attr.style "z-index" "-1"
            ]
            []

        -- Your HTML content
        , div
            [ Attr.style "position" "relative"
            , Attr.style "z-index" "1"
            , Attr.style "padding" "20px 40px 40px 40px"
            , Attr.style "font-family" "monospace"
            , Attr.style "height" "100%"
            , Attr.style "overflow-y" "auto"
            , Attr.style "background-color" "transparent" -- Ensure the content background is transparent
            ]
            [ -- Contact methods grid - 3 elements centered
              div
                [ Attr.style "display" "grid"
                , Attr.style "grid-template-columns" "repeat(auto-fit, minmax(250px, 1fr))"
                , Attr.style "gap" "24px"
                , Attr.style "margin-bottom" "48px"
                , Attr.style "max-width" "900px"
                , Attr.style "margin-left" "auto"
                , Attr.style "margin-right" "auto"
                ]
                [ contactCard "📡" "EMAIL" "hello@example.com" "mailto:hello@example.com"
                , contactCard "🌐" "GITHUB" "@stamnostomp" "https://github.com/stamnostomp"
                , contactCard "💫" "DISCORD" "username#0000" "#"
                ]

            -- Organic contact form
            , div
                [ Attr.style "max-width" "600px"
                , Attr.style "margin" "0 auto"
                , Attr.style "padding" "32px"
                , Attr.style "background" "rgba(0, 0, 0, 0.2)"
                , Attr.style "border" "1px solid rgba(50, 50, 50, 0.3)"
                , Attr.style "border-radius" "8px"
                , Attr.style "position" "relative"
                , Attr.style "overflow" "hidden"
                , Attr.style "backdrop-filter" "blur(4px)"
                , Attr.class "contact-form"
                ]
                [ -- Form fields
                  formField "NAME" "text" "Your designation..."
                , formField "EMAIL" "email" "your@email.com..."
                , formTextArea "MESSAGE" "Compose your message..."

                -- Submit button
                , div [ Attr.style "text-align" "center", Attr.style "margin-top" "32px" ]
                    [ button
                        [ Attr.style "background" "linear-gradient(135deg, rgba(70, 70, 70, 0.6), rgba(40, 40, 40, 0.7))"
                        , Attr.style "color" "#cccccc"
                        , Attr.style "border" "1px solid rgba(80, 80, 80, 0.3)"
                        , Attr.style "padding" "14px 40px"
                        , Attr.style "font-size" "16px"
                        , Attr.style "font-weight" "600"
                        , Attr.style "font-family" "monospace"
                        , Attr.style "letter-spacing" "0.1em"
                        , Attr.style "cursor" "pointer"
                        , Attr.style "position" "relative"
                        , Attr.style "overflow" "hidden"
                        , Attr.style "transition" "all 0.3s"
                        , Attr.style "text-transform" "uppercase"
                        , Attr.style "border-radius" "4px"
                        , Attr.style "backdrop-filter" "blur(4px)"
                        , Attr.class "submit-button"
                        ]
                        [ text "TRANSMIT" ]
                    ]
                ]

            -- Status indicators
            , div
                [ Attr.style "text-align" "center"
                , Attr.style "margin-top" "48px"
                , Attr.style "padding" "12px"
                , Attr.style "background" "rgba(0, 0, 0, 0.2)"
                , Attr.style "border" "1px solid rgba(50, 50, 50, 0.2)"
                , Attr.style "border-radius" "4px"
                , Attr.style "max-width" "600px"
                , Attr.style "margin-left" "auto"
                , Attr.style "margin-right" "auto"
                , Attr.style "backdrop-filter" "blur(4px)"
                ]
                [ span [ Attr.style "color" "#888", Attr.style "margin-right" "16px", Attr.style "font-size" "12px" ] [ text "● NODE ACTIVE" ]
                , span [ Attr.style "color" "#888", Attr.style "margin-right" "16px", Attr.style "font-size" "12px" ] [ text "◆ SECURE CHANNEL" ]
                , span [ Attr.style "color" "#888", Attr.style "font-size" "12px" ] [ text "▲ READY" ]
                ]

            -- Add CSS for metallic effects and blue hover
            , node "style"
                []
                [ text """
                    /* Metallic contact cards with blue hover */
                    .contact-card {
                        background: linear-gradient(135deg, rgba(50, 50, 55, 0.6), rgba(30, 30, 35, 0.5)) !important;
                        backdrop-filter: blur(6px);
                        transition: all 0.3s ease !important;
                        box-shadow: inset 0 1px 0 rgba(100, 100, 110, 0.2),
                                    0 2px 8px rgba(0, 0, 0, 0.3);
                    }

                    .contact-card:hover {
                        transform: translateY(-2px);
                        border-color: rgba(0, 150, 255, 0.6) !important;
                        box-shadow: 0 0 20px rgba(0, 150, 255, 0.3),
                                    0 0 40px rgba(0, 100, 200, 0.2),
                                    inset 0 0 15px rgba(0, 150, 255, 0.1),
                                    0 4px 16px rgba(0, 0, 0, 0.4);
                        background: linear-gradient(135deg, rgba(40, 60, 80, 0.7), rgba(20, 40, 60, 0.6)) !important;
                    }

                    .contact-card:hover * {
                        color: rgba(200, 230, 255, 0.9) !important;
                        text-shadow: 0 0 8px rgba(0, 150, 255, 0.4);
                    }

                    /* Form styling to match goop */
                    .contact-form {
                        box-shadow: inset 0 1px 0 rgba(80, 80, 80, 0.1),
                                    0 2px 8px rgba(0, 0, 0, 0.3);
                        background: linear-gradient(135deg, rgba(30, 30, 35, 0.2), rgba(20, 20, 25, 0.15)) !important;
                    }

                    .contact-form:hover {
                        border-color: rgba(0, 100, 200, 0.3) !important;
                        box-shadow: 0 0 15px rgba(0, 100, 200, 0.1),
                                    inset 0 1px 0 rgba(80, 80, 80, 0.1),
                                    0 2px 8px rgba(0, 0, 0, 0.3);
                    }

                    /* Form inputs with metallic style */
                    input, textarea {
                        background: rgba(20, 20, 25, 0.4) !important;
                        border: 1px solid rgba(60, 60, 65, 0.3) !important;
                        color: #ccc !important;
                        transition: all 0.3s ease !important;
                        backdrop-filter: blur(4px);
                    }

                    input:focus, textarea:focus {
                        border-color: rgba(0, 150, 255, 0.5) !important;
                        background: rgba(20, 30, 40, 0.5) !important;
                        box-shadow: 0 0 15px rgba(0, 150, 255, 0.2),
                                    inset 0 0 10px rgba(0, 50, 100, 0.1) !important;
                        color: #fff !important;
                        outline: none !important;
                    }

                    /* Submit button with metallic effect */
                    .submit-button {
                        background: linear-gradient(135deg, rgba(70, 70, 70, 0.6), rgba(40, 40, 40, 0.7)) !important;
                        backdrop-filter: blur(4px);
                        box-shadow: inset 0 1px 0 rgba(120, 120, 130, 0.3),
                                    0 2px 4px rgba(0, 0, 0, 0.3);
                    }

                    .submit-button:hover {
                        background: linear-gradient(135deg, rgba(40, 60, 80, 0.7), rgba(30, 50, 70, 0.6)) !important;
                        border-color: rgba(0, 150, 255, 0.5) !important;
                        color: rgba(200, 230, 255, 0.9) !important;
                        box-shadow: 0 0 20px rgba(0, 150, 255, 0.3),
                                    inset 0 0 15px rgba(0, 100, 200, 0.2),
                                    0 2px 8px rgba(0, 0, 0, 0.4);
                        text-shadow: 0 0 8px rgba(0, 150, 255, 0.4);
                        transform: translateY(-1px);
                    }

                    /* Label styling */
                    label {
                        color: #999 !important;
                        font-size: 11px !important;
                    }

                    /* Status indicators hover */
                    span:hover {
                        color: rgba(0, 150, 255, 0.8) !important;
                        text-shadow: 0 0 6px rgba(0, 150, 255, 0.3);
                    }
                """ ]
            ]
        ]



-- Contact card component with metallic styling


contactCard : String -> String -> String -> String -> Html msg
contactCard icon title value link =
    a
        [ Attr.href link
        , Attr.style "display" "block"
        , Attr.style "padding" "28px"
        , Attr.style "border" "1px solid rgba(60, 60, 65, 0.3)"
        , Attr.style "border-radius" "6px"
        , Attr.style "text-decoration" "none"
        , Attr.style "color" "inherit"
        , Attr.style "position" "relative"
        , Attr.style "overflow" "hidden"
        , Attr.class "contact-card"
        ]
        [ -- Icon
          div
            [ Attr.style "font-size" "32px"
            , Attr.style "margin-bottom" "12px"
            , Attr.style "opacity" "0.7"
            ]
            [ text icon ]

        -- Title
        , h3
            [ Attr.style "color" "#aaa"
            , Attr.style "font-size" "13px"
            , Attr.style "margin-bottom" "8px"
            , Attr.style "letter-spacing" "0.1em"
            , Attr.style "font-weight" "normal"
            ]
            [ text title ]

        -- Value
        , p
            [ Attr.style "color" "#ccc"
            , Attr.style "font-size" "15px"
            , Attr.style "opacity" "0.8"
            ]
            [ text value ]
        ]



-- Form field component with metallic styling


formField : String -> String -> String -> Html msg
formField labelText inputType placeholder =
    div [ Attr.style "margin-bottom" "20px" ]
        [ label
            [ Attr.style "display" "block"
            , Attr.style "font-size" "11px"
            , Attr.style "letter-spacing" "0.1em"
            , Attr.style "margin-bottom" "6px"
            , Attr.style "text-transform" "uppercase"
            , Attr.style "color" "#999"
            ]
            [ text labelText ]
        , input
            [ Attr.type_ inputType
            , Attr.placeholder placeholder
            , Attr.style "width" "100%"
            , Attr.style "padding" "10px 12px"
            , Attr.style "border-radius" "4px"
            , Attr.style "font-family" "monospace"
            , Attr.style "font-size" "14px"
            ]
            []
        ]



-- Form textarea component with metallic styling


formTextArea : String -> String -> Html msg
formTextArea labelText placeholder =
    div [ Attr.style "margin-bottom" "20px" ]
        [ label
            [ Attr.style "display" "block"
            , Attr.style "font-size" "11px"
            , Attr.style "letter-spacing" "0.1em"
            , Attr.style "margin-bottom" "6px"
            , Attr.style "text-transform" "uppercase"
            , Attr.style "color" "#999"
            ]
            [ text labelText ]
        , textarea
            [ Attr.placeholder placeholder
            , Attr.rows 5
            , Attr.style "width" "100%"
            , Attr.style "padding" "10px 12px"
            , Attr.style "border-radius" "4px"
            , Attr.style "font-family" "monospace"
            , Attr.style "font-size" "14px"
            , Attr.style "resize" "vertical"
            ]
            []
        ]
