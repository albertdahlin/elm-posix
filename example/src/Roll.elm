module Roll exposing (..)

{-| Rolls a random number.
-}

import Posix.IO as IO exposing (IO)
import Posix.IO.Random
import Random


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    let
        highLimit =
            parseHighValue process.argv
                |> Maybe.withDefault 100
    in
    Posix.IO.Random.generate (Random.int 1 highLimit)
        |> IO.andThen
            (\randomNumber ->
                IO.printLn (String.fromInt randomNumber ++ " (" ++ String.fromInt highLimit ++ ")")
            )


parseHighValue : List String -> Maybe Int
parseHighValue args =
    case args of
        [ _, str ] ->
            String.toInt str

        _ ->
            Nothing
