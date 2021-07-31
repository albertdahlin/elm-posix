module Internal.Stream exposing (..)

import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Stream input output
    = Stream (List Pipe) (input -> Encode.Value) (Decoder output)


encodePipe : Pipe -> Encode.Value
encodePipe pipe =
    Encode.object
        [ ( "id", Encode.string pipe.id )
        , ( "args", Encode.list identity pipe.args )
        ]


decoder : (i -> Encode.Value) -> Decoder o -> Decoder (Stream i o)
decoder e d =
    Decode.field "id" Decode.string
        |> Decode.map
            (\id ->
                Stream [ { id = id, args = [] } ] e d
            )


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
        |> Decode.map listToBytes


listToBytes : List Int -> Bytes
listToBytes =
    List.map Bytes.Encode.unsignedInt8
        >> Bytes.Encode.sequence
        >> Bytes.Encode.encode


encodeBytes : Bytes -> Encode.Value
encodeBytes bytes =
    bytesToList bytes
        |> Maybe.map (Encode.list Encode.int)
        |> Maybe.withDefault Encode.null


bytesToList : Bytes -> Maybe (List Int)
bytesToList bytes =
    Bytes.Decode.decode
        (decodeBytesList
            |> Bytes.Decode.loop
                ( Bytes.width bytes, [] )
        )
        bytes


decodeBytesList :
    ( Int, List Int )
    -> Bytes.Decode.Decoder (Bytes.Decode.Step ( Int, List Int ) (List Int))
decodeBytesList ( n, xs ) =
    if n <= 0 then
        Bytes.Decode.succeed (Bytes.Decode.Done <| List.reverse xs)

    else
        Bytes.Decode.map
            (\x -> Bytes.Decode.Loop ( n - 1, x :: xs ))
            Bytes.Decode.unsignedInt8
