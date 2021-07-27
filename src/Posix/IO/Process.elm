module Posix.IO.Process exposing
    ( Exit, exec, execFile, failOnError
    , spawn, Process, Pid, wait, kill, Signal(..)
    )

{-| This module provides an API for executing shell
commands and spawning child processes.


# Blocking API

These operations will spawn a sub-process
and wait for it to exit.

@docs exec, execFile, Exit, failOnError


# Non-Blocking API

@docs spawn, Process, Pid, wait, kill, Signal

-}

import Dict exposing (Dict)
import Bytes exposing (Bytes)
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


type alias Options =
    { cwd : String
    , env : Dict String String
    , timeout : Int
    , uid : Int
    , gid : Int
    }

{-| Execute a shell command and wait until it exits.

    exec "ls -l"

-}
exec : String -> IO String Exit
exec cmd =
    IO.fail ""


{-| Execute file with args and wait until it exits.

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


{-|
-}
type alias Process =
    { pid : Pid
    , stdIn : Internal.Stream Bytes Never
    , stdOut : Internal.Stream Never Bytes
    , stdErr : Internal.Stream Never Bytes
    }


{-| Spawn a child process without blocking.

    spawn cmd args

-}
spawn :
    String
    -> List String
    -> IO String Process
spawn cmd args =
    IO.fail ""


{-| Wait for child process to exit.
-}
wait : Pid -> IO String Int
wait pid =
    IO.fail ""


{-| Posix signal

<https://man7.org/linux/man-pages/man7/signal.7.html>

-}
type Signal
    = SIGALRM
    | SIGBUS
    | SIGCHLD
    | SIGCLD
    | SIGCONT
    | SIGEMT
    | SIGFPE
    | SIGHUP
    | SIGILL
    | SIGINFO
    | SIGINT
    | SIGIO
    | SIGIOT
    | SIGKILL
    | SIGLOST
    | SIGPIPE
    | SIGPOLL
    | SIGPROF
    | SIGPWR
    | SIGQUIT
    | SIGSEGV
    | SIGSTKFLT
    | SIGSTOP
    | SIGTSTP
    | SIGSYS
    | SIGTERM
    | SIGTRAP
    | SIGTTIN
    | SIGTTOU
    | SIGUNUSED
    | SIGURG
    | SIGUSR1
    | SIGUSR2
    | SIGVTALRM
    | SIGXCPU
    | SIGXFSZ
    | SIGWINCH


{-| Send a signal to a child process.
-}
kill : Signal -> Pid -> IO String ()
kill sig pid =
    IO.fail ""

