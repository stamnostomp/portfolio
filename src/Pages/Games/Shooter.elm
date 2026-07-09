module Pages.Games.Shooter exposing (GameState, Msg, init, subscriptions, update, view)

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
    }


type alias Keys =
    { f : Bool, b : Bool, l : Bool, r : Bool }


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


arenaHalf : Float
arenaHalf =
    12


playerRadius : Float
playerRadius =
    0.4


eyeHeight : Float
eyeHeight =
    1.6


moveSpeed : Float
moveSpeed =
    0.006


targetRadius : Float
targetRadius =
    0.75


obstacles0 : List Box
obstacles0 =
    [ Box (vec3 -3 1.5 0) (vec3 1 1.5 1)
    , Box (vec3 3 1.5 -2) (vec3 1 1.5 1)
    , Box (vec3 0 1 -5) (vec3 1.6 1 1.6)
    , Box (vec3 -5 1.5 -6) (vec3 1 1.5 1)
    , Box (vec3 5 2 -7) (vec3 1 2 1)
    ]



-- INIT


init : ( GameState, Cmd Msg )
init =
    let
        ( targets, seed ) =
            spawnMany 6 (Random.initialSeed 11)
    in
    ( { camPos = vec3 0 eyeHeight 9
      , yaw = pi -- look toward -Z (into the arena)
      , pitch = 0
      , keys = Keys False False False False
      , targets = targets
      , obstacles = obstacles0
      , score = 0
      , time = Time.millisToPosix 0
      , seed = seed
      , locked = False
      }
    , Cmd.none
    )


spawnMany : Int -> Random.Seed -> ( List Vec3, Random.Seed )
spawnMany n seed =
    if n <= 0 then
        ( [], seed )

    else
        let
            ( p, s1 ) =
                spawnOne seed

            ( rest, s2 ) =
                spawnMany (n - 1) s1
        in
        ( p :: rest, s2 )


spawnOne : Random.Seed -> ( Vec3, Random.Seed )
spawnOne seed =
    let
        ( x, s1 ) =
            Random.step (Random.float -8 8) seed

        ( z, s2 ) =
            Random.step (Random.float -9 -1) s1
    in
    ( vec3 x 1.2 z, s2 )



-- UPDATE


update : Msg -> GameState -> ( GameState, Cmd Msg )
update msg state =
    case msg of
        Tick newTime ->
            ( step (toFloat (Basics.clamp 0 32 (Time.posixToMillis newTime - Time.posixToMillis state.time))) { state | time = newTime }
            , Cmd.none
            )

        Look dx dy ->
            if state.locked then
                -- Positive yaw turns left (forward = (sin yaw, cos yaw)),
                -- so mouse-right must decrease yaw.
                ( { state
                    | yaw = state.yaw - dx * 0.0025
                    , pitch = Basics.clamp -1.4 1.4 (state.pitch - dy * 0.0025)
                  }
                , Cmd.none
                )

            else
                ( state, Cmd.none )

        Key isDown raw ->
            let
                k =
                    state.keys

                keys =
                    case String.toLower raw of
                        "w" ->
                            { k | f = isDown }

                        "arrowup" ->
                            { k | f = isDown }

                        "s" ->
                            { k | b = isDown }

                        "arrowdown" ->
                            { k | b = isDown }

                        "a" ->
                            { k | l = isDown }

                        "arrowleft" ->
                            { k | l = isDown }

                        "d" ->
                            { k | r = isDown }

                        "arrowright" ->
                            { k | r = isDown }

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
            ( { state | locked = locked }, Cmd.none )


{-| Advance movement for one frame. -}
step : Float -> GameState -> GameState
step dt state =
    let
        fwd =
            forwardH state.yaw

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
            if blocked state.obstacles wantX z0 then
                x0

            else
                wantX

        newZ =
            if blocked state.obstacles newX wantZ then
                z0

            else
                wantZ
    in
    { state | camPos = vec3 newX eyeHeight newZ }


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


blocked : List Box -> Float -> Float -> Bool
blocked obstacles x z =
    (abs x > arenaHalf - 0.5)
        || (abs z > arenaHalf - 0.5)
        || List.any
            (\o ->
                (abs (x - Vec3.getX o.center) < Vec3.getX o.half + playerRadius)
                    && (abs (z - Vec3.getZ o.center) < Vec3.getZ o.half + playerRadius)
            )
            obstacles


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

        obstacleEntities =
            List.map
                (\o ->
                    let
                        model =
                            Mat4.mul (Mat4.makeTranslate o.center) (Mat4.makeScale (Vec3.scale 2 o.half))
                    in
                    entity (mvp model) model 0.5 0 cubeMesh
                )
                state.obstacles

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
            (floorEntity :: obstacleEntities ++ targetEntities)
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
                    "WASD MOVE · MOUSE LOOK · CLICK SHOOT · ESC RELEASE MOUSE"

                 else
                    "WASD MOVE · CLICK TO CAPTURE MOUSE · ESC BACK"
                )
            ]
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
        s =
            arenaHalf

        up =
            vec3 0 1 0
    in
    WebGL.triangles
        [ ( Vertex (vec3 -s 0 -s) up, Vertex (vec3 s 0 -s) up, Vertex (vec3 s 0 s) up )
        , ( Vertex (vec3 -s 0 -s) up, Vertex (vec3 s 0 s) up, Vertex (vec3 -s 0 s) up )
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
        , Browser.Events.onKeyDown (Decode.map (Key True) (Decode.field "key" Decode.string))
        , Browser.Events.onKeyUp (Decode.map (Key False) (Decode.field "key" Decode.string))
        , Ports.pointerLockChanged LockChanged
        ]
