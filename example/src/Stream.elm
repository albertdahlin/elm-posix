module Stream exposing (..)

{-| Example of reading a stream'
-}

import Posix.IO as IO exposing (IO)
import Posix.IO.File as File
import Posix.IO.Stream as Stream exposing (Stream)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    File.openReadStream { bufferSize = 10 } "elm.json"
        |> IO.andThen
            (\src ->
                src
                    |> Stream.pipeTo Stream.utf8Decode
                    |> Stream.forEach IO.print
            )


