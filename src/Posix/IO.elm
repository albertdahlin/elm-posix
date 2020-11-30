module Posix.IO exposing
    ( IO, return, do, map, exitOnError
    , Process, PosixProgram, program
    )

{-|


# IO Monad

@docs IO, return, do, map, exitOnError


# Create IO Program

@docs Process, PosixProgram, program

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


{-| -}
do : IO a -> (a -> IO b) -> IO b
do =
    IO.do


{-| -}
map : (a -> b) -> IO a -> IO b
map =
    IO.map


{-| Print to stderr and exit program on `Err`
-}
exitOnError : (e -> String) -> IO (Result e a) -> IO a
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
