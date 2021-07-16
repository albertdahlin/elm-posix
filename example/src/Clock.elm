module Clock exposing (..)


import Dict exposing (Dict)
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.Process as Proc
import Time


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : Process -> IO String ()
program process =
    Proc.printLn "Press Ctrl+C two times to exit"
        |> IO.and Proc.here
        |> IO.andThen (\zone -> printTime zone ())


printTime : Time.Zone -> () -> IO String ()
printTime zone _ =
    Proc.now
        |> IO.map (toHHMMSS Time.utc)
        |> IO.andThen Proc.printLn
        |> IO.and (Proc.sleep 1000)
        |> IO.andThen (printTime zone)


toHHMMSS : Time.Zone -> Time.Posix -> String
toHHMMSS zone posix =
    let
        pad n =
            String.fromInt n
                |> String.padLeft 2 '0'

        h =
            Time.toHour zone posix

        m =
            Time.toMinute zone posix

        s =
            Time.toSecond zone posix
    in
    [ pad h
    , pad m
    , pad s
    ]
        |> String.join ":"

