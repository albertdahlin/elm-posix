module Roll exposing (..)

{-| Rolls a randum number between 1 and 6.
-}
import Posix.IO as IO exposing (IO)
import Random


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : a -> IO String ()
program _ =
    IO.randomSeed
        |> IO.andThen
            (\seed ->
                Random.step (Random.int 1 6) seed
                    |> Tuple.first
                    |> String.fromInt
                    |> IO.printLn
            )



