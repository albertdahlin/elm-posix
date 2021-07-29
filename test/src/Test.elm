module Test exposing (..)

import Console
import Posix.IO as IO exposing (IO)


type alias Test =
    IO String (Result String String)


run : List Test -> IO String ()
run t =
    t
        |> List.reverse
        |> List.map
            (IO.andThen
                (\res ->
                    case res of
                        Ok o ->
                            "PASS: "
                                ++ Console.green o
                                |> IO.printLn

                        Err e ->
                            "FAIL: "
                                ++ Console.red e
                                |> IO.fail
                )
            )
        |> IO.combine
        |> IO.and IO.none


name n =
    { pass = Ok n
    , fail = \msg -> n ++ " - " ++ msg |> Err
    }
