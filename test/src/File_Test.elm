module File_Test exposing (..)

{-| -}

import Json.Decode as Decode
import Posix.IO as IO exposing (IO)
import Posix.IO.File as File
import Posix.IO.File.Permission as Permission
import Posix.IO.Random
import Random
import Test exposing (Test)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    [ testRead
    , testRead_
    , testFileNotFound
    , testNoPermission
    , testIsDir
    , testWrite
    , testWriteExclusive
    , testAppend
    ]
        |> Test.run


testRead : Test
testRead =
    let
        test =
            Test.name "read"
    in
    File.read "elm.json"
        |> IO.map
            (\str ->
                case Decode.decodeString decodeTypeField str of
                    Ok "application" ->
                        test.pass

                    Ok v ->
                        "Unexpected value " ++ v |> test.fail

                    Err e ->
                        test.fail (Decode.errorToString e)
            )


testRead_ : Test
testRead_ =
    let
        test =
            Test.name "read_"
    in
    File.read_ "elm.json"
        |> IO.map
            (\str ->
                case Decode.decodeString decodeTypeField str of
                    Ok "application" ->
                        test.pass

                    Ok v ->
                        "Unexpected value " ++ v |> test.fail

                    Err e ->
                        test.fail (Decode.errorToString e)
            )
        |> IO.mapError File.readErrorToString


testFileNotFound : Test
testFileNotFound =
    let
        test =
            Test.name "Err FileDoesNotExist"
    in
    File.read_ "file that does not exist"
        |> IO.map
            (\_ ->
                test.fail "File exists"
            )
        |> IO.recover
            (\err ->
                case err of
                    File.CouldNotOpenRead (File.FileDoesNotExist msg) ->
                        IO.return test.pass

                    _ ->
                        File.readErrorToString err
                            |> test.fail
                            |> IO.return
            )


testNoPermission : Test
testNoPermission =
    let
        test =
            Test.name "MissingPermisison error"
    in
    File.read_ "/root/"
        |> IO.map
            (\_ ->
                test.fail "Missing permissions should result in an error"
            )
        |> IO.recover
            (\err ->
                case err of
                    File.CouldNotOpenRead (File.MissingPermission msg) ->
                        IO.return test.pass

                    _ ->
                        File.readErrorToString err
                            |> test.fail
                            |> IO.return
            )


testIsDir : Test
testIsDir =
    let
        test =
            Test.name "open dir should result in an error"
    in
    File.read_ "src"
        |> IO.map
            (\_ ->
                test.fail "Should not be able to see /root"
            )
        |> IO.recover
            (\err ->
                case err of
                    File.CouldNotOpenRead (File.IsDirectory msg) ->
                        IO.return test.pass

                    _ ->
                        File.readErrorToString err
                            |> test.fail
                            |> IO.return
            )


testWrite : Test
testWrite =
    let
        test =
            Test.name "Write"

        testFile =
            "tmp/write-test.txt"
    in
    Posix.IO.Random.generate (Random.int 1 1000000)
        |> IO.andThen
            (\num ->
                File.write
                    (File.CreateIfNotExists File.Truncate Permission.default)
                    testFile
                    (String.fromInt num)
                    |> IO.and
                        (File.read testFile
                            |> IO.map
                                (\content ->
                                    if content == String.fromInt num then
                                        test.pass

                                    else
                                        test.fail "Content read does not match"
                                )
                        )
            )


testWriteExclusive : Test
testWriteExclusive =
    let
        test =
            Test.name "Write Exclusive Error"

        testFile =
            "tmp/write-test-exclusive.txt"
    in
    File.write
        (File.CreateIfNotExists File.Truncate Permission.default)
        testFile
        "test"
        |> IO.and
            (File.write_
                (File.FailIfExists Permission.default)
                testFile
                "test"
                |> IO.map (\_ -> test.fail "File write should not succeed")
                |> IO.recover
                    (\err ->
                        case err of
                            File.CouldNotOpenWrite (File.FileAlreadyExists _) ->
                                IO.return test.pass

                            _ ->
                                File.writeErrorToString err
                                    |> test.fail
                                    |> IO.return
                    )
            )


testAppend : Test
testAppend =
    let
        test =
            Test.name "Write Append"

        testFile =
            "tmp/write-test-append.txt"

        append content =
            File.write
                (File.CreateIfNotExists File.Append Permission.default)
                testFile
                content
    in
    append "A"
        |> IO.and (append "B")
        |> IO.and
            (File.read testFile
                |> IO.map
                    (\content ->
                        if content == "AB" then
                            test.pass

                        else
                            test.fail "Content read does not match"
                    )
            )


decodeTypeField =
    Decode.field "type" Decode.string
