module Forever exposing (..)

{-| Print forever
-}

import Posix.IO as IO exposing (IO)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    forever print 1
        |> IO.and IO.none


print : Int -> IO String Int
print count =
    IO.printLn (String.fromInt count)
        |> IO.and (IO.return <| count + 1)


forever : (next -> IO err next) -> next -> IO err next
forever nextIO value =
    nextIO value
        |> IO.andThen (forever nextIO)
