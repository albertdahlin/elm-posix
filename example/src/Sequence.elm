module Sequence exposing (..)

{-| A simple example to show how `combine` can be used
-}
import Posix.IO as IO exposing (IO)
import Posix.IO.Random
import Random


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : a -> IO String ()
program _ =
    [ IO.return "Rolled"
    , Posix.IO.Random.generate (Random.int 1 6)
        |> IO.map String.fromInt
    , IO.sleep 1000
        |> IO.and (IO.return "and waited 1 sec")
    ]
        |> IO.combine
        |> IO.andThen
            (\list ->
                String.join " " list
                    |> IO.printLn
            )



