module HelloUser exposing (program)

import Dict exposing (Dict)
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.Process as Proc
import Posix.IO.File as File

{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : Process -> IO String ()
program process =
    let
        userName =
            Dict.get "USER" process.env
                |> Maybe.withDefault "Unknown"
    in
    print 10 userName


print : Int -> String -> IO String ()
print n userName =
    let
        line =
            "Hello, " ++ String.fromInt n ++ " " ++ userName
    in
    Proc.sleep 100
        |> IO.and (Proc.print line)
        |> IO.and
            (
                if n <= 1 then
                    IO.return ()

                else
                    print (n - 1) userName
            )



