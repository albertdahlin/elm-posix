module ReadFile exposing (..)

{-| -}

import Json.Decode exposing (Decoder)
import Posix.IO as IO exposing (IO)
import Posix.IO.File as File


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    File.read "elm.json"
        |> IO.andThen
            (\elmJson ->
                case Json.Decode.decodeString decoder elmJson of
                    Ok elmVersion ->
                        IO.printLn ("Elm version is: " ++ elmVersion)

                    Err err ->
                        IO.fail (Json.Decode.errorToString err)
            )


decoder : Decoder String
decoder =
    Json.Decode.field "elm-version" Json.Decode.string

