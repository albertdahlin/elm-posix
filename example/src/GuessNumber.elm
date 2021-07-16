module GuessNumber exposing (..)

import Dict exposing (Dict)
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.Process as Proc


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : Process -> IO String ()
program process =
    let
        userName =
            Dict.get "USER" process.env
                |> Maybe.withDefault "Unknown"
    in
    Proc.print "Hello, "
        |> IO.and (Proc.sleep 500)
        |> IO.and (Proc.printLn userName)
        |> IO.and (Proc.sleep 500)
