module Clock exposing (..)

{-| Prints the time on the terminal every second.

-}
import Posix.IO as IO exposing (IO)
import Time


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : a -> IO String ()
program _ =
    IO.printLn "Press Ctrl+C to exit."
        |> IO.and (IO.performTask Time.here)
        |> IO.andThen (\zone -> printTime zone ())


printTime : Time.Zone -> () -> IO String ()
printTime zone _ =
    IO.performTask Time.now
        |> IO.map (toHHMMSS zone)
        |> IO.andThen IO.printLn
        |> IO.and (IO.sleep 1000)
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
