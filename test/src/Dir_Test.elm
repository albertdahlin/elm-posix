module Dir_Test exposing (..)

import List.Extra as List
import Posix.IO as IO exposing (IO)
import Posix.IO.Directory as Dir
import Posix.IO.File as File
import Posix.IO.File.Permission as Permission
import Test exposing (Test)
import Time


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    [ statDir
    , statFile
    , listDir
    ]
        |> Test.run


statDir : Test
statDir =
    let
        test =
            Test.name "stat dir"
    in
    Dir.stat "./src"
        |> IO.map
            (\entry ->
                if entry.type_ == Dir.Dir then
                    test.pass

                else
                    test.fail "Not a dir"
            )


statFile : Test
statFile =
    let
        test =
            Test.name "stat file"
    in
    Dir.stat "elm.json"
        |> IO.map
            (\entry ->
                if entry.type_ == Dir.File then
                    test.pass

                else
                    test.fail "Not a file"
            )


listDir : Test
listDir =
    let
        test =
            Test.name "list dir"
    in
    Dir.list "."
        |> IO.map
            (\dirs ->
                case List.find (\f -> f.name == "src") dirs of
                    Just entry ->
                        if entry.type_ == Dir.Dir then
                            test.pass

                        else
                            test.fail "scr is not a dir"

                    Nothing ->
                        test.fail "no src dir found"
            )
