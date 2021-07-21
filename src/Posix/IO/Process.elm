module Posix.IO.Process exposing
    ( Exit, exec, execFile, failOnError
    , Pid, spawn, wait, kill, send, receive, Message(..)
    )

{-|


# Execute shell commands

@docs Exit, exec, execFile, failOnError


# Spawn child processes

@docs Pid, spawn, wait, kill, send, receive, Message

-}

import Internal.Stream as Internal
import Posix.IO as IO exposing (IO)


{-| -}
type Pid
    = Pid


{-| Sub-Process exit data.
-}
type alias Exit =
    { status : Int
    , stdOut : String
    , stdErr : String
    }


{-| Execute a shell command.

    exec "ls -l"

-}
exec : String -> IO String Exit
exec cmd =
    IO.fail ""


{-| Execute file with args

    execFile "path/to/file" [ "arg1", "arg2" ]

-}
execFile : String -> List String -> IO String Exit
execFile cmd args =
    IO.fail ""


{-| Make program fail if the status code is not zero.
Also unpacks stdOut and stdErr as `IO <stdErr> <stdOut>`.

    exec "whoami"
        |> failOnError
        |> IO.andThen
            (\usename ->
                IO.printLn ("Hello, " ++ username)
            )
-}
failOnError : IO String Exit -> IO String String
failOnError io =
    IO.andThen
        (\exit ->
            if exit.status == 0 then
                IO.return exit.stdOut

            else
                IO.fail exit.stdErr
        )
        io


{-| Spawn a child process

    spawn cmd args

-}
spawn : String -> List String -> IO String Pid
spawn cmd args =
    IO.fail ""


{-| Wait for child process to exit.
-}
wait : Pid -> IO String Exit
wait pid =
    IO.fail ""


{-| Kill process.
-}
kill : Pid -> IO String Exit
kill pid =
    IO.fail ""


{-| Send a message to standard in (stdin) of a child process
-}
send : Pid -> String -> IO String ()
send pid args =
    IO.fail ""


{-| -}
type Message
    = Exited Exit
    | Message String


{-| Recevie a message from a child process. Will block
until some data is available or the timeout occurs.

    receive <timeout> <pid>

-}
receive : Float -> Pid -> IO String Message
receive timeout pid =
    IO.fail ""
