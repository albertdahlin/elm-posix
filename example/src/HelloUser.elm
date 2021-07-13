module HelloUser exposing (program)

import Dict exposing (Dict)
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.Process as Proc
import Posix.IO.File as File

{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.PosixProgram
program =
    IO.program helloUser


helloUser : Process -> IO ()
helloUser process =
    let
        userName =
            Dict.get "USER" process.env
                |> Maybe.withDefault "Unknown"
    in
    print 10 userName


print : Int -> String -> IO ()
print n userName =
    let
        line =
            "Hello, " ++ String.fromInt n ++ " " ++ userName
    in
    IO.do (Proc.sleep 100) <| \_ ->
    IO.do (Proc.print line) <| \_ ->

    if n <= 1 then
        IO.return ()

    else
        print (n - 1) userName



