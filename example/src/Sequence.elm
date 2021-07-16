module Sequence exposing (program)

import Posix.IO as IO exposing (IO, Process)
import Posix.IO.Process as Proc


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : Process -> IO String ()
program process =
    "Hello World!\n"
        |> String.split ""
        |> List.map
            (\char ->
                Proc.print char
                    |> IO.and (Proc.sleep 200)
            )
        |> IO.combine
        |> IO.map (\_ -> ())
