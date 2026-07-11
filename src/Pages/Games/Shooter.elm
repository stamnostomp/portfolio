module Pages.Games.Shooter exposing (GameState, Msg, init, subscriptions, update, view)

import Array exposing (Array)
import Browser.Events
import Dict exposing (Dict)
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
    , recoil : Float
    , ammo : Int
    , cooldown : Float
    , reloading : Float
    , flow : Dict ( Int, Int ) Int
    , flowFrom : ( Int, Int )
    , bullets : List Bullet
    , gibs : List Gib
    }


type alias Bullet =
    { pos : Vec3, dir : Vec3, ttl : Float }


{-| A burst fragment from a killed goblin. -}
type alias Gib =
    { pos : Vec3, vel : Vec3, t : Float }


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


magSize : Int
magSize =
    6


{-| Minimum ms between shots (lets the recoil animation play out). -}
shotCooldown : Float
shotCooldown =
    350


{-| Reload duration in ms. -}
reloadTime : Float
reloadTime =
    1100


{-| Goblin walk speed in units/ms (player moves at 0.006). -}
goblinSpeed : Float
goblinSpeed =
    0.0025


{-| Goblins stop chasing once this close to the player. -}
goblinStopDist : Float
goblinStopDist =
    1.4


{-| Bullet speed in units/ms. -}
bulletSpeed : Float
bulletSpeed =
    0.03


{-| Bullet lifetime in ms. -}
bulletTtl : Float
bulletTtl =
    1500


{-| How long goblin burst fragments live, in ms. -}
gibTtl : Float
gibTtl =
    600


{-| Radius of a goblin's hit sphere (centered on its body). -}
targetRadius : Float
targetRadius =
    0.55


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
                    addOpen i j 0 { acc | targetSpawns = vec3 (cellX i) 0 (cellZ j) :: acc.targetSpawns }

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
    let
        spawnTile =
            tileIndexAt (Vec3.getX levelData.playerSpawn) (Vec3.getZ levelData.playerSpawn)
    in
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
      , recoil = 0
      , ammo = magSize
      , cooldown = 0
      , reloading = 0
      , flow = computeFlow spawnTile
      , flowFrom = spawnTile
      , bullets = []
      , gibs = []
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
    ( vec3 x h z, s1 )



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

                reloadRequested =
                    isDown
                        && state.locked
                        && List.member (String.toLower raw) [ "r", "keyr" ]
                        && state.ammo < magSize
                        && state.reloading <= 0
            in
            if reloadRequested then
                ( { state | keys = keys, reloading = reloadTime }, Cmd.none )

            else
                ( { state | keys = keys }, Cmd.none )

        Fire ->
            if not state.locked then
                ( state, Cmd.none )

            else if state.cooldown > 0 || state.reloading > 0 then
                -- Still cycling or reloading; the trigger does nothing.
                ( state, Cmd.none )

            else if state.ammo <= 0 then
                ( { state | reloading = reloadTime }, Cmd.none )

            else
                let
                    look =
                        lookDir state.yaw state.pitch

                    right =
                        Vec3.normalize (Vec3.cross look (vec3 0 1 0))

                    -- Leave from the gun barrel, converging on the aim point.
                    origin =
                        state.camPos
                            |> Vec3.add (Vec3.scale 0.35 look)
                            |> Vec3.add (Vec3.scale 0.12 right)
                            |> Vec3.add (vec3 0 -0.12 0)

                    aim =
                        Vec3.add state.camPos (Vec3.scale 50 look)

                    dir =
                        Vec3.normalize (Vec3.sub aim origin)
                in
                ( { state
                    | recoil = 1
                    , ammo = state.ammo - 1
                    , cooldown = shotCooldown
                    , bullets = Bullet origin dir bulletTtl :: state.bullets
                  }
                , Cmd.none
                )

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

        ( newReloading, newAmmo ) =
            if state.reloading > 0 then
                let
                    remaining =
                        state.reloading - dt
                in
                if remaining <= 0 then
                    ( 0, magSize )

                else
                    ( remaining, state.ammo )

            else
                ( 0, state.ammo )

        -- Chase: refresh the flow field when the player changes tile,
        -- then let every goblin walk one step along it.
        playerTile =
            tileIndexAt newX newZ

        flow =
            if playerTile == state.flowFrom then
                state.flow

            else
                computeFlow playerTile

        goblins =
            List.map (moveGoblin dt (vec3 newX 0 newZ) flow) state.targets

        shots =
            stepBullets dt state.obstacles goblins state.seed state.bullets

        gibs =
            List.concatMap spawnGibs shots.killed
                ++ List.filterMap
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
                    state.gibs
    in
    { state
        | camPos = vec3 newX (newFeet + eyeHeight) newZ
        , yaw = yaw
        , pitch = pitch
        , lookDx = state.lookDx - useDx
        , lookDy = state.lookDy - useDy
        , velY = newVelY
        , recoil = state.recoil * Basics.e ^ (-dt / 90)
        , cooldown = Basics.max 0 (state.cooldown - dt)
        , ammo = newAmmo
        , reloading = newReloading
        , targets = shots.goblins
        , flow = flow
        , flowFrom = playerTile
        , bullets = shots.bullets
        , seed = shots.seed
        , score = state.score + 100 * List.length shots.killed
        , gibs = gibs
    }


{-| Advance every bullet one frame: die on level geometry or timeout,
kill the first goblin crossed (which respawns elsewhere).
-}
stepBullets :
    Float
    -> List Box
    -> List Vec3
    -> Random.Seed
    -> List Bullet
    -> { bullets : List Bullet, goblins : List Vec3, seed : Random.Seed, killed : List Vec3 }
stepBullets dt obstacles goblins0 seed0 bullets0 =
    List.foldl
        (\b acc ->
            let
                travel =
                    bulletSpeed * dt

                wallT =
                    obstacles
                        |> List.filterMap (rayBox b.pos b.dir)
                        |> List.minimum
                        |> Maybe.withDefault 1.0e9

                reach =
                    Basics.min travel wallT

                hit =
                    acc.goblins
                        |> List.filterMap
                            (\g ->
                                raySphere b.pos b.dir (Vec3.add g (vec3 0 0.55 0)) targetRadius
                                    |> Maybe.map (\t -> ( t, g ))
                            )
                        |> List.filter (\( t, _ ) -> t <= reach)
                        |> List.sortBy Tuple.first
                        |> List.head
            in
            case hit of
                Just ( _, g ) ->
                    let
                        ( fresh, s2 ) =
                            spawnOne acc.seed
                    in
                    { acc
                        | goblins = fresh :: List.filter (\o -> o /= g) acc.goblins
                        , seed = s2
                        , killed = g :: acc.killed
                    }

                Nothing ->
                    if wallT <= travel || b.ttl <= dt then
                        acc

                    else
                        { acc
                            | bullets =
                                { b
                                    | pos = Vec3.add b.pos (Vec3.scale travel b.dir)
                                    , ttl = b.ttl - dt
                                }
                                    :: acc.bullets
                        }
        )
        { bullets = [], goblins = goblins0, seed = seed0, killed = [] }
        bullets0


{-| Fragments flung outward and up from a killed goblin's center. -}
spawnGibs : Vec3 -> List Gib
spawnGibs p =
    let
        center =
            Vec3.add p (vec3 0 0.55 0)
    in
    List.map
        (\( dx, dy, dz ) ->
            { pos = center
            , vel = Vec3.scale 0.0045 (Vec3.normalize (vec3 dx dy dz))
            , t = gibTtl
            }
        )
        [ ( 1, 0.4, 0 )
        , ( -1, 0.4, 0 )
        , ( 0, 0.4, 1 )
        , ( 0, 0.4, -1 )
        , ( 0.7, 0.9, 0.7 )
        , ( -0.7, 0.9, 0.7 )
        , ( 0.7, 0.9, -0.7 )
        , ( -0.7, 0.9, -0.7 )
        , ( 0.35, 1.3, 0 )
        , ( -0.35, 1.3, 0 )
        , ( 0, 1.3, 0.35 )
        , ( 0, 1.3, -0.35 )
        ]



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



-- PATHFINDING


tileIndexAt : Float -> Float -> ( Int, Int )
tileIndexAt x z =
    ( floor ((x + levelData.halfW) / cellSize)
    , floor ((z + levelData.halfD) / cellSize)
    )


cellCenter : ( Int, Int ) -> ( Float, Float )
cellCenter ( i, j ) =
    ( (toFloat i + 0.5) * cellSize - levelData.halfW
    , (toFloat j + 0.5) * cellSize - levelData.halfD
    )


{-| Floor height at the edge of a tile faced when stepping toward
(di, dj); Nothing when that edge can't be crossed (walls, ramp sides).
-}
exitHeight : ( Int, Int ) -> ( Int, Int ) -> Maybe Float
exitHeight ( i, j ) ( di, dj ) =
    let
        ch =
            tileAt i j
    in
    case flatHeight ch of
        Just h ->
            Just h

        Nothing ->
            if List.member ch [ '>', '<', '^', 'v' ] then
                let
                    ( ti, tj ) =
                        rampTailDir ch

                    base =
                        flatHeight (tileAt (i + ti) (j + tj))
                            |> Maybe.withDefault 0
                in
                if ( di, dj ) == ( ti, tj ) then
                    Just base

                else if ( di, dj ) == ( -ti, -tj ) then
                    Just (base + platformUnit)

                else
                    Nothing

            else
                Nothing


{-| Whether something walking (not jumping) can cross between two
adjacent tiles, using the same step-height rule as the player.
-}
canWalk : ( Int, Int ) -> ( Int, Int ) -> Bool
canWalk (( i1, j1 ) as a) (( i2, j2 ) as b) =
    case ( exitHeight a ( i2 - i1, j2 - j1 ), exitHeight b ( i1 - i2, j1 - j2 ) ) of
        ( Just ha, Just hb ) ->
            abs (ha - hb) <= stepUp

        _ ->
            False


{-| Breadth-first walking distance (in tiles) from a start tile to every
reachable tile. Goblins descend this field to chase the player.
-}
computeFlow : ( Int, Int ) -> Dict ( Int, Int ) Int
computeFlow start =
    bfsFlow (Dict.singleton start 0) [ start ]


bfsFlow : Dict ( Int, Int ) Int -> List ( Int, Int ) -> Dict ( Int, Int ) Int
bfsFlow dist frontier =
    case frontier of
        [] ->
            dist

        (( i, j ) as cur) :: rest ->
            let
                d =
                    Dict.get cur dist |> Maybe.withDefault 0

                fresh =
                    [ ( i + 1, j ), ( i - 1, j ), ( i, j + 1 ), ( i, j - 1 ) ]
                        |> List.filter (\n -> not (Dict.member n dist) && canWalk cur n)

                dist2 =
                    List.foldl (\n acc -> Dict.insert n (d + 1) acc) dist fresh
            in
            bfsFlow dist2 (rest ++ fresh)


{-| Walk one goblin toward the player: head for the neighboring tile
with the lowest flow distance (or straight at the player when sharing a
tile), gluing to the floor so ramps carry it up and down.
-}
moveGoblin : Float -> Vec3 -> Dict ( Int, Int ) Int -> Vec3 -> Vec3
moveGoblin dt cam flow p =
    let
        gx =
            Vec3.getX p

        gz =
            Vec3.getZ p

        dxp =
            Vec3.getX cam - gx

        dzp =
            Vec3.getZ cam - gz

        gTile =
            tileIndexAt gx gz

        here =
            Dict.get gTile flow |> Maybe.withDefault 99999

        waypoint =
            if here == 0 then
                Just ( Vec3.getX cam, Vec3.getZ cam )

            else
                let
                    ( gi, gj ) =
                        gTile
                in
                [ ( gi + 1, gj ), ( gi - 1, gj ), ( gi, gj + 1 ), ( gi, gj - 1 ) ]
                    |> List.filter (canWalk gTile)
                    |> List.filterMap (\n -> Dict.get n flow |> Maybe.map (\d -> ( d, n )))
                    |> List.sortBy Tuple.first
                    |> List.head
                    |> Maybe.andThen
                        (\( d, n ) ->
                            if d < here then
                                Just (cellCenter n)

                            else
                                Nothing
                        )
    in
    if sqrt (dxp * dxp + dzp * dzp) <= goblinStopDist then
        p

    else
        case waypoint of
            Nothing ->
                p

            Just ( wx, wz ) ->
                let
                    dx =
                        wx - gx

                    dz =
                        wz - gz

                    len =
                        sqrt (dx * dx + dz * dz)

                    stepLen =
                        Basics.min len (goblinSpeed * dt)
                in
                if len < 1.0e-6 then
                    p

                else
                    let
                        nx =
                            gx + dx / len * stepLen

                        nz =
                            gz + dz / len * stepLen
                    in
                    vec3 nx (supportAt nx nz) nz


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
            Mat4.makePerspective 70 (1600 / 900) 0.1 100

        viewM =
            Mat4.makeLookAt state.camPos (Vec3.add state.camPos (lookDir state.yaw state.pitch)) (vec3 0 1 0)

        mvp model =
            Mat4.mul proj (Mat4.mul viewM model)

        floorEntity =
            entity (mvp Mat4.identity) Mat4.identity 0.22 1 white floorMesh

        ceilingEntity =
            entity (mvp Mat4.identity) Mat4.identity 0.12 0 white ceilingMesh

        boxEntity shade grid o =
            let
                model =
                    Mat4.mul (Mat4.makeTranslate o.center) (Mat4.makeScale (Vec3.scale 2 o.half))
            in
            entity (mvp model) model shade grid white cubeMesh

        wallEntities =
            List.map (boxEntity 0.5 0) levelData.walls

        platformEntities =
            List.map (boxEntity 0.38 1) levelData.platforms

        rampEntity =
            entity (mvp Mat4.identity) Mat4.identity 0.45 1 white rampMesh

        goblinEntities =
            List.concatMap (viewGoblin mvp state) state.targets

        bulletEntities =
            List.map
                (\b ->
                    let
                        model =
                            Mat4.mul (Mat4.makeTranslate b.pos) (Mat4.makeScale (vec3 0.09 0.09 0.09))
                    in
                    entity (mvp model) model 2.5 0 (vec3 1 0.85 0.4) cubeMesh
                )
                state.bullets

        gibEntities =
            List.map
                (\g ->
                    let
                        s =
                            0.02 + 0.15 * (g.t / gibTtl)

                        model =
                            Mat4.mul (Mat4.makeTranslate g.pos) (Mat4.makeScale (vec3 s s s))
                    in
                    entity (mvp model) model 0.9 0 (vec3 0.5 0.95 0.55) cubeMesh
                )
                state.gibs
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
            (floorEntity :: ceilingEntity :: rampEntity :: wallEntities ++ platformEntities ++ goblinEntities ++ bulletEntities ++ gibEntities ++ viewGun proj state)
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


{-| A little goblin standing at a spawn point: it bobs in place and
always turns to face the player. Built from tinted boxes.
-}
viewGoblin : (Mat4 -> Mat4) -> GameState -> Vec3 -> List WebGL.Entity
viewGoblin mvp state p =
    let
        ms =
            toFloat (Time.posixToMillis state.time)

        gx =
            Vec3.getX p

        gy =
            Vec3.getY p

        gz =
            Vec3.getZ p

        yawG =
            atan2 (Vec3.getX state.camPos - gx) (Vec3.getZ state.camPos - gz)

        bob =
            sin (ms * 0.004 + (gx + gz) * 3) * 0.04

        root =
            Mat4.mul (Mat4.makeTranslate (vec3 gx (gy + bob) gz))
                (Mat4.makeRotate yawG (vec3 0 1 0))

        part shade tint pos size =
            let
                model =
                    Mat4.mul root (Mat4.mul (Mat4.makeTranslate pos) (Mat4.makeScale size))
            in
            entity (mvp model) model shade 0 tint cubeMesh

        green =
            vec3 0.5 0.95 0.55

        black =
            vec3 0.05 0.05 0.05
    in
    [ -- legs
      part 0.5 green (vec3 -0.12 0.11 0) (vec3 0.12 0.22 0.14)
    , part 0.5 green (vec3 0.12 0.11 0) (vec3 0.12 0.22 0.14)

    -- body
    , part 0.6 green (vec3 0 0.42 0) (vec3 0.5 0.42 0.34)

    -- head
    , part 0.7 green (vec3 0 0.8 0.02) (vec3 0.42 0.34 0.36)

    -- pointy ears
    , part 0.6 green (vec3 -0.24 1.02 0) (vec3 0.1 0.28 0.06)
    , part 0.6 green (vec3 0.24 1.02 0) (vec3 0.1 0.28 0.06)

    -- nose
    , part 0.55 green (vec3 0 0.76 0.2) (vec3 0.09 0.09 0.14)

    -- arms hanging at the sides
    , part 0.55 green (vec3 -0.31 0.38 0) (vec3 0.1 0.36 0.12)
    , part 0.55 green (vec3 0.31 0.38 0) (vec3 0.1 0.36 0.12)

    -- little hands
    , part 0.7 green (vec3 -0.31 0.16 0) (vec3 0.12 0.1 0.14)
    , part 0.7 green (vec3 0.31 0.16 0) (vec3 0.12 0.1 0.14)

    -- beady black eyes, poking just out of the face
    , part 0.05 black (vec3 -0.1 0.86 0.21) (vec3 0.07 0.07 0.06)
    , part 0.05 black (vec3 0.1 0.86 0.21) (vec3 0.07 0.07 0.06)
    ]


{-| First-person arm and revolver, rendered in view space (no view
matrix) so it sticks to the camera. A squashed depth range draws it
over the scene while it still occludes itself correctly.
-}
viewGun : Mat4 -> GameState -> List WebGL.Entity
viewGun proj state =
    let
        ms =
            toFloat (Time.posixToMillis state.time)

        moving =
            state.keys.f || state.keys.b || state.keys.l || state.keys.r

        bob =
            if moving then
                sin (ms * 0.012) * 0.018

            else
                sin (ms * 0.003) * 0.006

        kick =
            state.recoil

        -- 0 -> 1 over the course of a reload, 0 when not reloading.
        reloadP =
            if state.reloading > 0 then
                1 - state.reloading / reloadTime

            else
                0

        -- Dip the gun down and back while reloading.
        dip =
            sin (pi * reloadP)

        -- Gun space: origin low-right of the view, barrel toward -Z.
        vm =
            Mat4.mul
                (Mat4.makeTranslate (vec3 0.32 (-0.34 + bob - dip * 0.1) (-1.05 + kick * 0.09 + dip * 0.06)))
                (Mat4.makeRotate (kick * 0.5 - dip * 0.35) (vec3 1 0 0))

        partRot mesh shade tint pos rot size =
            let
                model =
                    Mat4.mul vm
                        (Mat4.mul (Mat4.makeTranslate pos)
                            (Mat4.mul rot (Mat4.makeScale size))
                        )
            in
            WebGL.entityWith
                [ DepthTest.less { write = True, near = 0, far = 0.1 } ]
                vertexShader
                fragmentShader
                mesh
                { mvp = Mat4.mul proj model, model = model, shade = shade, grid = 0, tint = tint }

        part mesh shade pos size =
            partRot mesh shade white pos Mat4.identity size

        -- The cylinder advances a chamber per shot and spins on reload.
        cylAngle =
            toFloat (magSize - state.ammo) * (pi / 3) + reloadP * 4 * pi

        flash =
            if kick > 0.8 then
                [ partRot prismMesh 2.5 (vec3 1 0.85 0.4) (vec3 0 0.06 -0.92) Mat4.identity (vec3 0.2 0.2 0.12) ]

            else
                []
    in
    [ -- arm reaching in from the bottom right
      part prismMesh 0.3 (vec3 0.07 -0.13 0.34) (vec3 0.16 0.16 0.55)

    -- grip
    , part cubeMesh 0.62 (vec3 0 -0.13 0.12) (vec3 0.09 0.22 0.1)

    -- frame
    , part cubeMesh 0.75 (vec3 0 0.02 0) (vec3 0.08 0.16 0.42)

    -- oversized cylinder
    , partRot prismMesh 0.9 white (vec3 0 0.03 -0.06) (Mat4.makeRotate cylAngle (vec3 0 0 1)) (vec3 0.21 0.21 0.2)

    -- long octagonal barrel
    , part prismMesh 0.8 (vec3 0 0.06 -0.52) (vec3 0.1 0.1 0.75)

    -- muzzle ring
    , part prismMesh 0.9 (vec3 0 0.06 -0.87) (vec3 0.15 0.15 0.06)

    -- hammer
    , part cubeMesh 0.85 (vec3 0 0.14 0.18) (vec3 0.03 0.1 0.06)

    -- front sight
    , part cubeMesh 0.85 (vec3 0 0.14 -0.84) (vec3 0.02 0.06 0.04)
    ]
        ++ flash


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
                    "WASD MOVE · SPACE JUMP · CLICK SHOOT · R RELOAD · ESC RELEASE MOUSE"

                 else
                    "WASD MOVE · SPACE JUMP · CLICK TO CAPTURE MOUSE · ESC BACK"
                )
            ]
        , div
            [ Attr.class "absolute bottom-0 right-0 pa2 f7 tracked"
            , Attr.style "color" "rgba(170,170,170,0.7)"
            ]
            [ text (String.fromInt (round state.fps) ++ " FPS") ]
        , div
            [ Attr.class
                ("absolute bottom-0 pa2 f5 tracked"
                    ++ (if state.reloading > 0 then
                            " blink"

                        else
                            ""
                       )
                )
            , Attr.style "left" "50%"
            , Attr.style "transform" "translateX(-50%)"
            , Attr.style "color" "rgba(210,210,210,0.85)"
            , Attr.style "text-shadow" "0 0 8px rgba(192,192,192,0.4)"
            ]
            [ text
                (if state.reloading > 0 then
                    "RELOADING"

                 else
                    String.repeat state.ammo "●" ++ String.repeat (magSize - state.ammo) "○"
                )
            ]
        ]



-- 3D MESHES & SHADERS


type alias Vertex =
    { position : Vec3, normal : Vec3 }


type alias Uniforms =
    { mvp : Mat4, model : Mat4, shade : Float, grid : Float, tint : Vec3 }


type alias Varyings =
    { vNormal : Vec3, vWorld : Vec3 }


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
        uniform vec3 tint;
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
            gl_FragColor = vec4(vec3(c) * tint, 1.0);
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
