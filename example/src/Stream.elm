module Stream exposing (..)

{-| Example of reading a stream.

Read a CSV file line by line and convert each row to a JSON object.

-}

import Json.Encode as Encode
import Posix.IO as IO exposing (IO)
import Posix.IO.File as File
import Posix.IO.Stream as Stream exposing (Stream)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    File.openReadStream { bufferSize = 10 } "test.csv"
        |> IO.andThen
            (\testCsvStream ->
                let
                    rowStream =
                        testCsvStream
                            |> Stream.pipeTo Stream.utf8Decode
                            |> Stream.pipeTo Stream.line
                in
                Stream.read rowStream
                    |> IO.andThen
                        (\maybeRow0 ->
                            let
                                columns =
                                    Maybe.withDefault "" maybeRow0
                                        |> String.split ","
                            in
                            Stream.forEach
                                (\row ->
                                    if String.isEmpty row then
                                        IO.none

                                    else
                                        let
                                            values =
                                                String.split "," row
                                        in
                                        List.map Encode.string values
                                            |> List.map2 Tuple.pair columns
                                            |> Encode.object
                                            |> Encode.encode 2
                                            |> IO.printLn
                                )
                                rowStream
                        )
            )
