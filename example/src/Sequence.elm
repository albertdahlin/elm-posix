module Sequence exposing (..)

{-| A simple example to show how `combine` can be used.
-}
import Posix.IO as IO exposing (IO)
import Posix.IO.Random
import Random


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : a -> IO String ()
program _ =
    IO.print "Roll 5 random numbers: "
        |> IO.and rollFiveNumbers
        |> IO.map
            (List.map String.fromInt
                >> String.join ", "
            )
        |> IO.andThen IO.printLn


rollFiveNumbers : IO x (List Int)
rollFiveNumbers =
    Random.int 1 100
        |> Posix.IO.Random.generate
        |> List.repeat 5
        |> IO.combine
