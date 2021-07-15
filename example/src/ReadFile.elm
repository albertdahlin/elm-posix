module ReadFile exposing (program)

import Dict exposing (Dict)
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.File as File
import Posix.IO.Process as Proc


program : Process -> IO String ()
program process =
    case process.argv of
        [ _, filename ] ->
            File.contentsOf filename
                |> IO.andThen Proc.print

        _ ->
            Proc.logErr ("Usage: elm-cli <program> file\n")


