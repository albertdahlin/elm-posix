module Internal.Effect exposing (..)

import Internal.IO


type alias IO a =
    Internal.IO.IO Effect a


type Effect
    = Exit Int
    | File File
    | NoOp


type File
    = Read Int
    | Write Int String
    | Open String


