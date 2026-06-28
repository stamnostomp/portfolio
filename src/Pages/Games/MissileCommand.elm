module Pages.Games.MissileCommand exposing (GameState, Msg, init, subscriptions, update, view)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (..)
import Json.Decode as Decode
import Math.Vector2 as Vec2
import Random
import Time

-- MODEL

type alias GameState =
    { cities : List City
    , missiles : List Missile
    , antiMissiles : List AntiMissile
    , score : Int
    , lives : Int
    , gameOver : Bool
    , time : Time.Posix
    , mousePos : Vec2.Vec2
    , mouseDown : Bool
    , seed : Random.Seed

    -- Wave state
    , wave : Int
    , toSpawn : Int -- missiles still to launch this wave
    , spawnCooldown : Float -- ms until the next launch is allowed

    -- Active blast animations
    , explosions : List Explosion
    }

type alias City =
    { position : Vec2.Vec2
    , health : Int
    , radius : Float
    , ammo : Int -- interceptors this base has left this wave
    }

type alias Missile =
    { position : Vec2.Vec2
    , velocity : Vec2.Vec2
    , target : Vec2.Vec2
    , radius : Float
    , start : Vec2.Vec2
    , phase : Float
    }

type alias AntiMissile =
    { position : Vec2.Vec2
    , velocity : Vec2.Vec2
    , life : Float
    , radius : Float
    , origin : Vec2.Vec2
    }

type alias Explosion =
    { position : Vec2.Vec2
    , age : Float -- seconds since detonation
    , duration : Float -- total lifetime in seconds
    , maxRadius : Float -- peak blast radius (game units)
    }

type alias CollisionResult =
    { missiles : List Missile
    , antiMissiles : List AntiMissile
    , cities : List City
    , explosions : List Explosion
    , score : Int
    }

type Msg
    = Tick Time.Posix
    | MouseMove Float Float
    | MouseDown Bool
    | LaunchAntiMissile

-- INIT

init : ( GameState, Cmd Msg )
init =
    let
        initialSeed =
            Random.initialSeed 42

        cities =
            [ City (Vec2.vec2 0.2 0.8) 3 0.05 ammoPerCity
            , City (Vec2.vec2 0.5 0.8) 3 0.05 ammoPerCity
            , City (Vec2.vec2 0.8 0.8) 3 0.05 ammoPerCity
            ]
    in
    ( GameState cities [] [] 0 3 False (Time.millisToPosix 0) (Vec2.vec2 0 0) False initialSeed 1 (missilesForWave 1 cities) 0 []
    , Cmd.none
    )

-- UPDATE

update : Msg -> GameState -> ( GameState, Cmd Msg )
update msg state =
    case msg of
        Tick newTime ->
            let
                -- Clamp so the first frame (state.time = 0 vs. absolute epoch
                -- millis) and any lag spikes don't teleport everything.
                dt =
                    Basics.clamp 0 32 (Time.posixToMillis newTime - Time.posixToMillis state.time)

                -- Tick down the spawn timer, then launch a missile if this wave
                -- still has budget and the screen isn't already at its cap.
                cooledDown =
                    state.spawnCooldown - toFloat dt

                wantSpawn =
                    not state.gameOver
                        && (state.toSpawn > 0)
                        && (List.length state.missiles < maxConcurrent state.wave)
                        && (cooledDown <= 0)

                ( newMissiles, newSeed, spawnState ) =
                    if wantSpawn then
                        let
                            ( missile, nextSeed ) =
                                spawnMissile state.cities state.seed
                        in
                        ( missile :: state.missiles
                        , nextSeed
                        , { toSpawn = state.toSpawn - 1, cooldown = spawnIntervalMs state.wave }
                        )

                    else
                        ( state.missiles
                        , state.seed
                        , { toSpawn = state.toSpawn, cooldown = cooledDown }
                        )

                -- Update missiles (city/interception hits handled in checkCollisions)
                updatedMissiles =
                    newMissiles
                        |> List.map (stepMissile dt)
                        |> List.filter (\m -> Vec2.getY m.position < 1.2)

                -- Update anti-missiles
                updatedAntiMissiles =
                    List.map (\am ->
                        let
                            newPos =
                                Vec2.add am.position (Vec2.scale (toFloat dt) am.velocity)
                        in
                        { am | position = newPos, life = am.life - (toFloat dt / 1000) }
                    ) state.antiMissiles
                        |> List.filter (\am -> am.life > 0)

                -- Age active blasts; drop the ones that have finished.
                updatedExplosions =
                    state.explosions
                        |> List.map (\e -> { e | age = e.age + toFloat dt / 1000 })
                        |> List.filter (\e -> e.age < e.duration)

                -- Check collisions
                collisions =
                    checkCollisions updatedMissiles updatedAntiMissiles state.cities updatedExplosions state.score

                finalMissiles =
                    collisions.missiles

                finalAntiMissiles =
                    collisions.antiMissiles

                newCities =
                    collisions.cities

                finalExplosions =
                    collisions.explosions

                newScore =
                    collisions.score

                -- Check if game over
                newGameOver =
                    List.isEmpty newCities || state.lives <= 0

                -- Wave is cleared once its budget is spent and the sky is empty;
                -- the next wave is bigger and allows more missiles at once.
                waveCleared =
                    (spawnState.toSpawn == 0) && List.isEmpty finalMissiles && not newGameOver

                ( nextWave, nextToSpawn, nextCooldown ) =
                    if waveCleared then
                        ( state.wave + 1
                        , missilesForWave (state.wave + 1) newCities
                        , waveBreatherMs
                        )

                    else
                        ( state.wave, spawnState.toSpawn, spawnState.cooldown )

                -- Restock every surviving base at the start of a new wave.
                citiesForNextWave =
                    if waveCleared then
                        List.map (\c -> { c | ammo = ammoPerCity }) newCities

                    else
                        newCities
            in
            ( { state
                | missiles = finalMissiles
                , antiMissiles = finalAntiMissiles
                , cities = citiesForNextWave
                , score = newScore
                , time = newTime
                , seed = newSeed
                , gameOver = newGameOver
                , wave = nextWave
                , toSpawn = nextToSpawn
                , spawnCooldown = nextCooldown
                , explosions = finalExplosions
              }
            , Cmd.none
            )

        MouseMove x y ->
            ( { state | mousePos = Vec2.vec2 x y }, Cmd.none )

        MouseDown down ->
            ( { state | mouseDown = down }, Cmd.none )

        LaunchAntiMissile ->
            let
                -- Nearest base to the aim point that still has ammo (paired with
                -- its index so we can deplete exactly that one).
                firingBase =
                    state.cities
                        |> List.indexedMap Tuple.pair
                        |> List.filter (\( _, c ) -> c.ammo > 0)
                        |> List.sortBy (\( _, c ) -> Vec2.distance state.mousePos c.position)
                        |> List.head
            in
            case firingBase of
                Nothing ->
                    -- No base with ammo left — nothing fires.
                    ( state, Cmd.none )

                Just ( index, city ) ->
                    let
                        launchPos =
                            city.position

                        direction =
                            Vec2.normalize (Vec2.sub state.mousePos launchPos)

                        newAntiMissile =
                            { position = launchPos
                            , velocity = Vec2.scale 0.0009 direction
                            , life = 4.0
                            , radius = 0.02
                            , origin = launchPos
                            }

                        depletedCities =
                            List.indexedMap
                                (\i c ->
                                    if i == index then
                                        { c | ammo = c.ammo - 1 }

                                    else
                                        c
                                )
                                state.cities
                    in
                    ( { state
                        | antiMissiles = newAntiMissile :: state.antiMissiles
                        , cities = depletedCities
                      }
                    , Cmd.none
                    )


-- WAVES & SPAWNING


{-| Total missiles a wave launches: a per-city allotment that grows each wave. -}
missilesForWave : Int -> List City -> Int
missilesForWave wave cities =
    Basics.max 1 (List.length cities) * (1 + wave)


{-| How many missiles may be on screen at once — rises each wave, capped. -}
maxConcurrent : Int -> Int
maxConcurrent wave =
    Basics.min 8 (1 + wave)


{-| Delay between launches within a wave (ms); later waves spawn faster. -}
spawnIntervalMs : Int -> Float
spawnIntervalMs wave =
    Basics.max 400 (1600 - toFloat wave * 150)


{-| Breather before the next wave starts (ms). -}
waveBreatherMs : Float
waveBreatherMs =
    2000


{-| Interceptors each base is stocked with at the start of every wave. -}
ammoPerCity : Int
ammoPerCity =
    10


{-| Build one randomized enemy missile (entry column, speed, weave phase, and a
random target city), returning the advanced seed.
-}
spawnMissile : List City -> Random.Seed -> ( Missile, Random.Seed )
spawnMissile cities seed =
    let
        ( randX, seed1 ) =
            Random.step (Random.float 0.1 0.9) seed

        ( randSpeed, seed2 ) =
            Random.step (Random.float 0 0.0003) seed1

        ( randPhase, seed3 ) =
            Random.step (Random.float 0 6.283) seed2

        ( targetCity, seed4 ) =
            pickTargetCity cities seed3

        spawnPos =
            Vec2.vec2 randX -0.1

        missile =
            Missile spawnPos (Vec2.vec2 0 (0.0005 + randSpeed)) targetCity 0.02 spawnPos randPhase
    in
    ( missile, seed4 )



-- MISSILE MOTION


{-| Pick a random city's position as a missile's target, returning the advanced
seed. Falls back to the screen center if there are no cities left.
-}
pickTargetCity : List City -> Random.Seed -> ( Vec2.Vec2, Random.Seed )
pickTargetCity cities seed =
    let
        ( index, nextSeed ) =
            Random.step (Random.int 0 (Basics.max 0 (List.length cities - 1))) seed

        position =
            cities
                |> List.drop index
                |> List.head
                |> Maybe.map .position
                |> Maybe.withDefault (Vec2.vec2 0.5 0.8)
    in
    ( position, nextSeed )


{-| Advance a missile one frame. It descends at its (slow) vertical speed while
its x weaves along a sine wave that drifts from the spawn column toward the
target city, with the wave amplitude damping to zero as it arrives.
-}
stepMissile : Int -> Missile -> Missile
stepMissile dt m =
    let
        newY =
            Vec2.getY m.position + Vec2.getY m.velocity * toFloat dt

        startY =
            Vec2.getY m.start

        targetY =
            Vec2.getY m.target

        progress =
            if targetY == startY then
                1

            else
                Basics.clamp 0 1 ((newY - startY) / (targetY - startY))

        baseX =
            Vec2.getX m.start + (Vec2.getX m.target - Vec2.getX m.start) * progress

        -- Weave wide up high, converge onto the city as it descends.
        amplitude =
            0.12 * (1 - progress)

        waveX =
            baseX + amplitude * sin (m.phase + newY * 16)
    in
    { m | position = Vec2.vec2 waveX newY }



-- EXPLOSIONS


{-| A fresh blast at a point: starts at zero radius, blooms, then fades. -}
explosionAt : Vec2.Vec2 -> Explosion
explosionAt position =
    { position = position
    , age = 0
    , duration = 0.45
    , maxRadius = 0.07
    }


{-| Current blast radius: grows from 0 to maxRadius and back over its lifetime. -}
currentExplosionRadius : Explosion -> Float
currentExplosionRadius e =
    e.maxRadius * sin (pi * Basics.clamp 0 1 (e.age / e.duration))



-- COLLISIONS


{-| Resolve a frame of collisions: interceptors and active blasts destroy
missiles (scoring points and spawning a new blast at each kill, so explosions
chain), surviving missiles that reach a city damage it, and dead cities are
removed. Spent interceptors detonate too.
-}
checkCollisions :
    List Missile
    -> List AntiMissile
    -> List City
    -> List Explosion
    -> Int
    -> CollisionResult
checkCollisions missiles antiMissiles cities explosions score =
    let
        -- Small forgiveness for a direct interceptor contact.
        blastRadius =
            0.015

        collides m am =
            Vec2.distance m.position am.position < (m.radius + am.radius + blastRadius)

        -- Only the inner core of the fireball is lethal, so a blast doesn't
        -- sweep up everything that merely grazes its visible edge.
        lethalFactor =
            0.55

        caughtInBlast m =
            List.any
                (\e -> Vec2.distance m.position e.position < (currentExplosionRadius e * lethalFactor + m.radius))
                explosions

        destroyed m =
            List.any (collides m) antiMissiles || caughtInBlast m

        ( shotDown, missilesAfterBlast ) =
            List.partition destroyed missiles

        -- An interceptor is spent once it connects with any incoming missile.
        ( spentInterceptors, survivingAntiMissiles ) =
            List.partition (\am -> List.any (\m -> collides m am) missiles) antiMissiles

        reachesCity m =
            List.any
                (\c -> Vec2.distance m.position c.position < (m.radius + c.radius))
                cities

        ( cityHits, survivingMissiles ) =
            List.partition reachesCity missilesAfterBlast

        damagedCities =
            cities
                |> List.map
                    (\c ->
                        if List.any (\m -> Vec2.distance m.position c.position < (m.radius + c.radius)) cityHits then
                            { c | health = c.health - 1 }

                        else
                            c
                    )
                |> List.filter (\c -> c.health > 0)

        -- Every kill (and each spent interceptor) blooms a fresh blast; a
        -- missile killed by a blast spawns its own, so explosions chain.
        newExplosions =
            List.map (\m -> explosionAt m.position) (shotDown ++ cityHits)
                ++ List.map (\am -> explosionAt am.position) spentInterceptors
    in
    { missiles = survivingMissiles
    , antiMissiles = survivingAntiMissiles
    , cities = damagedCities
    , explosions = explosions ++ newExplosions
    , score = score + List.length shotDown * 100
    }


-- VIEW


view : GameState -> Html Msg
view state =
    div
        [ Attr.class "relative w-100 h-100 overflow-hidden monospace"
        , Attr.style "background" "radial-gradient(ellipse at center, rgba(8,8,10,0.18) 0%, rgba(8,8,10,0.5) 100%)"
        , Attr.style "cursor" "none"

        -- Aim by moving, fire by clicking. Coordinates are normalized to the
        -- element's own size via offsetX / clientWidth so they map to game space.
        , Html.Events.on "mousemove" (mousePositionDecoder MouseMove)
        , Html.Events.on "mousedown" (Decode.succeed LaunchAntiMissile)
        ]
        (List.concat
            [ [ viewGround ]
            , List.map viewCity state.cities
            , List.map viewMissile state.missiles
            , List.map viewAntiMissile state.antiMissiles
            , List.map viewExplosion state.explosions
            , [ viewCrosshair state.mousePos
              , viewHud state
              ]
            ]
        )


{-| Decode a mouse event into game-space coordinates in [0,1] by dividing the
position within the target by the target's own size. No ports needed.
-}
mousePositionDecoder : (Float -> Float -> msg) -> Decode.Decoder msg
mousePositionDecoder toMsg =
    Decode.map4 (\ox oy w h -> toMsg (ox / Basics.max 1 w) (oy / Basics.max 1 h))
        (Decode.field "offsetX" Decode.float)
        (Decode.field "offsetY" Decode.float)
        (Decode.at [ "currentTarget", "clientWidth" ] Decode.float)
        (Decode.at [ "currentTarget", "clientHeight" ] Decode.float)


pct : Float -> String
pct v =
    String.fromFloat (v * 100) ++ "%"


{-| Absolutely-positioned, centered marker at a game-space point. -}
marker : Vec2.Vec2 -> Float -> List (Html.Attribute msg) -> Html msg
marker position sizePx extra =
    div
        ([ Attr.class "absolute"
         , Attr.style "left" (pct (Vec2.getX position))
         , Attr.style "top" (pct (Vec2.getY position))
         , Attr.style "width" (String.fromFloat sizePx ++ "px")
         , Attr.style "height" (String.fromFloat sizePx ++ "px")
         , Attr.style "transform" "translate(-50%, -50%)"

         -- Let pointer events fall through to the game container so the
         -- mousemove decoder always measures against the container, not a marker.
         , Attr.style "pointer-events" "none"
         ]
            ++ extra
        )
        []


viewGround : Html msg
viewGround =
    div
        [ Attr.class "absolute left-0 right-0"
        , Attr.style "bottom" "0"
        , Attr.style "height" "12%"
        , Attr.style "background" "linear-gradient(to top, rgba(60,60,90,0.5), transparent)"
        , Attr.style "border-top" "1px solid rgba(192,192,192,0.3)"
        , Attr.style "pointer-events" "none"
        ]
        []


viewCity : City -> Html msg
viewCity city =
    let
        color =
            if city.health >= 3 then
                "rgba(225, 225, 225, 0.9)"

            else if city.health == 2 then
                "rgba(150, 150, 150, 0.9)"

            else
                "rgba(95, 95, 95, 0.9)"
    in
    div [ Attr.style "pointer-events" "none" ]
        [ -- The base building
          div
            [ Attr.class "absolute"
            , Attr.style "left" (pct (Vec2.getX city.position))
            , Attr.style "top" (pct (Vec2.getY city.position))
            , Attr.style "width" "26px"
            , Attr.style "height" "18px"
            , Attr.style "transform" "translate(-50%, -50%)"
            , Attr.style "background" color
            , Attr.style "border" "1px solid rgba(255,255,255,0.5)"
            , Attr.style "box-shadow" ("0 0 10px " ++ color)
            ]
            []
        , -- Remaining interceptor ammo, just below the base
          div
            [ Attr.class "absolute f7 fw6 tracked tc"
            , Attr.style "left" (pct (Vec2.getX city.position))
            , Attr.style "top" (pct (Vec2.getY city.position))
            , Attr.style "transform" "translate(-50%, 90%)"
            , Attr.style "color"
                (if city.ammo == 0 then
                    "rgba(110, 110, 110, 0.95)"

                 else
                    "rgba(205, 205, 205, 0.9)"
                )
            , Attr.style "text-shadow" "0 0 6px rgba(0,0,0,0.8)"
            ]
            [ text (String.fromInt city.ammo) ]
        ]


viewMissile : Missile -> Html msg
viewMissile m =
    marker m.position
        7
        [ Attr.style "border-radius" "50%"
        , Attr.style "background" "rgba(240, 240, 240, 0.95)"
        , Attr.style "box-shadow" "0 0 8px rgba(225, 225, 225, 0.9)"
        ]


viewExplosion : Explosion -> Html msg
viewExplosion e =
    let
        -- Diameter as a percentage of the container width; aspect-ratio keeps
        -- it circular regardless of the container's shape.
        diameterPct =
            currentExplosionRadius e * 2 * 100

        fade =
            1 - Basics.clamp 0 1 (e.age / e.duration)
    in
    div
        [ Attr.class "absolute"
        , Attr.style "left" (pct (Vec2.getX e.position))
        , Attr.style "top" (pct (Vec2.getY e.position))
        , Attr.style "width" (String.fromFloat diameterPct ++ "%")
        , Attr.style "aspect-ratio" "1"
        , Attr.style "transform" "translate(-50%, -50%)"
        , Attr.style "border-radius" "50%"
        , Attr.style "opacity" (String.fromFloat fade)
        , Attr.style "background"
            "radial-gradient(circle, rgba(255,255,255,0.95) 0%, rgba(200,200,200,0.6) 45%, rgba(140,140,140,0.25) 75%, rgba(120,120,120,0) 100%)"
        , Attr.style "pointer-events" "none"
        ]
        []


viewAntiMissile : AntiMissile -> Html msg
viewAntiMissile am =
    let
        -- A few faint dots interpolated from the launch base to the bullet,
        -- brightest near the head and fading toward the origin.
        steps =
            6

        trail =
            List.range 1 steps
                |> List.map
                    (\i ->
                        let
                            t =
                                toFloat i / toFloat (steps + 1)

                            dotPos =
                                Vec2.add am.origin (Vec2.scale t (Vec2.sub am.position am.origin))
                        in
                        marker dotPos
                            3
                            [ Attr.style "border-radius" "50%"
                            , Attr.style "background"
                                ("rgba(175, 175, 175, " ++ String.fromFloat (t * 0.3) ++ ")")
                            ]
                    )

        bullet =
            marker am.position
                9
                [ Attr.style "border-radius" "50%"
                , Attr.style "background" "rgba(175, 175, 175, 0.95)"
                , Attr.style "box-shadow" "0 0 12px rgba(175, 175, 175, 0.85)"
                , Attr.style "opacity" (String.fromFloat (Basics.clamp 0.2 1 am.life))
                ]
    in
    div [] (trail ++ [ bullet ])


viewCrosshair : Vec2.Vec2 -> Html msg
viewCrosshair position =
    marker position
        18
        [ Attr.style "border" "1px solid rgba(192,192,192,0.8)"
        , Attr.style "border-radius" "50%"
        , Attr.style "box-shadow" "0 0 6px rgba(192,192,192,0.5)"
        ]


viewHud : GameState -> Html msg
viewHud state =
    div [ Attr.style "pointer-events" "none" ]
        [ div
            [ Attr.class "absolute top-0 left-0 pa2 f6 tracked"
            , Attr.style "color" "rgba(192,192,192,0.9)"
            , Attr.style "text-shadow" "0 0 8px rgba(192,192,192,0.35)"
            ]
            [ text ("SCORE " ++ String.fromInt state.score ++ "   CITIES " ++ String.fromInt (List.length state.cities)) ]
        , div
            [ Attr.class "absolute top-0 w-100 pa2 f6 tracked tc"
            , Attr.style "color" "rgba(192,192,192,0.9)"
            , Attr.style "text-shadow" "0 0 8px rgba(192,192,192,0.35)"
            ]
            [ text ("WAVE " ++ String.fromInt state.wave) ]
        , if state.gameOver then
            div
                [ Attr.class "absolute f3 fw6 tracked"
                , Attr.style "left" "50%"
                , Attr.style "top" "50%"
                , Attr.style "transform" "translate(-50%, -50%)"
                , Attr.style "color" "rgba(230, 230, 230, 0.95)"
                , Attr.style "text-shadow" "0 0 14px rgba(200, 200, 200, 0.5)"
                ]
                [ text "GAME OVER" ]

          else if inBreather state then
            div
                [ Attr.class "absolute tc"
                , Attr.style "left" "50%"
                , Attr.style "top" "50%"
                , Attr.style "transform" "translate(-50%, -50%)"
                , Attr.style "color" "rgba(225, 225, 225, 0.95)"
                , Attr.style "text-shadow" "0 0 16px rgba(200, 200, 200, 0.5)"
                ]
                [ div [ Attr.class "f2 fw6 tracked" ] [ text ("WAVE " ++ String.fromInt state.wave) ]
                , div [ Attr.class "f6 tracked mt2 o-70" ] [ text "GET READY" ]
                ]

          else
            text ""
        ]


{-| True during the pause between waves: nothing airborne, the spawn timer is
still counting down, and none of this wave's missiles have launched yet.
-}
inBreather : GameState -> Bool
inBreather state =
    not state.gameOver
        && List.isEmpty state.missiles
        && (state.spawnCooldown > 0)
        && (state.toSpawn == missilesForWave state.wave state.cities)


-- SUBSCRIPTIONS


subscriptions : GameState -> Sub Msg
subscriptions _ =
    Browser.Events.onAnimationFrame Tick
