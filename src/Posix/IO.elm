module Posix.IO exposing
    ( IO, return, map, do, andThen, and, combine, exitOnError
    , Process, program, PosixProgram, PortIn, PortOut
    )

{-|


# IO Monad

@docs IO, return, map, do, andThen, and, combine, exitOnError


# Create IO Program

@docs Process, program, PosixProgram, PortIn, PortOut

-}

import Dict exposing (Dict)
import Internal.Effect as Effect exposing (Effect)
import Internal.IO as IO
import Internal.Program
import Json.Decode as Decode exposing (Decoder)


{-| -}
type alias IO err a =
    Effect.IO (Result err a)


{-| -}
type alias Process =
    { argv : List String
    , pid : Int
    , env : Dict String String
    }


{-| -}
type alias PosixProgram =
    Internal.Program.PosixProgram


{-| -}

type alias PortIn msg =
    Internal.Program.PortIn msg

{-| -}
type alias PortOut msg =
    Internal.Program.PortOut msg

{-| -}
return : a -> IO err a
return a =
    IO.make (Decode.succeed (Ok a)) Effect.NoOp


fail : err -> IO err a
fail err =
    IO.make (Decode.succeed (Err err)) Effect.NoOp


{-| Compose IO actions, do-notation style.

    do (File.open "file.txt" |> exitOnError identity) <|
        \fd ->
            do (File.write fd "Hello, World")

-}
do : IO x a -> (a -> IO x b) -> IO x b
do i nxt =
    IO.do i
        (\result ->
            case result of
                Ok a ->
                    nxt a

                Err e ->
                    fail e
        )


{-| Compose IO actions, `andThen` style

    File.open "file.txt"
        |> exitOnError identity
        |> andThen
            (\fd ->
                File.write fd "Hello, World"
            )

-}
andThen : (a -> IO x b) -> IO x a -> IO x b
andThen a b =
    do b a

{-| Chain output io

    Process.print "hello"
        |> IO.and (Process.print "world")

    instead of

    Process.print "hello"
        |> IO.andThen (\_ -> Process.print "world")

-}
and : IO x b -> IO x () -> IO x b
and b a =
    andThen (\_ -> b) a

{-| -}
map : (a -> b) -> IO x a -> IO x b
map fn =
    IO.map (Result.map fn)


{-| Print to stderr and exit program on `Err`
-}
exitOnError : (error -> String) -> IO error a -> IO String a
exitOnError toErrorMsg io =
    IO.do io
        (\result ->
            case result of
                Ok a ->
                    return a

                Err e ->
                    fail (toErrorMsg e)
        )


{-| Perform IO in sequence
-}
combine : List (IO e a) -> IO x (List (Result e a))
combine list =
    case list of
        x :: xs ->
            List.foldl
                (\ioA ioListOfA ->
                    IO.do ioListOfA
                        (\listOfA -> IO.map (\a -> a :: listOfA) ioA)
                )
                (IO.map List.singleton x)
                xs
                |> IO.map (List.reverse >> Ok)

        [] ->
            return []


{-|

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
        File.write File.stdOut userName

    program : IO.PosixProgram
    program =
        IO.program helloUser

-}
program : (Process -> IO String ()) -> Internal.Program.PosixProgram
program makeP =
    Internal.Program.program
        (\proc ->
            IO.do (makeP proc)
                (\result ->
                    case result of
                        Ok _ ->
                            IO.make (Decode.succeed ()) Effect.NoOp

                        Err err ->
                            IO.do
                                (IO.make
                                    (Decode.succeed ())
                                    (Effect.File <| Effect.Write 2 err)
                                )
                            <|
                                \_ ->
                                    IO.make
                                        (Decode.fail "")
                                        (Effect.Exit 255)
                )
        )
