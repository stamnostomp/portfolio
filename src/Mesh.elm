module Mesh exposing (fullscreenMesh)

import Math.Vector3 as Vec3
import WebGL



-- Full screen quad mesh for 2D effects


fullscreenMesh : WebGL.Mesh { position : Vec3.Vec3 }
fullscreenMesh =
    WebGL.triangles
        [ ( { position = Vec3.vec3 -1 -1 0 }
          , { position = Vec3.vec3 1 -1 0 }
          , { position = Vec3.vec3 1 1 0 }
          )
        , ( { position = Vec3.vec3 -1 -1 0 }
          , { position = Vec3.vec3 1 1 0 }
          , { position = Vec3.vec3 -1 1 0 }
          )
        ]
