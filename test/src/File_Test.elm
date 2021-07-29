module File_Test exposing (..)

{-| -}

import Json.Decode as Decode
import Posix.IO as IO exposing (IO)
import Posix.IO.File as File
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
        |> IO.mapError File.errorToString


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
                    File.OpenError (File.FileDoesNotExist msg) ->
                        IO.return test.pass

                    _ ->
                        File.errorToString err
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
                    File.OpenError (File.MissingPermission msg) ->
                        IO.return test.pass

                    _ ->
                        File.errorToString err
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
                    File.OpenError (File.IsDirectory msg) ->
                        IO.return test.pass

                    _ ->
                        File.errorToString err
                            |> test.fail
                            |> IO.return
            )

decodeTypeField =
    Decode.field "type" Decode.string