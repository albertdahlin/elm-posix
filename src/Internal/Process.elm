module Internal.Process exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type Process eff
    = Process (Decoder ( Process eff, eff ))


step : Value -> Process eff -> Result Decode.Error ( Process eff, eff )
step value (Process decoder) =
    Decode.decodeValue decoder value
