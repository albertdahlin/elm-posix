module Stream_Test exposing (..)

import Bytes exposing (Bytes)
import Bytes.Decode
import Json.Decode as Decode
import Posix.IO as IO exposing (IO)
import Posix.IO.File as File
import Posix.IO.Stream as Stream
import Test exposing (Test)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    [ readElmJson
    , readBytes
    , readEOF
    ]
        |> Test.run


readElmJson : Test
readElmJson =
    let
        test =
            Test.name "read elm.json"
    in
    File.openReadStream File.defaultReadOptions "elm.json"
        |> IO.andThen
            (Stream.pipeTo Stream.utf8Decode
                >> Stream.collect (\s acc -> acc ++ s) ""
            )
        |> IO.map
            (\elmJson ->
                case Decode.decodeString decodeTypeField elmJson of
                    Ok "application" ->
                        test.pass

                    Ok v ->
                        "Unexpected value " ++ v |> test.fail

                    Err e ->
                        test.fail (Decode.errorToString e)
            )


readBytes : Test
readBytes =
    let
        test =
            Test.name "read bytes.bin"
    in
    File.openReadStream File.defaultReadOptions "bytes.bin"
        |> IO.andThen Stream.read
        |> IO.map
            (\mbBytes ->
                case mbBytes of
                    Just bytes ->
                        case decodeBytes bytes of
                            Just [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] ->
                                test.pass

                            Just list ->
                                List.map String.fromInt list
                                    |> String.join ", "
                                    |> test.fail

                            Nothing ->
                                test.fail "Could not decode bytes"

                    Nothing ->
                        test.fail "No bytes read"
            )


readEOF : Test
readEOF =
    let
        test =
            Test.name "read until EOF"
    in
    File.openReadStream File.defaultReadOptions "bytes.bin"
        |> IO.andThen
            (\file ->
                Stream.read file
                    |> IO.andThen (\_ -> Stream.read file)
            )
        |> IO.map
            (\mbBytes ->
                case mbBytes of
                    Just _ ->
                        test.fail "Not at EOF"

                    Nothing ->
                        test.pass
            )


decodeTypeField =
    Decode.field "type" Decode.string


decodeBytes : Bytes -> Maybe (List Int)
decodeBytes bytes =
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
