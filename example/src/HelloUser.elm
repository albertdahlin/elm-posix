module HelloUser exposing (program)

import Dict exposing (Dict)
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.File as File


helloUser : Process -> IO ()
helloUser process =
    let
        userName =
            Dict.get "USER" process.env
                |> Maybe.withDefault "Unknown"
    in
    File.write File.stdOut ("Hello, " ++ userName ++ "\n")


program : IO.PosixProgram
program =
    IO.program helloUser
