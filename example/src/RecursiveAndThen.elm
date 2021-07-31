module RecursiveAndThen exposing (..)

{-| Print forever
-}

import Posix.IO as IO exposing (IO)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    IO.printLn "Repeat I/O 5000 times to check that stack does not blow up."
        |> IO.and
            (IO.print "."
                |> repeat 5000
            )


repeat : Int -> IO String () -> IO String ()
repeat n io =
    if n <= 0 then
        IO.none

    else
        io
            |> IO.andThen (\_ -> repeat (n - 1) io)
