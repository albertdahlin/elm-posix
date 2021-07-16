module Sequence exposing (..)

import Posix.IO as IO exposing (IO)
import Random


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : a -> IO String ()
program _ =
    [ IO.return "Rolled"
    , IO.randomSeed
        |> IO.map
            (\seed ->
                Random.step (Random.int 1 6) seed
                    |> Tuple.first
                    |> String.fromInt
            )
    , IO.sleep 1000
        |> IO.and (IO.return "and waited 1 sec")
    ]
        |> IO.combine
        |> IO.andThen
            (\list ->
                String.join " " list
                    |> IO.printLn
            )



