module Stream_Test exposing (..)

import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import Json.Decode as Decode exposing (Decoder)
import Posix.IO as IO exposing (IO)
import Posix.IO.File as File
import Posix.IO.File.Permission as Permission
import Posix.IO.Stream as Stream
import Test exposing (Test)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    [ readElmJson
    , readBytes
    , readEOF
    , readUtf8
    , writeUtf8
    , writeBin
    , streamLines
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
            Test.name "read stream until EOF"
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


readUtf8 : Test
readUtf8 =
    let
        test =
            Test.name "read stream decode UTF-8"
    in
    File.read "utf8.txt"
        |> IO.andThen
            (\stringFromFile ->
                File.openReadStream { bufferSize = 5 } "utf8.txt"
                    |> IO.andThen
                        (Stream.pipeTo Stream.utf8Decode
                            >> Stream.collect (\s acc -> acc ++ s) ""
                        )
                    |> IO.map
                        (\stringFromStream ->
                            if stringFromFile == stringFromStream then
                                test.pass

                            else
                                test.fail
                                    ("\n"
                                        ++ stringFromStream
                                        ++ "\nexpected:\n"
                                        ++ stringFromFile
                                    )
                        )
            )


writeUtf8 : Test
writeUtf8 =
    let
        test =
            Test.name "write stream UTF-8"

        testFile =
            "tmp/stream-write-utf8.txt"
    in
    File.openWriteStream (File.CreateIfNotExists File.Truncate Permission.default) testFile
        |> IO.andThen
            (\targetFile ->
                let
                    utf8Stream =
                        Stream.utf8Encode
                            |> Stream.pipeTo targetFile
                in
                Stream.write "ÅÅÅÅ" utf8Stream
                    |> IO.and (Stream.write "öööö" utf8Stream)
                    |> IO.and (File.read testFile)
                    |> IO.map
                        (\stringFromStream ->
                            if "ÅÅÅÅöööö" == stringFromStream then
                                test.pass

                            else
                                test.fail
                                    ("\n"
                                        ++ stringFromStream
                                        ++ "\nexpected: ÅÅÅÅöööö\n"
                                    )
                        )
            )


writeBin : Test
writeBin =
    let
        test =
            Test.name "write stream binary"

        testFile =
            "tmp/stream-write-bin.txt"

        testData =
            [ 0xFF, 0x80, 0x40, 0x20, 0x00, 0x01, 0x02, 0x04 ]
    in
    File.openWriteStream (File.CreateIfNotExists File.Truncate Permission.default) testFile
        |> IO.andThen
            (\targetFile ->
                Stream.write (List.take 4 testData |> intToBytes) targetFile
                    |> IO.and (Stream.write (List.drop 4 testData |> intToBytes) targetFile)
                    |> IO.and
                        (File.openReadStream File.defaultReadOptions testFile
                            |> IO.andThen Stream.read
                        )
                    |> IO.map
                        (\maybeBytes ->
                            case maybeBytes of
                                Just bytes ->
                                    case decodeBytes bytes of
                                        Just data ->
                                            if testData == data then
                                                test.pass

                                            else
                                                test.fail
                                                    ("\n"
                                                        ++ String.join ", " (List.map String.fromInt data)
                                                        ++ "\nexpected: "
                                                        ++ String.join ", " (List.map String.fromInt testData)
                                                    )

                                        Nothing ->
                                            test.fail "Could not decode bytes"

                                Nothing ->
                                    test.fail "Got EOF"
                        )
            )


streamLines : Test
streamLines =
    let
        testFile =
            "utf8.txt"

        test =
            Test.name "stream lines"
    in
    File.read testFile
        |> IO.andThen
            (\content ->
                File.openReadStream { bufferSize = 10 } testFile
                    |> IO.andThen
                        (Stream.pipeTo Stream.utf8Decode
                            >> Stream.pipeTo Stream.line
                            >> Stream.collect (\line count -> count + 1) 0
                        )
                    |> IO.map
                        (\streamLineCount ->
                            let
                                realLineCount =
                                    String.split "\n" content
                                        |> List.length
                            in
                            if realLineCount == streamLineCount then
                                test.pass

                            else
                                "Got line count: "
                                    ++ String.fromInt streamLineCount
                                    ++ ", expecting: "
                                    ++ String.fromInt realLineCount
                                    |> test.fail
                        )
            )


decodeTypeField : Decoder String
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


intToBytes : List Int -> Bytes
intToBytes list =
    List.map Bytes.Encode.unsignedInt8 list
        |> Bytes.Encode.sequence
        |> Bytes.Encode.encode
