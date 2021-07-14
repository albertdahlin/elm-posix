module ReadFile exposing (program)

import Dict exposing (Dict)
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.File as File
import Posix.IO.Process as Proc


program : Process -> IO ()
program process =
    case process.argv of
        [ _, filename ] ->
            IO.do
                (File.contentsOf filename
                    |> IO.exitOnError identity
                ) <| \content ->
            IO.do (Proc.print content) <| \_ ->
            IO.return ()

        _ ->
            Proc.logErr ("Usage: elm-cli <program> file\n")


