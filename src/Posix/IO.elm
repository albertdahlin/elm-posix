module Posix.IO exposing
    ( IO, return, map, do, andThen, combine, exitOnError
    , Process, program, PosixProgram
    )

{-|


# IO Monad

@docs IO, return, map, do, andThen, combine, exitOnError


# Create IO Program

@docs Process, program, PosixProgram

-}

import Dict exposing (Dict)
import Internal.Effect as Effect exposing (Effect)
import Internal.IO as IO
import Internal.Program
import Json.Decode as Decode exposing (Decoder)


{-| -}
type alias IO a =
    Effect.IO a


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
return : a -> IO a
return a =
    IO.make (Decode.succeed a) Effect.NoOp


{-| Compose IO actions, do-notation style.

    do (File.open "file.txt" |> exitOnError identity) <| \fd ->
    do (File.write fd "Hello, World")

-}
do : IO a -> (a -> IO b) -> IO b
do =
    IO.do


{-| Compose IO actions, `andThen` style

    File.open "file.txt"
        |> exitOnError identity
        |> andThen
            (\fd ->
                File.write fd "Hello, World"
            )

-}
andThen : (a -> IO b) -> IO a -> IO b
andThen a b =
    IO.do b a


{-| -}
map : (a -> b) -> IO a -> IO b
map =
    IO.map


{-| Print to stderr and exit program on `Err`
-}
exitOnError : (error -> String) -> IO (Result error a) -> IO a
exitOnError toErrorMsg io =
    IO.do io
        (\result ->
            case result of
                Ok a ->
                    return a

                Err e ->
                    IO.do
                        (IO.make
                            (Decode.succeed ())
                            (Effect.File <| Effect.Write 2 (toErrorMsg e))
                        )
                    <|
                        \_ ->
                            IO.make
                                (Decode.fail "")
                                (Effect.Exit 255)
        )


{-| Perform IO in sequence
-}
combine : List (IO a) -> IO (List a)
combine list =
    case list of
        x :: xs ->
            List.foldl
                (\ioA ioListOfA ->
                    IO.do ioListOfA (\listOfA -> IO.map (\a -> a :: listOfA) ioA)
                )
                (IO.map List.singleton x)
                xs
                |> IO.map List.reverse

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
program : (Process -> IO ()) -> Internal.Program.PosixProgram
program =
    Internal.Program.program
