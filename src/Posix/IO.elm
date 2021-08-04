module Posix.IO exposing
    ( IO, return, fail, none, fromResult
    , print, printLn, sleep, exit
    , map, andMap, andThen, and, combine
    , mapError, recover
    , performTask, attemptTask
    , callJs
    , makeProgram, Process, PortIn, PortOut
    )

{-|


# Create IO

The `IO err ok` type is very similar in concept to `Task err ok`. The first parameter is the error
value, the second value is the "return" value of an IO-operation.

A program must have the type `IO String ()`. The error parameter must have type `String`.
This allows the runtime to print error message to std err in case of a problem.

@docs IO, return, fail, none, fromResult


# Basic IO

@docs print, printLn, sleep, exit


# Transforming IO

@docs map, andMap, andThen, and, combine


# Handle Errors

@docs mapError, recover


# Tasks

@docs performTask, attemptTask


# Javascript Interop

@docs callJs


# Program

@docs makeProgram, Process, PortIn, PortOut

-}

import Dict exposing (Dict)
import Internal.ContWithResult as Cont exposing (Cont)
import Internal.Process as Proc exposing (Proc)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Process
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
return : a -> IO err a
return a =
    Proc.Return a
        |> embed


{-| -}
fail : err -> IO err a
fail err =
    Cont.fail err


{-| -}
none : IO x ()
none =
    return ()


{-| -}
fromResult : Result err ok -> IO err ok
fromResult result =
    case result of
        Ok ok ->
            return ok

        Err err ->
            fail err


{-| -}
printLn : String -> IO x ()
printLn str =
    print (str ++ "\n")


{-| -}
print : String -> IO x ()
print str =
    callJs
        "print"
        [ Encode.string str ]
        (Decode.succeed ())


{-| Sleep process execution in milliseconds.
-}
sleep : Float -> IO x ()
sleep delay =
    Process.sleep delay
        |> performTask


{-| Perform a task

    getTime : IO x Time.Posix
    getTime =
        performTask Time.now

-}
performTask : Task Never a -> IO x a
performTask task =
    Proc.PerformTask task
        |> embed


{-| Attempt a Task that can fail.

For example you can fetch data using the [elm/http](https://package.elm-lang.org/packages/elm/http/latest/Http) package.

    import Http

    fetch : IO String String
    fetch =
        Http.riskyTask
            { method = "GET"
            , headers = []
            , url = "http://example.com"
            , body = Http.emptyBody
            , resolver = Http.stringResolver stringBody
            , timeout = Just 10
            }
            |> attemptTask

    stringBody : Http.Response String -> Result String String
    stringBody response =
        case response of
            Http.GoodStatus_ metaData body ->
                Ok body

            _ ->
                Err "Problem"

-}
attemptTask : Task err ok -> IO err ok
attemptTask task =
    \next ->
        task
            |> Task.map Ok
            |> Task.onError (Task.succeed << Err)
            |> Proc.PerformTask
            |> Proc.map next
            |> Proc.Proc


{-| Call a synchronous function in Javascript land.

This works by sending out a message through a port. The Javascript implementation
will then send the return value back through another port.

```sh
callJs <fn> <args> <result decoder>
```


### Example

js/my-functions.js

```javascript
module.exports = {
    addOne: function(num) {
        // sync example
        return num + 1;
    },
    sleep: function(delay) {
        // async example
        return new Promise(resolve => {
            setTimeout(resolve, delay);
        });
    },
}
```

src/MyModule.elm

    addOne : Int -> IO x Int
    addOne n =
        IO.callJs
            "addOne"
            [ Encode.int n
            ]
            Decode.int

    sleep : Float -> IO x ()
    sleep delay =
        IO.callJs
            "sleep"
            [ Encode.float delay
            ]
            (Decode.succeed ())

Run like this:

```sh
elm.cli run --ext js/my-functions.js src/MyModule.elm
```

-}
callJs : String -> List Value -> Decoder a -> IO x a
callJs fn args decoder =
    Proc.CallJs { fn = fn, args = args } decoder
        |> embed


{-| Exit to shell with a status code
-}
exit : Int -> IO x ()
exit status =
    callJs
        "exit"
        [ Encode.int status ]
        (Decode.fail "")


{-| -}
embed : Proc.Handler a -> IO x a
embed handler =
    \next ->
        Proc.Proc (Proc.map (Ok >> next) handler)


{-| -}
andThen : (a -> IO x b) -> IO x a -> IO x b
andThen =
    Cont.andThen


{-| Instead of:

    sleep 100
        |> andThen (\_ -> printLn "Hello")

`and` allows you to do:

    sleep 100
        |> and (printLn "Hello")

-}
and : IO x b -> IO x a -> IO x b
and fn io =
    Cont.andThen (\_ -> fn) io


{-| -}
map : (a -> b) -> IO x a -> IO x b
map =
    Cont.map


{-| Applicative

    map2 : (a -> b -> c) -> IO x a -> IO x b -> IO x c
    map2 fn a b =
        IO.return fn
            |> IO.andMap a
            |> IO.andMap b

-}
andMap : IO x a -> IO x (a -> b) -> IO x b
andMap =
    Cont.andMap


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


{-| Used by `elm-cli` to wrap your program.

Create your own program by defining `program` in your module.

    program : Process -> IO String ()
    program process =
        printLn "Hello, world!"

-}
makeProgram : (Process -> IO String ()) -> Proc.PosixProgram
makeProgram makeIO =
    Proc.makeProgram
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
                                    ("\nERROR: "
                                        ++ error
                                        ++ "\n"
                                        |> Proc.panic
                                    )
                                    (Decode.fail "")
                                )
                )
        )
