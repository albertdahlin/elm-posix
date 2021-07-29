module Stream exposing (..)

{-| Loop implementation
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Posix.IO as IO exposing (IO)
import Posix.IO.File as File
import Posix.IO.Stream as Stream exposing (Stream)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    let
        filename =
            case process.argv of
                [ _, str ] ->
                    str

                _ ->
                    "elm.json"
    in
    File.openReadStream filename
        |> IO.andThen
            (\src ->
                src
                    |> Stream.pipeTo Stream.utf8Decode
                    |> Stream.forEach IO.print
            )


