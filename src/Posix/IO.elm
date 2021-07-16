module Posix.IO exposing
    ( IO, return, fail, none
    , print, printLn, sleep, randomSeed, exit
    , map, andThen, and, combine
    , mapError, recover
    , performTask, attemptTask, callJs, ArgsToJs
    , program, Process, PortIn, PortOut
    )

{-|


# Create IO

@docs IO, return, fail, none


# Basic IO

@docs print, printLn, sleep, randomSeed, exit


# Transforming IO

@docs map, andThen, and, combine


# Handle Errors

@docs mapError, recover


# Low Level

@docs performTask, attemptTask, callJs, ArgsToJs


# Program

@docs program, Process, PortIn, PortOut

-}

import Dict exposing (Dict)
import Internal.ContWithResult as Cont exposing (Cont)
import Internal.Process as Proc exposing (Proc)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Process
import Random
import Task exposing (Task)


{-| -}
type alias PortIn msg =
    Proc.PortIn msg


{-| -}
type alias PortOut msg =
    Proc.PortOut msg


{-| -}
type alias IO err ok =
    Cont Proc err ok


{-| -}
type alias Process =
    { argv : List String
    , pid : Int
    , env : Dict String String
    }


{-| -}
type alias ArgsToJs =
    { fn : String
    , args : List Value
    }


{-| -}
return : a -> IO err a
return a =
    Task.succeed a
        |> performTask


{-| -}
fail : err -> IO err a
fail err =
    Cont.fail err


{-| -}
none : IO x ()
none =
    return ()


{-| -}
printLn : String -> IO x ()
printLn str =
    print (str ++ "\n")


{-| -}
print : String -> IO x ()
print str =
    callJs
        { fn = "fwrite"
        , args = [ Encode.int 1, Encode.string str ]
        }
        (Decode.succeed ())


{-| -}
sleep : Float -> IO x ()
sleep delay =
    Process.sleep delay
        |> performTask


{-| -}
performTask : Task Never a -> IO x a
performTask task =
    Proc.PerformTask task
        |> embend


{-| -}
attemptTask : Task err ok -> IO err ok
attemptTask task =
    \next ->
        task
            |> Task.map Ok
            |> Task.onError (Task.succeed << Err)
            |> Proc.PerformTask
            |> Proc.map next
            |> Proc.Proc


{-| -}
callJs : ArgsToJs -> Decoder a -> IO x a
callJs args decoder =
    Proc.CallJs args decoder
        |> embend


{-| -}
randomSeed : IO x Random.Seed
randomSeed =
    callJs
        { fn = "randomSeed"
        , args = []
        }
        (Decode.int |> Decode.map Random.initialSeed)


{-| -}
exit : Int -> IO x ()
exit status =
    callJs
        { fn = "exit"
        , args = [ Encode.int status ]
        }
        (Decode.fail "")


{-| -}
embend : Proc.Handler a -> IO x a
embend handler =
    \next ->
        Proc.Proc (Proc.map (Ok >> next) handler)


{-| -}
andThen : (a -> IO x b) -> IO x a -> IO x b
andThen =
    Cont.andThen


{-| -}
and : IO x b -> IO x a -> IO x b
and fn io =
    Cont.andThen (\_ -> fn) io


{-| -}
map : (a -> b) -> IO x a -> IO x b
map =
    Cont.map


{-| -}
combine : List (IO err ok) -> IO err (List ok)
combine =
    Cont.combine


{-| -}
mapError : (x -> y) -> IO x a -> IO y a
mapError fn io =
    Cont.mapError fn io


{-| -}
recover : (err -> IO x ok) -> IO err ok -> IO x ok
recover fn io =
    Cont.recover fn io


{-| -}
program : (Process -> IO String ()) -> Proc.PosixProgram
program makeIO =
    Proc.program
        (\env ->
            let
                io =
                    makeIO env
            in
            io
                (\result ->
                    case result of
                        Ok () ->
                            Proc.Proc
                                (Proc.CallJs
                                    { fn = "exit"
                                    , args = [ Encode.int 0 ]
                                    }
                                    (Decode.fail "")
                                )

                        Err error ->
                            Proc.Proc
                                (Proc.CallJs
                                    { fn = "fwrite"
                                    , args =
                                        [ Encode.int 2
                                        , "\nERROR: "
                                            ++ error
                                            ++ "\n"
                                            |> Encode.string
                                        ]
                                    }
                                    (Decode.succeed
                                        (Proc.Proc
                                            (Proc.CallJs
                                                { fn = "exit"
                                                , args = [ Encode.int 255 ]
                                                }
                                                (Decode.fail "")
                                            )
                                        )
                                    )
                                )
                )
        )
