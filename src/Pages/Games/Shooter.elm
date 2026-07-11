module Pages.Games.Shooter exposing (GameState, Msg, init, subscriptions, update, view)

import Array exposing (Array)
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
    , targets : List Vec3
    , obstacles : List Box
    , score : Int
    , time : Time.Posix
    , seed : Random.Seed
    , locked : Bool
    , lookDx : Float
    , lookDy : Float
    , fps : Float
    , velY : Float
    }


type alias Keys =
    { f : Bool, b : Bool, l : Bool, r : Bool, jump : Bool }


type alias Box =
    { center : Vec3, half : Vec3 }


type Msg
    = Tick Time.Posix
    | Look Float Float
    | Fire
    | Key Bool String
    | RequestLock
    | LockChanged Bool



-- CONSTANTS


{-| World size of one map tile. -}
cellSize : Float
cellSize =
    2


wallHeight : Float
wallHeight =
    4.5


{-| Height gained by one platform level (and by one ramp tile). -}
platformUnit : Float
platformUnit =
    1.1


{-| Largest rise the player can walk up without jumping. -}
stepUp : Float
stepUp =
    0.45


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


{-| Time constant (ms) for draining accumulated mouse deltas.
-}
lookSmoothing : Float
lookSmoothing =
    40


{-| Downward acceleration in units/ms². -}
gravity : Float
gravity =
    0.000025


{-| Initial upward velocity of a jump in units/ms (~1.1 units high). -}
jumpSpeed : Float
jumpSpeed =
    0.0075


targetRadius : Float
targetRadius =
    0.75


-- LEVEL
--
-- The map is a tile grid, one character per cell:
--   '#' wall (floor to roof)      '.' open floor
--   'T' target spawn              'P' player start
--   '1' '2' raised platform (n * platformUnit high, walkable on top)
--   '>' '<' '^' 'v' ramp rising one level toward the arrow, starting
--   from the height of the tile behind it (which must be flat)


levelMap : List String
levelMap =
    [ "#################################"
    , "#.......#...........#...........#"
    , "#..T....#...........#.....T.....#"
    , "#.......#...........#...........#"
    , "####.#########.###########.######"
    , "#...T...........................#"
    , "#...............................#"
    , "######.#########.###########.####"
    , "#.......#...............#.......#"
    , "#..T....#...............#..T....#"
    , "#.......#....1111111....#.......#"
    , "#.......#....111v111....#.......#"
    , "#.......#...>1122211<...#.......#"
    , "#.......#....1111111....#.......#"
    , "#.......#....1111111....#.......#"
    , "#..T....#...............#..T....#"
    , "#.......#...............#.......#"
    , "######.#########.###########.####"
    , "#...............................#"
    , "#..........................P....#"
    , "####.#########.###########.######"
    , "#.......#...........#...........#"
    , "#..T....#.....T.....#........T..#"
    , "#.......#...........#...........#"
    , "#################################"
    ]


type alias Level =
    { walls : List Box
    , platforms : List Box
    , ramps : List Ramp
    , rampBoxes : List Box
    , openCells : List ( Float, Float, Float )
    , targetSpawns : List Vec3
    , playerSpawn : Vec3
    , tiles : Array (Array Char)
    , halfW : Float
    , halfD : Float
    }


type alias Ramp =
    { i : Int, j : Int, dir : Char, base : Float }


levelData : Level
levelData =
    parseLevel levelMap


parseLevel : List String -> Level
parseLevel rows =
    let
        tiles =
            Array.fromList (List.map (String.toList >> Array.fromList) rows)

        width =
            List.foldl (\r m -> Basics.max (String.length r) m) 0 rows

        halfW =
            toFloat width * cellSize / 2

        halfD =
            toFloat (List.length rows) * cellSize / 2

        cellX i =
            (toFloat i + 0.5) * cellSize - halfW

        cellZ j =
            (toFloat j + 0.5) * cellSize - halfD

        tile i j =
            Array.get j tiles
                |> Maybe.andThen (Array.get i)
                |> Maybe.withDefault '#'

        -- One box per horizontal run of '#' keeps the wall count low.
        runBox j ( s, e ) =
            let
                x1 =
                    toFloat s * cellSize - halfW

                x2 =
                    toFloat (e + 1) * cellSize - halfW
            in
            Box (vec3 ((x1 + x2) / 2) (wallHeight / 2) (cellZ j))
                (vec3 ((x2 - x1) / 2) (wallHeight / 2) (cellSize / 2))

        cellBox i j h =
            Box (vec3 (cellX i) (h / 2) (cellZ j))
                (vec3 (cellSize / 2) (h / 2) (cellSize / 2))

        addOpen i j h acc =
            { acc | openCells = ( cellX i, cellZ j, h ) :: acc.openCells }

        addPlatform i j h acc =
            addOpen i j h { acc | platforms = cellBox i j h :: acc.platforms }

        addRamp i j dir acc =
            let
                ( di, dj ) =
                    rampTailDir dir

                base =
                    flatHeight (tile (i + di) (j + dj))
                        |> Maybe.withDefault 0
            in
            { acc
                | ramps = Ramp i j dir base :: acc.ramps
                , rampBoxes = cellBox i j (base + platformUnit) :: acc.rampBoxes
            }

        collectCell j ( i, ch ) acc =
            case ch of
                '.' ->
                    addOpen i j 0 acc

                'T' ->
                    addOpen i j 0 { acc | targetSpawns = vec3 (cellX i) 1.2 (cellZ j) :: acc.targetSpawns }

                'P' ->
                    addOpen i j 0 { acc | playerSpawn = vec3 (cellX i) 0 (cellZ j) }

                '1' ->
                    addPlatform i j platformUnit acc

                '2' ->
                    addPlatform i j (2 * platformUnit) acc

                '>' ->
                    addRamp i j ch acc

                '<' ->
                    addRamp i j ch acc

                '^' ->
                    addRamp i j ch acc

                'v' ->
                    addRamp i j ch acc

                _ ->
                    acc

        collectRow j row acc =
            let
                withCells =
                    List.foldl (collectCell j)
                        acc
                        (List.indexedMap Tuple.pair (String.toList row))
            in
            { withCells | walls = List.map (runBox j) (wallRuns row) ++ withCells.walls }
    in
    List.foldl (\row ( j, acc ) -> ( j + 1, collectRow j row acc ))
        ( 0
        , { walls = []
          , platforms = []
          , ramps = []
          , rampBoxes = []
          , openCells = []
          , targetSpawns = []
          , playerSpawn = vec3 0 0 0
          , tiles = tiles
          , halfW = halfW
          , halfD = halfD
          }
        )
        rows
        |> Tuple.second


{-| Grid offset toward the tile a ramp rises from (opposite the arrow). -}
rampTailDir : Char -> ( Int, Int )
rampTailDir dir =
    case dir of
        '>' ->
            ( -1, 0 )

        '<' ->
            ( 1, 0 )

        'v' ->
            ( 0, -1 )

        _ ->
            ( 0, 1 )


{-| Floor height of a flat walkable tile; Nothing for walls and ramps. -}
flatHeight : Char -> Maybe Float
flatHeight ch =
    case ch of
        '.' ->
            Just 0

        'T' ->
            Just 0

        'P' ->
            Just 0

        '1' ->
            Just platformUnit

        '2' ->
            Just (2 * platformUnit)

        _ ->
            Nothing


{-| Start/end column indices of each consecutive run of '#'. -}
wallRuns : String -> List ( Int, Int )
wallRuns row =
    let
        stepChar ( i, ch ) ( current, done ) =
            if ch == '#' then
                case current of
                    Nothing ->
                        ( Just ( i, i ), done )

                    Just ( s, _ ) ->
                        ( Just ( s, i ), done )

            else
                case current of
                    Nothing ->
                        ( Nothing, done )

                    Just run ->
                        ( Nothing, run :: done )

        ( leftover, runs ) =
            List.foldl stepChar
                ( Nothing, [] )
                (List.indexedMap Tuple.pair (String.toList row))
    in
    case leftover of
        Nothing ->
            runs

        Just run ->
            run :: runs



-- INIT


init : ( GameState, Cmd Msg )
init =
    ( { camPos = Vec3.add levelData.playerSpawn (vec3 0 eyeHeight 0)
      , yaw = pi -- look toward -Z ("up" the map)
      , pitch = 0
      , keys = Keys False False False False False
      , targets = levelData.targetSpawns
      , obstacles = levelData.walls ++ levelData.platforms ++ levelData.rampBoxes
      , score = 0
      , time = Time.millisToPosix 0
      , seed = Random.initialSeed 11
      , locked = False
      , lookDx = 0
      , lookDy = 0
      , fps = 60
      , velY = 0
      }
    , Cmd.none
    )


{-| Respawn a target on a random open floor cell. -}
spawnOne : Random.Seed -> ( Vec3, Random.Seed )
spawnOne seed =
    let
        cells =
            levelData.openCells

        ( idx, s1 ) =
            Random.step (Random.int 0 (List.length cells - 1)) seed

        ( x, z, h ) =
            List.drop idx cells
                |> List.head
                |> Maybe.withDefault ( 0, 0, 0 )
    in
    ( vec3 x (h + 1.2) z, s1 )



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
            -- Deltas are accumulated here and drained smoothly in `step`,
            -- so coarse-grained movement events don't read as jumps.
            if state.locked then
                ( { state | lookDx = state.lookDx + dx, lookDy = state.lookDy + dy }
                , Cmd.none
                )

            else
                ( state, Cmd.none )

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
            if state.locked then
                ( shoot state, Cmd.none )

            else
                ( state, Cmd.none )

        RequestLock ->
            ( state, Ports.requestPointerLock viewId )

        LockChanged locked ->
            ( { state | locked = locked, lookDx = 0, lookDy = 0 }, Cmd.none )


{-| Advance camera and movement for one frame.
-}
step : Float -> GameState -> GameState
step dt state =
    let
        -- Drain a dt-proportional share of the pending mouse deltas so
        -- quantized movement events become continuous rotation.
        drain =
            1 - Basics.e ^ (-dt / lookSmoothing)

        useDx =
            state.lookDx * drain

        useDy =
            state.lookDy * drain

        -- Positive yaw turns left (forward = (sin yaw, cos yaw)),
        -- so mouse-right must decrease yaw.
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

        feet0 =
            Vec3.getY state.camPos - eyeHeight

        -- A move is allowed when the floor there doesn't rise more than a
        -- step above the feet (walls report height 99, so they block).
        canStand x z =
            cornerSupport x z <= feet0 + stepUp

        -- Resolve each axis independently so you slide along walls.
        newX =
            if canStand wantX z0 then
                wantX

            else
                x0

        newZ =
            if canStand newX wantZ then
                wantZ

            else
                z0

        -- Vertical: jump, integrate gravity, follow ramps, land on floors.
        support =
            cornerSupport newX newZ

        velY =
            if feet0 <= support + 0.02 && state.keys.jump then
                jumpSpeed

            else
                state.velY - gravity * dt

        wantY =
            feet0 + velY * dt

        ( newFeet, newVelY ) =
            if velY <= 0 && (wantY <= support || feet0 - support <= stepUp) then
                -- Landed, or near enough a surface to stay glued walking down it.
                ( support, 0 )

            else if wantY > wallHeight - 1.85 then
                -- Bumped the roof.
                ( wallHeight - 1.85, 0 )

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


shoot : GameState -> GameState
shoot state =
    let
        origin =
            state.camPos

        dir =
            lookDir state.yaw state.pitch

        -- Nearest obstacle distance along the ray (shots are blocked by walls).
        wallT =
            state.obstacles
                |> List.filterMap (rayBox origin dir)
                |> List.minimum

        hit =
            state.targets
                |> List.filterMap (\c -> Maybe.map (\t -> ( t, c )) (raySphere origin dir c targetRadius))
                |> List.filter (\( t, _ ) -> Maybe.withDefault True (Maybe.map (\w -> t < w) wallT))
                |> List.sortBy Tuple.first
                |> List.head
    in
    case hit of
        Nothing ->
            state

        Just ( _, c ) ->
            let
                ( fresh, seed ) =
                    spawnOne state.seed
            in
            { state
                | targets = fresh :: List.filter (\o -> o /= c) state.targets
                , score = state.score + 100
                , seed = seed
            }



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


tileAt : Int -> Int -> Char
tileAt i j =
    Array.get j levelData.tiles
        |> Maybe.andThen (Array.get i)
        |> Maybe.withDefault '#'


{-| Floor height under a world point. Ramps interpolate from the height
of their tail tile; walls and void report 99 so they block everything.
-}
supportAt : Float -> Float -> Float
supportAt x z =
    let
        i =
            floor ((x + levelData.halfW) / cellSize)

        j =
            floor ((z + levelData.halfD) / cellSize)

        fracX =
            (x + levelData.halfW) / cellSize - toFloat i

        fracZ =
            (z + levelData.halfD) / cellSize - toFloat j

        rampH di dj frac =
            (flatHeight (tileAt (i + di) (j + dj)) |> Maybe.withDefault 0)
                + platformUnit
                * frac
    in
    case tileAt i j of
        '>' ->
            rampH (-1) 0 fracX

        '<' ->
            rampH 1 0 (1 - fracX)

        'v' ->
            rampH 0 (-1) fracZ

        '^' ->
            rampH 0 1 (1 - fracZ)

        ch ->
            flatHeight ch |> Maybe.withDefault 99


{-| Highest floor under the player's four corners at a position. -}
cornerSupport : Float -> Float -> Float
cornerSupport x z =
    List.foldl Basics.max
        0
        [ supportAt (x - playerRadius) (z - playerRadius)
        , supportAt (x + playerRadius) (z - playerRadius)
        , supportAt (x - playerRadius) (z + playerRadius)
        , supportAt (x + playerRadius) (z + playerRadius)
        ]


raySphere : Vec3 -> Vec3 -> Vec3 -> Float -> Maybe Float
raySphere origin dir center radius =
    let
        oc =
            Vec3.sub origin center

        b =
            Vec3.dot oc dir

        c =
            Vec3.dot oc oc - radius * radius

        disc =
            b * b - c
    in
    if disc < 0 then
        Nothing

    else
        let
            t =
                -b - sqrt disc
        in
        if t > 0 then
            Just t

        else
            Nothing


rayBox : Vec3 -> Vec3 -> Box -> Maybe Float
rayBox origin dir box =
    let
        lo =
            Vec3.sub box.center box.half

        hi =
            Vec3.add box.center box.half

        ( txa, txb ) =
            slab (Vec3.getX origin) (Vec3.getX dir) (Vec3.getX lo) (Vec3.getX hi)

        ( tya, tyb ) =
            slab (Vec3.getY origin) (Vec3.getY dir) (Vec3.getY lo) (Vec3.getY hi)

        ( tza, tzb ) =
            slab (Vec3.getZ origin) (Vec3.getZ dir) (Vec3.getZ lo) (Vec3.getZ hi)

        tmin =
            Basics.max (Basics.max (min txa txb) (min tya tyb)) (min tza tzb)

        tmax =
            Basics.min (Basics.min (max txa txb) (max tya tyb)) (max tza tzb)
    in
    if tmax >= Basics.max 0 tmin then
        Just (Basics.max 0 tmin)

    else
        Nothing


slab : Float -> Float -> Float -> Float -> ( Float, Float )
slab o d lo hi =
    if abs d < 1.0e-6 then
        if o < lo || o > hi then
            ( 1.0e9, -1.0e9 )

        else
            ( -1.0e9, 1.0e9 )

    else
        ( (lo - o) / d, (hi - o) / d )



-- VIEW


view : GameState -> Html Msg
view state =
    let
        proj =
            Mat4.makePerspective 70 (960 / 600) 0.1 100

        viewM =
            Mat4.makeLookAt state.camPos (Vec3.add state.camPos (lookDir state.yaw state.pitch)) (vec3 0 1 0)

        mvp model =
            Mat4.mul proj (Mat4.mul viewM model)

        floorEntity =
            entity (mvp Mat4.identity) Mat4.identity 0.22 1 floorMesh

        ceilingEntity =
            entity (mvp Mat4.identity) Mat4.identity 0.12 0 ceilingMesh

        boxEntity shade grid o =
            let
                model =
                    Mat4.mul (Mat4.makeTranslate o.center) (Mat4.makeScale (Vec3.scale 2 o.half))
            in
            entity (mvp model) model shade grid cubeMesh

        wallEntities =
            List.map (boxEntity 0.5 0) levelData.walls

        platformEntities =
            List.map (boxEntity 0.38 1) levelData.platforms

        rampEntity =
            entity (mvp Mat4.identity) Mat4.identity 0.45 1 rampMesh

        targetEntities =
            List.map
                (\c ->
                    let
                        model =
                            Mat4.mul (Mat4.makeTranslate c) (Mat4.makeScale (vec3 1.2 1.2 1.2))
                    in
                    entity (mvp model) model 0.85 0 cubeMesh
                )
                state.targets
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
            [ Attr.width 960
            , Attr.height 600
            , Attr.style "width" "100%"
            , Attr.style "height" "100%"
            , Attr.style "display" "block"
            ]
            (floorEntity :: ceilingEntity :: rampEntity :: wallEntities ++ platformEntities ++ targetEntities)
        , viewCrosshair
        , viewHud state
        , if state.locked then
            text ""

          else
            viewLockPrompt
        ]


viewId : String
viewId =
    "shooter-view"


lookDecoder : Decode.Decoder Msg
lookDecoder =
    Decode.map2 Look
        (Decode.field "movementX" Decode.float)
        (Decode.field "movementY" Decode.float)


viewLockPrompt : Html msg
viewLockPrompt =
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
        [ text "CLICK TO CAPTURE MOUSE" ]


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
    div [ Attr.style "pointer-events" "none" ]
        [ div
            [ Attr.class "absolute top-0 left-0 pa2 f6 tracked"
            , Attr.style "color" "rgba(192,192,192,0.9)"
            , Attr.style "text-shadow" "0 0 8px rgba(192,192,192,0.35)"
            ]
            [ text ("SCORE " ++ String.fromInt state.score) ]
        , div
            [ Attr.class "absolute bottom-0 left-0 pa2 f7 tracked"
            , Attr.style "color" "rgba(170,170,170,0.7)"
            ]
            [ text
                (if state.locked then
                    "WASD MOVE · SPACE JUMP · CLICK SHOOT · ESC RELEASE MOUSE"

                 else
                    "WASD MOVE · SPACE JUMP · CLICK TO CAPTURE MOUSE · ESC BACK"
                )
            ]
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
    { mvp : Mat4, model : Mat4, shade : Float, grid : Float }


type alias Varyings =
    { vNormal : Vec3, vWorld : Vec3 }


entity : Mat4 -> Mat4 -> Float -> Float -> WebGL.Mesh Vertex -> WebGL.Entity
entity mvp model shade grid mesh =
    WebGL.entityWith [ DepthTest.default ]
        vertexShader
        fragmentShader
        mesh
        { mvp = mvp, model = model, shade = shade, grid = grid }


floorMesh : WebGL.Mesh Vertex
floorMesh =
    let
        w =
            levelData.halfW

        d =
            levelData.halfD

        up =
            vec3 0 1 0
    in
    WebGL.triangles
        [ ( Vertex (vec3 -w 0 -d) up, Vertex (vec3 w 0 -d) up, Vertex (vec3 w 0 d) up )
        , ( Vertex (vec3 -w 0 -d) up, Vertex (vec3 w 0 d) up, Vertex (vec3 -w 0 d) up )
        ]


rampMesh : WebGL.Mesh Vertex
rampMesh =
    WebGL.triangles (List.concatMap rampTriangles levelData.ramps)


{-| A solid wedge filling the ramp's cell: sloped top, side skirts down
to the ground, and a full back face under the high edge.
-}
rampTriangles : Ramp -> List ( Vertex, Vertex, Vertex )
rampTriangles r =
    let
        x1 =
            toFloat r.i * cellSize - levelData.halfW

        z1 =
            toFloat r.j * cellSize - levelData.halfD

        s =
            cellSize

        b =
            r.base

        t =
            b + platformUnit

        -- Local frame: u ascends the slope, w runs across it.
        pos u y w =
            case r.dir of
                '>' ->
                    vec3 (x1 + u) y (z1 + w)

                '<' ->
                    vec3 (x1 + s - u) y (z1 + w)

                'v' ->
                    vec3 (x1 + w) y (z1 + u)

                _ ->
                    -- '^'
                    vec3 (x1 + w) y (z1 + s - u)

        tri a b_ c =
            let
                n0 =
                    Vec3.cross (Vec3.sub b_ a) (Vec3.sub c a)
            in
            if Vec3.length n0 < 1.0e-6 then
                Nothing

            else
                let
                    n1 =
                        Vec3.normalize n0

                    n =
                        if Vec3.getY n1 < 0 then
                            Vec3.scale -1 n1

                        else
                            n1
                in
                Just ( Vertex a n, Vertex b_ n, Vertex c n )

        quad a b_ c d =
            List.filterMap identity [ tri a b_ c, tri a c d ]
    in
    List.concat
        [ quad (pos 0 b 0) (pos s t 0) (pos s t s) (pos 0 b s)
        , quad (pos 0 0 0) (pos s 0 0) (pos s t 0) (pos 0 b 0)
        , quad (pos 0 0 s) (pos s 0 s) (pos s t s) (pos 0 b s)
        , quad (pos s 0 0) (pos s 0 s) (pos s t s) (pos s t 0)
        ]


ceilingMesh : WebGL.Mesh Vertex
ceilingMesh =
    let
        w =
            levelData.halfW

        d =
            levelData.halfD

        h =
            wallHeight

        down =
            vec3 0 -1 0
    in
    WebGL.triangles
        [ ( Vertex (vec3 -w h -d) down, Vertex (vec3 w h d) down, Vertex (vec3 w h -d) down )
        , ( Vertex (vec3 -w h -d) down, Vertex (vec3 -w h d) down, Vertex (vec3 w h d) down )
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

        void main () {
            gl_Position = mvp * vec4(position, 1.0);
            vWorld = (model * vec4(position, 1.0)).xyz;
            vNormal = (model * vec4(normal, 0.0)).xyz;
        }
    |]


fragmentShader : WebGL.Shader {} Uniforms Varyings
fragmentShader =
    [glsl|
        precision mediump float;
        uniform float shade;
        uniform float grid;
        varying vec3 vNormal;
        varying vec3 vWorld;

        void main () {
            vec3 L = normalize(vec3(0.4, 0.9, 0.35));
            float d = max(dot(normalize(vNormal), L), 0.0);
            float c = shade * (0.35 + 0.65 * d);
            if (grid > 0.5) {
                vec2 g = abs(fract(vWorld.xz) - 0.5);
                float line = 1.0 - smoothstep(0.0, 0.04, min(g.x, g.y));
                c = mix(c, 0.55, line * 0.5);
            }
            gl_FragColor = vec4(vec3(c), 1.0);
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
