module ReadFile exposing (program)

import Dict exposing (Dict)
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.File as File
import Posix.IO.Process as IO


readFile : Process -> IO ()
readFile process =
    case process.argv of
        [ _, filename ] ->
            IO.do
                (File.contentsOf filename
                    |> IO.exitOnError identity
                ) <| \content ->
            IO.do (IO.print content) <| \_ ->
            IO.return ()

        _ ->
            IO.logErr ("Usage: elm-cli <program> file\n")


program : IO.PosixProgram
program =
    IO.program readFile
