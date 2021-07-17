module HelloUser exposing (..)

{-| Prints the user name on the terminal.

-}
import Dict exposing (Dict)
import Posix.IO as IO exposing (IO)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    let
        userName =
            Dict.get "USER" process.env
                |> Maybe.withDefault "Unknown"
    in
    IO.printLn ("Hello " ++ userName)



