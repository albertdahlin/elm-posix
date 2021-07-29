module ReadFile exposing (..)

{-| -}

import Posix.IO as IO exposing (IO)
import Posix.IO.File as File


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    File.read (getFile process.argv)
        |> IO.andThen IO.printLn


getFile : List String -> String
getFile list =
    case list of
        [ _, filename ] ->
            filename

        _ ->
            "elm.json"
