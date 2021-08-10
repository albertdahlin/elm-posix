module Dir_Test exposing (..)

import Posix.IO as IO exposing (IO)
import Posix.IO.File as File
import Posix.IO.Directory as Dir
import Posix.IO.File.Permission as Permission
import Test exposing (Test)
import Time


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    [ statDir
    , statFile
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
