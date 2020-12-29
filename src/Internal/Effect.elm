module Internal.Effect exposing (..)

import Internal.IO


type alias IO a =
    Internal.IO.IO Effect a


type Effect
    = Exit Int
    | File File
    | Sleep Float
    | NoOp


type File
    = Read Int
    | Write Int String
    | Open String String
    | Stat String
    | ReadDir String


