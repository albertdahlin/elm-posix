module Internal.Stream exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Bytes exposing (Bytes)
import Bytes.Encode


type Stream input output
    = Stream (List Pipe) (input -> Encode.Value) (Decoder output)


encodePipe : Pipe -> Encode.Value
encodePipe pipe =
    Encode.object
        [ ( "id", Encode.string pipe.id )
        , ( "args", Encode.list identity pipe.args )
        ]


type alias Pipe =
    { id : String
    , args : List Encode.Value
    }


notImplemented : Stream a b
notImplemented =
    Stream [] (\_ -> Encode.null) (Decode.fail "Not implemented")


decodeBytes : Decoder Bytes
decodeBytes =
    Decode.list Decode.int
        |> Decode.map
            (List.map Bytes.Encode.unsignedInt8
                >> Bytes.Encode.sequence
                >> Bytes.Encode.encode
            )

