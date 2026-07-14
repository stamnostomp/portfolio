module Pages.Games.RatSnatcher exposing (GameState, Msg, init, subscriptions, update, view)

import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes as Attr
import Html.Events
import Json.Decode as Decode
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import Ports
import Random
import Time
import WebGL
import WebGL.Settings.DepthTest as DepthTest



-- MODEL


type alias GameState =
    { camPos : Vec3
    , yaw : Float
    , pitch : Float
    , keys : Keys
    , locked : Bool
    , lookDx : Float
    , lookDy : Float
    , velY : Float
    , fps : Float
    , time : Time.Posix
    , seed : Random.Seed
    , phase : Phase
    , rats : List Rat
    , hammerX : Float
    , hammerZ : Float
    , swing : Float
    , swings : Int
    , whacked : Int
    , elapsed : Float
    , splats : List Splat
    }


type Phase
    = Carry
    | Dump { t : Float, fromPos : Vec3, fromYaw : Float, fromPitch : Float }
    | Whack
    | Cleared


type alias Rat =
    { x : Float
    , z : Float
    , dir : Float
    , speed : Float
    , turnIn : Float
    , panic : Float
    , squash : Float -- 0 alive; counts down while flattening, then removed
    , gait : Float
    }


{-| A burst fragment from a whacked rat. -}
type alias Splat =
    { pos : Vec3, vel : Vec3, t : Float }


type alias Keys =
    { f : Bool, b : Bool, l : Bool, r : Bool, jump : Bool }


type Msg
    = Tick Time.Posix
    | Look Float Float
    | Fire
    | Key Bool String
    | RequestLock
    | LockChanged Bool



-- CONSTANTS


roomHalfW : Float
roomHalfW =
    8


roomHalfD : Float
roomHalfD =
    6


wallHeight : Float
wallHeight =
    3.4


{-| Height of the table's walking surface. -}
tableTop : Float
tableTop =
    0.95


tableHalfX : Float
tableHalfX =
    1.8


tableHalfZ : Float
tableHalfZ =
    1.0


playerRadius : Float
playerRadius =
    0.4


eyeHeight : Float
eyeHeight =
    1.6


moveSpeed : Float
moveSpeed =
    0.006


lookSpeed : Float
lookSpeed =
    0.004


{-| Time constant (ms) for draining accumulated mouse deltas. -}
lookSmoothing : Float
lookSmoothing =
    40


gravity : Float
gravity =
    0.000025


jumpSpeed : Float
jumpSpeed =
    0.0075


{-| Being within this far of the table edge lets you dump the box. -}
dumpRange : Float
dumpRange =
    1.2


{-| Duration of the camera glide from first person to the table view. -}
dumpTime : Float
dumpTime =
    900


ratCount : Int
ratCount =
    10


{-| How long a flattened rat lingers before disappearing (ms). -}
squashTime : Float
squashTime =
    450


{-| Hammer strikes kill rats within this distance of the mark. -}
whackRadius : Float
whackRadius =
    0.45


{-| Surviving rats this close to a strike bolt away from it. -}
panicRadius : Float
panicRadius =
    1.3


panicTime : Float
panicTime =
    900


{-| Table units the hammer mark moves per pixel of mouse travel. -}
hammerSens : Float
hammerSens =
    0.0035


{-| How long splat fragments live, in ms. -}
splatTtl : Float
splatTtl =
    500


{-| Rats keep this far inside the tabletop edge. -}
ratBoundX : Float
ratBoundX =
    tableHalfX - 0.25


ratBoundZ : Float
ratBoundZ =
    tableHalfZ - 0.2


{-| Fixed camera for the whacking phase, at the table's near edge. -}
vantagePos : Vec3
vantagePos =
    vec3 0 3 2.7


vantageYaw : Float
vantageYaw =
    pi


vantagePitch : Float
vantagePitch =
    -0.65



-- INIT


init : ( GameState, Cmd Msg )
init =
    ( { camPos = vec3 0 eyeHeight 4.6
      , yaw = pi -- face the table at the room's center
      , pitch = 0
      , keys = Keys False False False False False
      , locked = False
      , lookDx = 0
      , lookDy = 0
      , velY = 0
      , fps = 60
      , time = Time.millisToPosix 0
      , seed = Random.initialSeed 7
      , phase = Carry
      , rats = []
      , hammerX = 0
      , hammerZ = 0
      , swing = 0
      , swings = 0
      , whacked = 0
      , elapsed = 0
      , splats = []
      }
    , Cmd.none
    )


ratGen : Random.Generator Rat
ratGen =
    Random.map3
        (\( x, z ) ( dir, speed ) ( turnIn, gait ) ->
            { x = x
            , z = z
            , dir = dir
            , speed = speed
            , turnIn = turnIn
            , panic = 0
            , squash = 0
            , gait = gait
            }
        )
        (Random.pair (Random.float -0.7 0.7) (Random.float -0.45 0.45))
        (Random.pair (Random.float 0 (2 * pi)) (Random.float 0.0015 0.0024))
        (Random.pair (Random.float 250 1000) (Random.float 0 (2 * pi)))



-- UPDATE


update : Msg -> GameState -> ( GameState, Cmd Msg )
update msg state =
    case msg of
        Tick newTime ->
            let
                raw =
                    Time.posixToMillis newTime - Time.posixToMillis state.time

                fps =
                    if raw > 0 then
                        0.9 * state.fps + 0.1 * (1000 / toFloat raw)

                    else
                        state.fps
            in
            ( step (toFloat (Basics.clamp 0 32 raw)) { state | time = newTime, fps = fps }
            , Cmd.none
            )

        Look dx dy ->
            if not state.locked then
                ( state, Cmd.none )

            else
                case state.phase of
                    Carry ->
                        -- Deltas are accumulated here and drained smoothly in
                        -- `stepCarry`, so coarse events don't read as jumps.
                        ( { state | lookDx = state.lookDx + dx, lookDy = state.lookDy + dy }
                        , Cmd.none
                        )

                    Dump _ ->
                        ( state, Cmd.none )

                    _ ->
                        -- Camera is parked on the table: the mouse drives
                        -- the hammer mark across the tabletop instead.
                        ( { state
                            | hammerX = Basics.clamp -ratBoundX ratBoundX (state.hammerX + dx * hammerSens)
                            , hammerZ = Basics.clamp -ratBoundZ ratBoundZ (state.hammerZ + dy * hammerSens)
                          }
                        , Cmd.none
                        )

        Key isDown raw ->
            let
                k =
                    state.keys

                keys =
                    -- Matches both event.code ("keyw") and event.key ("w"),
                    -- so physical WASD works on any keyboard layout.
                    case String.toLower raw of
                        "keyw" ->
                            { k | f = isDown }

                        "w" ->
                            { k | f = isDown }

                        "arrowup" ->
                            { k | f = isDown }

                        "keys" ->
                            { k | b = isDown }

                        "s" ->
                            { k | b = isDown }

                        "arrowdown" ->
                            { k | b = isDown }

                        "keya" ->
                            { k | l = isDown }

                        "a" ->
                            { k | l = isDown }

                        "arrowleft" ->
                            { k | l = isDown }

                        "keyd" ->
                            { k | r = isDown }

                        "d" ->
                            { k | r = isDown }

                        "arrowright" ->
                            { k | r = isDown }

                        "space" ->
                            { k | jump = isDown }

                        " " ->
                            { k | jump = isDown }

                        _ ->
                            k
            in
            ( { state | keys = keys }, Cmd.none )

        Fire ->
            if not state.locked then
                ( state, Cmd.none )

            else
                fire state

        RequestLock ->
            ( state, Ports.requestPointerLock viewId )

        LockChanged locked ->
            ( { state | locked = locked, lookDx = 0, lookDy = 0 }, Cmd.none )


fire : GameState -> ( GameState, Cmd Msg )
fire state =
    case state.phase of
        Carry ->
            if nearTable state.camPos then
                -- Tip the box out: rats hit the table and the camera
                -- glides up to its fixed vantage over the action.
                let
                    ( rats, seed2 ) =
                        Random.step (Random.list ratCount ratGen)
                            (Random.initialSeed (Time.posixToMillis state.time))
                in
                ( { state
                    | phase =
                        Dump
                            { t = dumpTime
                            , fromPos = state.camPos
                            , fromYaw = state.yaw
                            , fromPitch = state.pitch
                            }
                    , rats = rats
                    , seed = seed2
                    , hammerX = 0
                    , hammerZ = 0
                    , swing = 0
                    , swings = 0
                    , whacked = 0
                    , elapsed = 0
                    , splats = []
                  }
                , Cmd.none
                )

            else
                ( state, Cmd.none )

        Dump _ ->
            ( state, Cmd.none )

        Whack ->
            if state.swing > 0.35 then
                -- Still recovering from the last swing.
                ( state, Cmd.none )

            else
                let
                    ( rats2, killed ) =
                        whackAt state.hammerX state.hammerZ state.rats
                in
                ( { state
                    | swing = 1
                    , swings = state.swings + 1
                    , whacked = state.whacked + List.length killed
                    , rats = rats2
                    , splats = List.concatMap spawnSplats killed ++ state.splats
                  }
                , Cmd.none
                )

        Cleared ->
            -- Click to restart, keeping the pointer lock and clock.
            let
                ( fresh, cmd ) =
                    init
            in
            ( { fresh | locked = state.locked, time = state.time }, cmd )


{-| Flatten every live rat under the mark; panic the near misses. -}
whackAt : Float -> Float -> List Rat -> ( List Rat, List Vec3 )
whackAt hx hz rats =
    List.foldr
        (\r ( acc, killed ) ->
            let
                dx =
                    r.x - hx

                dz =
                    r.z - hz

                d2 =
                    dx * dx + dz * dz
            in
            if r.squash <= 0 && d2 <= whackRadius * whackRadius then
                ( { r | squash = squashTime } :: acc
                , vec3 r.x tableTop r.z :: killed
                )

            else if r.squash <= 0 && d2 <= panicRadius * panicRadius then
                ( { r | panic = panicTime, dir = atan2 dx dz } :: acc, killed )

            else
                ( r :: acc, killed )
        )
        ( [], [] )
        rats


{-| Fragments flung outward and up from a flattened rat. -}
spawnSplats : Vec3 -> List Splat
spawnSplats p =
    let
        center =
            Vec3.add p (vec3 0 0.12 0)
    in
    List.map
        (\( dx, dy, dz ) ->
            { pos = center
            , vel = Vec3.scale 0.0035 (Vec3.normalize (vec3 dx dy dz))
            , t = splatTtl
            }
        )
        [ ( 1, 0.5, 0 )
        , ( -1, 0.5, 0 )
        , ( 0, 0.5, 1 )
        , ( 0, 0.5, -1 )
        , ( 0.7, 1, 0.7 )
        , ( -0.7, 1, 0.7 )
        , ( 0.7, 1, -0.7 )
        , ( -0.7, 1, -0.7 )
        ]


{-| Advance the game one frame. -}
step : Float -> GameState -> GameState
step dt state =
    case state.phase of
        Carry ->
            stepCarry dt state

        Dump d ->
            stepDump dt d state

        Whack ->
            stepTable dt True state

        Cleared ->
            stepTable dt False state


{-| First-person movement while carrying the box (same controller as
GOB KILLER, on a flat floor with the table as the only obstacle).
-}
stepCarry : Float -> GameState -> GameState
stepCarry dt state =
    let
        -- Drain a dt-proportional share of the pending mouse deltas so
        -- quantized movement events become continuous rotation.
        drain =
            1 - Basics.e ^ (-dt / lookSmoothing)

        useDx =
            state.lookDx * drain

        useDy =
            state.lookDy * drain

        yaw =
            state.yaw - useDx * lookSpeed

        pitch =
            Basics.clamp -1.4 1.4 (state.pitch - useDy * lookSpeed)

        fwd =
            forwardH yaw

        right =
            Vec3.normalize (Vec3.cross fwd (vec3 0 1 0))

        wish =
            Vec3.add
                (Vec3.scale (boolF state.keys.f - boolF state.keys.b) fwd)
                (Vec3.scale (boolF state.keys.r - boolF state.keys.l) right)

        move =
            if Vec3.length wish > 0 then
                Vec3.scale (moveSpeed * dt) (Vec3.normalize wish)

            else
                vec3 0 0 0

        x0 =
            Vec3.getX state.camPos

        z0 =
            Vec3.getZ state.camPos

        wantX =
            x0 + Vec3.getX move

        wantZ =
            z0 + Vec3.getZ move

        -- Resolve each axis independently so you slide along walls.
        newX =
            if walkable wantX z0 then
                wantX

            else
                x0

        newZ =
            if walkable newX wantZ then
                wantZ

            else
                z0

        feet0 =
            Vec3.getY state.camPos - eyeHeight

        velY =
            if feet0 <= 0.02 && state.keys.jump then
                jumpSpeed

            else
                state.velY - gravity * dt

        wantY =
            feet0 + velY * dt

        ( newFeet, newVelY ) =
            if velY <= 0 && wantY <= 0 then
                ( 0, 0 )

            else
                ( wantY, velY )
    in
    { state
        | camPos = vec3 newX (newFeet + eyeHeight) newZ
        , yaw = yaw
        , pitch = pitch
        , lookDx = state.lookDx - useDx
        , lookDy = state.lookDy - useDy
        , velY = newVelY
    }


{-| Standing room: inside the walls and not inside the table. -}
walkable : Float -> Float -> Bool
walkable x z =
    (abs x <= roomHalfW - playerRadius)
        && (abs z <= roomHalfD - playerRadius)
        && not
            ((abs x < tableHalfX + playerRadius)
                && (abs z < tableHalfZ + playerRadius)
            )


{-| Distance from the player to the table's footprint. -}
nearTable : Vec3 -> Bool
nearTable camPos =
    let
        dx =
            Basics.max 0 (abs (Vec3.getX camPos) - tableHalfX)

        dz =
            Basics.max 0 (abs (Vec3.getZ camPos) - tableHalfZ)
    in
    dx * dx + dz * dz <= dumpRange * dumpRange


{-| Glide the camera from wherever the dump happened to the fixed
vantage while the freshly poured rats already scurry below.
-}
stepDump : Float -> { t : Float, fromPos : Vec3, fromYaw : Float, fromPitch : Float } -> GameState -> GameState
stepDump dt d state =
    let
        t2 =
            d.t - dt

        p =
            Basics.clamp 0 1 (1 - t2 / dumpTime)

        s =
            p * p * (3 - 2 * p)

        ( rats2, seed2 ) =
            stepRats dt state.seed state.rats
    in
    if t2 <= 0 then
        { state
            | phase = Whack
            , camPos = vantagePos
            , yaw = vantageYaw
            , pitch = vantagePitch
            , rats = rats2
            , seed = seed2
        }

    else
        { state
            | phase = Dump { d | t = t2 }
            , camPos = Vec3.add d.fromPos (Vec3.scale s (Vec3.sub vantagePos d.fromPos))
            , yaw = d.fromYaw + s * angDiff d.fromYaw vantageYaw
            , pitch = d.fromPitch + s * (vantagePitch - d.fromPitch)
            , rats = rats2
            , seed = seed2
        }


{-| The locked-on-the-table phases: rats scurry, the hammer recovers,
splats fly. The clock only runs while there's something left to whack.
-}
stepTable : Float -> Bool -> GameState -> GameState
stepTable dt running state =
    let
        ( rats2, seed2 ) =
            stepRats dt state.seed state.rats

        splats2 =
            List.filterMap
                (\g ->
                    let
                        t2 =
                            g.t - dt
                    in
                    if t2 <= 0 then
                        Nothing

                    else
                        Just
                            { pos = Vec3.add g.pos (Vec3.scale dt g.vel)
                            , vel = Vec3.add g.vel (vec3 0 (-gravity * dt) 0)
                            , t = t2
                            }
                )
                state.splats

        cleared =
            running && not (List.any (\r -> r.squash <= 0) rats2)
    in
    { state
        | rats = rats2
        , seed = seed2
        , splats = splats2
        , swing = state.swing * Basics.e ^ (-dt / 90)
        , elapsed =
            if running then
                state.elapsed + dt

            else
                state.elapsed
        , phase =
            if cleared then
                Cleared

            else
                state.phase
    }


stepRats : Float -> Random.Seed -> List Rat -> ( List Rat, Random.Seed )
stepRats dt seed rats =
    List.foldr
        (\r ( acc, s ) ->
            case stepRat dt s r of
                ( Just r2, s2 ) ->
                    ( r2 :: acc, s2 )

                ( Nothing, s2 ) ->
                    ( acc, s2 )
        )
        ( [], seed )
        rats


{-| One rat, one frame: wander on a heading that changes at random
intervals, bounce off the table edges, sprint while panicked, and
finish flattening if whacked. Heading dir moves along (sin, cos).
-}
stepRat : Float -> Random.Seed -> Rat -> ( Maybe Rat, Random.Seed )
stepRat dt seed r =
    if r.squash > 0 then
        let
            s2 =
                r.squash - dt
        in
        if s2 <= 0 then
            ( Nothing, seed )

        else
            ( Just { r | squash = s2 }, seed )

    else
        let
            ( dir1, turnIn1, seed1 ) =
                if r.turnIn - dt <= 0 && r.panic <= 0 then
                    let
                        ( ( nd, nt ), s1 ) =
                            Random.step
                                (Random.pair (Random.float 0 (2 * pi)) (Random.float 250 1000))
                                seed
                    in
                    ( nd, nt, s1 )

                else
                    ( r.dir, Basics.max 0 (r.turnIn - dt), seed )

            eff =
                r.speed
                    * (if r.panic > 0 then
                        2.2

                       else
                        1
                      )

            nx0 =
                r.x + sin dir1 * eff * dt

            nz0 =
                r.z + cos dir1 * eff * dt

            ( nx, dirX ) =
                if nx0 < -ratBoundX || nx0 > ratBoundX then
                    ( Basics.clamp -ratBoundX ratBoundX nx0, negate dir1 )

                else
                    ( nx0, dir1 )

            ( nz, dir2 ) =
                if nz0 < -ratBoundZ || nz0 > ratBoundZ then
                    ( Basics.clamp -ratBoundZ ratBoundZ nz0, pi - dirX )

                else
                    ( nz0, dirX )
        in
        ( Just
            { r
                | x = nx
                , z = nz
                , dir = dir2
                , turnIn = turnIn1
                , panic = Basics.max 0 (r.panic - dt)
            }
        , seed1
        )



-- MATH HELPERS


boolF : Bool -> Float
boolF b =
    if b then
        1

    else
        0


forwardH : Float -> Vec3
forwardH yaw =
    vec3 (sin yaw) 0 (cos yaw)


lookDir : Float -> Float -> Vec3
lookDir yaw pitch =
    Vec3.normalize (vec3 (cos pitch * sin yaw) (sin pitch) (cos pitch * cos yaw))


{-| Signed shortest-arc difference between two angles. -}
angDiff : Float -> Float -> Float
angDiff from to =
    atan2 (sin (to - from)) (cos (to - from))



-- VIEW


view : GameState -> Html Msg
view state =
    let
        proj =
            Mat4.makePerspective 70 (1600 / 900) 0.1 100

        viewM =
            Mat4.makeLookAt state.camPos (Vec3.add state.camPos (lookDir state.yaw state.pitch)) (vec3 0 1 0)

        mvp model =
            Mat4.mul proj (Mat4.mul viewM model)

        boxEntity shade tint o =
            let
                model =
                    Mat4.mul (Mat4.makeTranslate o.center) (Mat4.makeScale (Vec3.scale 2 o.half))
            in
            entity (mvp model) model shade 0 tint cubeMesh

        floorEntity =
            entity (mvp Mat4.identity) Mat4.identity 0.22 1 white floorMesh

        wallEntities =
            List.map (boxEntity 0.5 white)
                [ { center = vec3 0 (wallHeight / 2) -(roomHalfD + 0.1), half = vec3 (roomHalfW + 0.2) (wallHeight / 2) 0.1 }
                , { center = vec3 0 (wallHeight / 2) (roomHalfD + 0.1), half = vec3 (roomHalfW + 0.2) (wallHeight / 2) 0.1 }
                , { center = vec3 -(roomHalfW + 0.1) (wallHeight / 2) 0, half = vec3 0.1 (wallHeight / 2) roomHalfD }
                , { center = vec3 (roomHalfW + 0.1) (wallHeight / 2) 0, half = vec3 0.1 (wallHeight / 2) roomHalfD }
                ]

        ceilingEntity =
            boxEntity 0.5 white { center = vec3 0 (wallHeight + 0.05) 0, half = vec3 (roomHalfW + 0.2) 0.05 (roomHalfD + 0.2) }

        -- A bright panel in the ceiling, the room's only decoration.
        lightEntity =
            boxEntity 2.6 white { center = vec3 0 (wallHeight - 0.02) 0, half = vec3 0.9 0.02 0.6 }

        wood =
            vec3 0.72 0.52 0.34

        tableEntities =
            boxEntity 0.75 wood { center = vec3 0 (tableTop - 0.06) 0, half = vec3 tableHalfX 0.06 tableHalfZ }
                :: List.map
                    (\( lx, lz ) ->
                        boxEntity 0.55 wood { center = vec3 lx ((tableTop - 0.12) / 2) lz, half = vec3 0.06 ((tableTop - 0.12) / 2) 0.06 }
                    )
                    [ ( tableHalfX - 0.15, tableHalfZ - 0.15 )
                    , ( -(tableHalfX - 0.15), tableHalfZ - 0.15 )
                    , ( tableHalfX - 0.15, -(tableHalfZ - 0.15) )
                    , ( -(tableHalfX - 0.15), -(tableHalfZ - 0.15) )
                    ]

        ms =
            toFloat (Time.posixToMillis state.time)

        ratEntities =
            List.concatMap (viewRat mvp ms) state.rats

        splatEntities =
            List.map
                (\g ->
                    let
                        s =
                            0.015 + 0.06 * (g.t / splatTtl)

                        model =
                            Mat4.mul (Mat4.makeTranslate g.pos) (Mat4.makeScale (vec3 s s s))
                    in
                    entity (mvp model) model 0.9 0 (vec3 0.75 0.12 0.12) cubeMesh
                )
                state.splats

        heldItem =
            case state.phase of
                Carry ->
                    viewBox proj state

                _ ->
                    []

        hammerEntities =
            case state.phase of
                Whack ->
                    viewHammer mvp state

                Cleared ->
                    viewHammer mvp state

                _ ->
                    []
    in
    div
        [ Attr.id viewId
        , Attr.class "relative w-100 h-100 overflow-hidden monospace"
        , Attr.style "cursor"
            (if state.locked then
                "none"

             else
                "crosshair"
            )
        , Html.Events.on "mousemove" lookDecoder
        , Html.Events.on "mousedown"
            (Decode.succeed
                (if state.locked then
                    Fire

                 else
                    RequestLock
                )
            )
        ]
        [ WebGL.toHtmlWith
            [ WebGL.depth 1, WebGL.antialias, WebGL.clearColor 0.04 0.04 0.05 1 ]
            [ Attr.width 1600
            , Attr.height 900
            , Attr.style "width" "100%"
            , Attr.style "height" "100%"
            , Attr.style "display" "block"
            ]
            (floorEntity
                :: ceilingEntity
                :: lightEntity
                :: wallEntities
                ++ tableEntities
                ++ ratEntities
                ++ splatEntities
                ++ hammerEntities
                ++ heldItem
            )
        , if state.phase == Carry then
            viewCrosshair

          else
            text ""
        , viewHud state
        , if state.phase == Carry && state.locked && nearTable state.camPos then
            viewPrompt "CLICK TO EMPTY BOX"

          else
            text ""
        , if state.phase == Cleared then
            viewClearedScreen state

          else
            text ""
        , if state.locked then
            text ""

          else
            viewPrompt "CLICK TO CAPTURE MOUSE"
        ]


viewId : String
viewId =
    "rat-snatcher-view"


lookDecoder : Decode.Decoder Msg
lookDecoder =
    Decode.map2 Look
        (Decode.field "movementX" Decode.float)
        (Decode.field "movementY" Decode.float)


{-| A little rat scurrying on the tabletop, built from tinted boxes.
Whacked rats flatten out before vanishing.
-}
viewRat : (Mat4 -> Mat4) -> Float -> Rat -> List WebGL.Entity
viewRat mvp ms r =
    let
        dying =
            if r.squash > 0 then
                1 - r.squash / squashTime

            else
                0

        squashY =
            Basics.max 0.15 (1 - dying * 1.1)

        squashXZ =
            1 + dying * 0.9

        scurry =
            if r.squash > 0 then
                0

            else
                abs (sin (ms * 0.02 + r.gait)) * 0.02

        waddle =
            if r.squash > 0 then
                0

            else
                sin (ms * 0.02 + r.gait) * 0.12

        root =
            Mat4.mul (Mat4.makeTranslate (vec3 r.x (tableTop + scurry) r.z))
                (Mat4.mul (Mat4.makeRotate (r.dir + waddle) (vec3 0 1 0))
                    (Mat4.makeScale (vec3 squashXZ squashY squashXZ))
                )

        part shade tint pos size =
            let
                model =
                    Mat4.mul root (Mat4.mul (Mat4.makeTranslate pos) (Mat4.makeScale size))
            in
            entity (mvp model) model shade 0 tint cubeMesh

        gray =
            vec3 0.55 0.55 0.6

        pink =
            vec3 0.85 0.55 0.55

        black =
            vec3 0.05 0.05 0.05
    in
    [ -- body
      part 0.6 gray (vec3 0 0.09 -0.02) (vec3 0.16 0.13 0.34)

    -- head
    , part 0.65 gray (vec3 0 0.1 0.2) (vec3 0.12 0.11 0.14)

    -- nose
    , part 0.6 pink (vec3 0 0.08 0.29) (vec3 0.05 0.05 0.06)

    -- round ears
    , part 0.55 pink (vec3 -0.05 0.18 0.15) (vec3 0.05 0.07 0.02)
    , part 0.55 pink (vec3 0.05 0.18 0.15) (vec3 0.05 0.07 0.02)

    -- tail trailing behind
    , part 0.55 pink (vec3 0 0.06 -0.33) (vec3 0.025 0.025 0.3)

    -- beady black eyes
    , part 0.05 black (vec3 -0.04 0.13 0.265) (vec3 0.03 0.03 0.02)
    , part 0.05 black (vec3 0.04 0.13 0.265) (vec3 0.03 0.03 0.02)
    ]


{-| The whacking hammer, a classic claw hammer: a dark mark shows where
it will land, and the hammer pivots down from behind the mark when
swung, striking face first with the nail puller curving up behind.
-}
viewHammer : (Mat4 -> Mat4) -> GameState -> List WebGL.Entity
viewHammer mvp state =
    let
        -- Raised at rest; at a swing's peak the face meets the tabletop.
        tilt =
            0.33 + (1 - state.swing) * 0.75

        -- Cocked a touch clockwise so the claw end sits to the player's right.
        cant =
            degrees 5

        root =
            Mat4.mul (Mat4.makeTranslate (vec3 state.hammerX (tableTop + 0.05) (state.hammerZ + 0.75)))
                (Mat4.mul (Mat4.makeRotate cant (vec3 0 1 0))
                    (Mat4.makeRotate tilt (vec3 1 0 0))
                )

        partRot mesh shade tint pos rot size =
            let
                model =
                    Mat4.mul root
                        (Mat4.mul (Mat4.makeTranslate pos)
                            (Mat4.mul rot (Mat4.makeScale size))
                        )
            in
            entity (mvp model) model shade 0 tint mesh

        part mesh shade tint pos size =
            partRot mesh shade tint pos Mat4.identity size

        -- Turns the Z-axis prism into a vertical barrel.
        upright =
            Mat4.makeRotate (pi / 2) (vec3 1 0 0)

        -- Leans the claw prongs up and back over the handle.
        clawTilt =
            Mat4.makeRotate 0.7 (vec3 1 0 0)

        markModel =
            Mat4.mul (Mat4.makeTranslate (vec3 state.hammerX (tableTop + 0.006) state.hammerZ))
                (Mat4.makeScale (vec3 0.36 1 0.36))

        wood =
            vec3 0.72 0.52 0.32

        steel =
            vec3 0.6 0.62 0.68
    in
    [ -- round landing mark on the tabletop, matching the hammer's face
      entity (mvp markModel) markModel 0.1 0 white discMesh

    -- wooden handle
    , part prismMesh 0.7 wood (vec3 0 0 -0.34) (vec3 0.06 0.06 0.68)

    -- grip band
    , part cubeMesh 0.4 wood (vec3 0 0 -0.06) (vec3 0.07 0.07 0.12)

    -- eye of the head, seated on the handle's end
    , part cubeMesh 0.85 steel (vec3 0 0.01 -0.72) (vec3 0.09 0.12 0.13)

    -- neck dropping to the striking face
    , partRot prismMesh 0.85 steel (vec3 0 -0.12 -0.72) upright (vec3 0.09 0.09 0.26)

    -- striking face, slightly flared
    , partRot prismMesh 0.9 steel (vec3 0 -0.26 -0.72) upright (vec3 0.13 0.13 0.05)

    -- claw root
    , part cubeMesh 0.8 steel (vec3 0 0.08 -0.69) (vec3 0.08 0.08 0.09)

    -- nail puller: two prongs curving up and back with a gap between
    , partRot cubeMesh 0.8 steel (vec3 -0.035 0.14 -0.63) clawTilt (vec3 0.03 0.2 0.05)
    , partRot cubeMesh 0.8 steel (vec3 0.035 0.14 -0.63) clawTilt (vec3 0.03 0.2 0.05)
    ]


{-| First-person cardboard box full of rats, rendered in view space so
it sticks to the camera. A squashed depth range draws it over the scene.
-}
viewBox : Mat4 -> GameState -> List WebGL.Entity
viewBox proj state =
    let
        ms =
            toFloat (Time.posixToMillis state.time)

        moving =
            state.keys.f || state.keys.b || state.keys.l || state.keys.r

        bob =
            if moving then
                sin (ms * 0.012) * 0.02

            else
                sin (ms * 0.003) * 0.008

        vm =
            Mat4.makeTranslate (vec3 0 (-0.42 + bob) -0.95)

        part mesh shade tint pos size =
            let
                model =
                    Mat4.mul vm (Mat4.mul (Mat4.makeTranslate pos) (Mat4.makeScale size))
            in
            WebGL.entityWith
                [ DepthTest.less { write = True, near = 0, far = 0.1 } ]
                vertexShader
                fragmentShader
                mesh
                { mvp = Mat4.mul proj model, model = model, shade = shade, grid = 0, tint = tint }

        cardboard =
            vec3 0.78 0.62 0.42

        gray =
            vec3 0.55 0.55 0.6

        pink =
            vec3 0.85 0.55 0.55

        black =
            vec3 0.05 0.05 0.05

        -- A rat peeking over the rim, popping up and ducking down.
        peeker px phase =
            let
                py =
                    0.02 + Basics.max 0 (sin (ms * 0.004 + phase)) * 0.1
            in
            [ part cubeMesh 0.6 gray (vec3 px py 0.02) (vec3 0.11 0.1 0.11)
            , part cubeMesh 0.55 pink (vec3 (px - 0.045) (py + 0.07) 0.02) (vec3 0.03 0.04 0.015)
            , part cubeMesh 0.55 pink (vec3 (px + 0.045) (py + 0.07) 0.02) (vec3 0.03 0.04 0.015)
            , part cubeMesh 0.05 black (vec3 (px - 0.03) (py + 0.02) 0.08) (vec3 0.02 0.02 0.015)
            , part cubeMesh 0.05 black (vec3 (px + 0.03) (py + 0.02) 0.08) (vec3 0.02 0.02 0.015)
            ]
    in
    [ -- arms reaching in from the bottom corners
      part prismMesh 0.3 white (vec3 -0.34 -0.18 0.35) (vec3 0.14 0.14 0.5)
    , part prismMesh 0.3 white (vec3 0.34 -0.18 0.35) (vec3 0.14 0.14 0.5)

    -- box bottom
    , part cubeMesh 0.5 cardboard (vec3 0 -0.16 0) (vec3 0.56 0.05 0.42)

    -- box walls
    , part cubeMesh 0.62 cardboard (vec3 -0.27 -0.02 0) (vec3 0.04 0.26 0.42)
    , part cubeMesh 0.62 cardboard (vec3 0.27 -0.02 0) (vec3 0.04 0.26 0.42)
    , part cubeMesh 0.58 cardboard (vec3 0 -0.02 -0.2) (vec3 0.56 0.26 0.04)
    , part cubeMesh 0.66 cardboard (vec3 0 -0.02 0.2) (vec3 0.56 0.26 0.04)
    ]
        ++ peeker -0.13 0
        ++ peeker 0.13 2.1


viewClearedScreen : GameState -> Html msg
viewClearedScreen state =
    div
        [ Attr.class "absolute absolute--fill flex flex-column items-center justify-center tracked"
        , Attr.style "background" "rgba(0,0,0,0.7)"
        ]
        [ div
            [ Attr.class "f1 fw6"
            , Attr.style "color" "#7fdc7f"
            , Attr.style "text-shadow" "0 0 18px rgba(80,255,80,0.5)"
            ]
            [ text "TABLE CLEARED" ]
        , div
            [ Attr.class "f4 mt3"
            , Attr.style "color" "rgba(220,220,220,0.9)"
            ]
            [ text ("TIME " ++ formatTime state.elapsed ++ "  ·  ACCURACY " ++ String.fromInt (accuracy state) ++ "%") ]
        , div
            [ Attr.class "f6 mt4 blink"
            , Attr.style "color" "rgba(180,180,180,0.8)"
            ]
            [ text "CLICK TO RESTART" ]
        ]


accuracy : GameState -> Int
accuracy state =
    if state.swings <= 0 then
        100

    else
        round (100 * toFloat state.whacked / toFloat state.swings)


formatTime : Float -> String
formatTime ms =
    String.fromFloat (toFloat (round (ms / 100)) / 10) ++ "s"


viewPrompt : String -> Html msg
viewPrompt label =
    div
        [ Attr.class "absolute f5 tracked pa2 ph3"
        , Attr.style "left" "50%"
        , Attr.style "top" "58%"
        , Attr.style "transform" "translate(-50%, -50%)"
        , Attr.style "color" "rgba(228,228,228,0.9)"
        , Attr.style "border" "1px solid rgba(228,228,228,0.4)"
        , Attr.style "background" "rgba(0,0,0,0.55)"
        , Attr.style "text-shadow" "0 0 8px rgba(192,192,192,0.5)"
        , Attr.style "pointer-events" "none"
        ]
        [ text label ]


viewCrosshair : Html msg
viewCrosshair =
    div
        [ Attr.class "absolute"
        , Attr.style "left" "50%"
        , Attr.style "top" "50%"
        , Attr.style "width" "14px"
        , Attr.style "height" "14px"
        , Attr.style "transform" "translate(-50%, -50%)"
        , Attr.style "border" "1px solid rgba(228,228,228,0.85)"
        , Attr.style "border-radius" "50%"
        , Attr.style "box-shadow" "0 0 6px rgba(200,200,200,0.5)"
        , Attr.style "pointer-events" "none"
        ]
        []


viewHud : GameState -> Html msg
viewHud state =
    let
        alive =
            List.length (List.filter (\r -> r.squash <= 0) state.rats)

        objective =
            case state.phase of
                Carry ->
                    "BRING THE BOX TO THE TABLE"

                Dump _ ->
                    "RATS!"

                _ ->
                    "RATS " ++ String.fromInt alive ++ "/" ++ String.fromInt ratCount

        hint =
            if not state.locked then
                "CLICK TO CAPTURE MOUSE · ESC BACK"

            else
                case state.phase of
                    Carry ->
                        "WASD MOVE · SPACE JUMP · ESC RELEASE MOUSE"

                    Dump _ ->
                        ""

                    _ ->
                        "MOVE MOUSE TO AIM · CLICK TO WHACK"
    in
    div [ Attr.style "pointer-events" "none" ]
        [ div
            [ Attr.class "absolute top-0 left-0 pa2 f6 tracked"
            , Attr.style "color" "rgba(192,192,192,0.9)"
            , Attr.style "text-shadow" "0 0 8px rgba(192,192,192,0.35)"
            ]
            [ text objective ]
        , case state.phase of
            Whack ->
                div
                    [ Attr.class "absolute top-0 right-0 pa2 f6 tracked"
                    , Attr.style "color" "rgba(192,192,192,0.9)"
                    , Attr.style "text-shadow" "0 0 8px rgba(192,192,192,0.35)"
                    ]
                    [ text ("TIME " ++ formatTime state.elapsed) ]

            _ ->
                text ""
        , div
            [ Attr.class "absolute bottom-0 left-0 pa2 f7 tracked"
            , Attr.style "color" "rgba(170,170,170,0.7)"
            ]
            [ text hint ]
        , div
            [ Attr.class "absolute bottom-0 right-0 pa2 f7 tracked"
            , Attr.style "color" "rgba(170,170,170,0.7)"
            ]
            [ text (String.fromInt (round state.fps) ++ " FPS") ]
        ]



-- 3D MESHES & SHADERS


type alias Vertex =
    { position : Vec3, normal : Vec3 }


type alias Uniforms =
    { mvp : Mat4, model : Mat4, shade : Float, grid : Float, tint : Vec3 }


type alias Varyings =
    { vNormal : Vec3, vWorld : Vec3, vDepth : Float }


white : Vec3
white =
    vec3 1 1 1


entity : Mat4 -> Mat4 -> Float -> Float -> Vec3 -> WebGL.Mesh Vertex -> WebGL.Entity
entity mvp model shade grid tint mesh =
    WebGL.entityWith [ DepthTest.default ]
        vertexShader
        fragmentShader
        mesh
        { mvp = mvp, model = model, shade = shade, grid = grid, tint = tint }


floorMesh : WebGL.Mesh Vertex
floorMesh =
    let
        w =
            roomHalfW

        d =
            roomHalfD

        up =
            vec3 0 1 0
    in
    WebGL.triangles
        [ ( Vertex (vec3 -w 0 -d) up, Vertex (vec3 w 0 -d) up, Vertex (vec3 w 0 d) up )
        , ( Vertex (vec3 -w 0 -d) up, Vertex (vec3 w 0 d) up, Vertex (vec3 -w 0 d) up )
        ]


cubeMesh : WebGL.Mesh Vertex
cubeMesh =
    let
        face n a b c d =
            [ ( Vertex a n, Vertex b n, Vertex c n )
            , ( Vertex a n, Vertex c n, Vertex d n )
            ]

        -- unit cube, corners at +/-0.5
        p =
            0.5
    in
    WebGL.triangles
        (List.concat
            [ face (vec3 0 0 1) (vec3 -p -p p) (vec3 p -p p) (vec3 p p p) (vec3 -p p p)
            , face (vec3 0 0 -1) (vec3 p -p -p) (vec3 -p -p -p) (vec3 -p p -p) (vec3 p p -p)
            , face (vec3 1 0 0) (vec3 p -p p) (vec3 p -p -p) (vec3 p p -p) (vec3 p p p)
            , face (vec3 -1 0 0) (vec3 -p -p -p) (vec3 -p -p p) (vec3 -p p p) (vec3 -p p -p)
            , face (vec3 0 1 0) (vec3 -p p p) (vec3 p p p) (vec3 p p -p) (vec3 -p p -p)
            , face (vec3 0 -1 0) (vec3 -p -p -p) (vec3 p -p -p) (vec3 p -p p) (vec3 -p -p p)
            ]
        )


{-| Flat disc in the XZ plane facing up, diameter 1 like cubeMesh. -}
discMesh : WebGL.Mesh Vertex
discMesh =
    let
        n =
            24

        up =
            vec3 0 1 0

        point k =
            let
                a =
                    turns (toFloat k / toFloat n)
            in
            vec3 (0.5 * cos a) 0 (0.5 * sin a)
    in
    WebGL.triangles
        (List.map
            (\k -> ( Vertex (vec3 0 0 0) up, Vertex (point k) up, Vertex (point (k + 1)) up ))
            (List.range 0 (n - 1))
        )


{-| Octagonal prism along the Z axis, radius and length 1 like cubeMesh,
so makeScale gives full extents.
-}
prismMesh : WebGL.Mesh Vertex
prismMesh =
    let
        n =
            8

        point k =
            let
                a =
                    turns (toFloat k / toFloat n)
            in
            ( 0.5 * cos a, 0.5 * sin a )

        side k =
            let
                ( xa, ya ) =
                    point k

                ( xb, yb ) =
                    point (k + 1)

                normal =
                    Vec3.normalize (vec3 (xa + xb) (ya + yb) 0)
            in
            [ ( Vertex (vec3 xa ya -0.5) normal, Vertex (vec3 xb yb -0.5) normal, Vertex (vec3 xb yb 0.5) normal )
            , ( Vertex (vec3 xa ya -0.5) normal, Vertex (vec3 xb yb 0.5) normal, Vertex (vec3 xa ya 0.5) normal )
            ]

        cap z nz =
            List.concatMap
                (\k ->
                    let
                        ( xa, ya ) =
                            point k

                        ( xb, yb ) =
                            point (k + 1)
                    in
                    [ ( Vertex (vec3 0 0 z) (vec3 0 0 nz)
                      , Vertex (vec3 xa ya z) (vec3 0 0 nz)
                      , Vertex (vec3 xb yb z) (vec3 0 0 nz)
                      )
                    ]
                )
                (List.range 0 (n - 1))
    in
    WebGL.triangles
        (List.concatMap side (List.range 0 (n - 1))
            ++ cap -0.5 -1
            ++ cap 0.5 1
        )


vertexShader : WebGL.Shader Vertex Uniforms Varyings
vertexShader =
    [glsl|
        precision mediump float;
        attribute vec3 position;
        attribute vec3 normal;
        uniform mat4 mvp;
        uniform mat4 model;
        varying vec3 vNormal;
        varying vec3 vWorld;
        varying float vDepth;

        void main () {
            gl_Position = mvp * vec4(position, 1.0);
            vWorld = (model * vec4(position, 1.0)).xyz;
            vNormal = (model * vec4(normal, 0.0)).xyz;
            vDepth = gl_Position.w;
        }
    |]


fragmentShader : WebGL.Shader {} Uniforms Varyings
fragmentShader =
    [glsl|
        precision mediump float;
        uniform float shade;
        uniform float grid;
        uniform vec3 tint;
        varying vec3 vNormal;
        varying vec3 vWorld;
        varying float vDepth;

        void main () {
            vec3 L = normalize(vec3(0.4, 0.9, 0.35));
            float d = max(dot(normalize(vNormal), L), 0.0);
            float c = shade * (0.35 + 0.65 * d);
            if (grid > 0.5) {
                vec2 g = abs(fract(vWorld.xz) - 0.5);
                float line = 1.0 - smoothstep(0.0, 0.04, min(g.x, g.y));
                c = mix(c, 0.55, line * 0.5);
            }
            // Gentle indoor haze into the clear color.
            float fog = 1.0 - exp(-(vDepth * vDepth) / 140.0);
            vec3 col = mix(vec3(c) * tint, vec3(0.04, 0.04, 0.05), fog);
            gl_FragColor = vec4(col, 1.0);
        }
    |]



-- SUBSCRIPTIONS


subscriptions : GameState -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Browser.Events.onAnimationFrame Tick
        , Browser.Events.onKeyDown (Decode.map (Key True) keyName)
        , Browser.Events.onKeyUp (Decode.map (Key False) keyName)
        , Ports.pointerLockChanged LockChanged
        ]


{-| Physical key code when available, falling back to the layout-dependent key.
-}
keyName : Decode.Decoder String
keyName =
    Decode.oneOf
        [ Decode.field "code" Decode.string
        , Decode.field "key" Decode.string
        ]
