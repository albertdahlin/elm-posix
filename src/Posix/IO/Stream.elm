module Posix.IO.Stream exposing
    ( Stream
    , stdIn, stdOut, utf8Decode, utf8Encode, line, gunzip, gzip
    , pipeTo
    , read
    , reduce, collect, forEach
    , write
    , read_, ReadError(..), write_, WriteError(..)
    , run
    )

{-| This module provides an API for working with
strams and pipes.

@docs Stream


# Stream pipes

@docs stdIn, stdOut, utf8Decode, utf8Encode, line, gunzip, gzip


# Stream pipelines

Compose Streams into pipelines.

@docs pipeTo


# Read

@docs read


## Read until stream is exhausted

These functions are convenient when you want to read all data in
a stream and process it somehow. Conceptually you can think of it
as variations of `List.foldl` but for streams.

@docs reduce, collect, forEach


# Write

@docs write


# Read / write streams with typed errors

@docs read_, ReadError, write_, WriteError


# Run pipeline

@docs run

-}

import Bytes exposing (Bytes)
import Internal.Js
import Internal.Stream as Internal
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Posix.IO as IO exposing (IO)


{-| -}
type alias Stream input output =
    Internal.Stream input output



-- CREATE STREAM


{-| -}
stdIn : Stream Never Bytes
stdIn =
    Internal.notImplemented


{-| -}
stdOut : Stream Bytes Never
stdOut =
    Internal.notImplemented


{-| Uncompress stream using gzip
-}
gunzip : Stream Bytes Bytes
gunzip =
    Internal.notImplemented


{-| Compress stream using gzip
-}
gzip : Stream Bytes Bytes
gzip =
    Internal.notImplemented


{-| Convert bytes to utf8 string

    stdInAsString : Stream Never String
    stdInAsString =
        stdIn
            |> pipeTo utf8Decode

-}
utf8Decode : Stream Bytes String
utf8Decode =
    Internal.Stream
        [ { id = "utf8Decode"
          , args = []
          }
        ]
        Internal.encodeBytes
        Decode.string


{-| Convert an utf8 string to bytes.

    stdOutAsString : Stream String Never
    stdOutAsString =
        utf8Encode
            |> pipeTo stdOut

-}
utf8Encode : Stream String Bytes
utf8Encode =
    Internal.Stream
        [ { id = "utf8Encode"
          , args = []
          }
        ]
        Encode.string
        Internal.decodeBytes


{-| Read stream line by line, splitting on the NL char.

-}
line : Stream String String
line =
    Internal.Stream
        [ { id = "line"
          , args = []
          }
        ]
        Encode.string
        Decode.string



-- READ


{-| Stream read errors
-}
type ReadError
    = EOF String
    | CouldNotRead
        { code : String
        , message : String
        }


{-| Read one value from a stream. Will block until one value can be returned.

Each consecutive call to `read` will return the next value
(`Just value`) until the stream is exhausted (EOF) in which
case it will result in `Nothing`.

-}
read : Stream x output -> IO String (Maybe output)
read (Internal.Stream pipe _ decoder) =
    IO.callJs "readStream"
        [ Encode.list Internal.encodePipe pipe
        ]
        (Internal.Js.decodeJsResultString (Decode.nullable decoder))
        |> IO.andThen IO.fromResult


{-| Read a stream until it is exhausted (EOF) and
collect all values using an accumulator function.

    toList : Stream Never value -> IO String (List value)
    toList stream =
        collect (::) [] stream

-}
collect : (value -> acc -> acc) -> acc -> Stream Never value -> IO String acc
collect fn acc stream =
    reduce (\v -> fn v >> IO.return) acc stream


{-| Read a stream until it is exhausted (EOF) and
reduce it.
-}
reduce : (value -> acc -> IO String acc) -> acc -> Stream Never value -> IO String acc
reduce fn acc stream =
    read stream
        |> IO.andThen
            (\maybeVal ->
                case maybeVal of
                    Just val ->
                        fn val acc
                            |> IO.andThen (\acc2 -> reduce fn acc2 stream)

                    Nothing ->
                        IO.return acc
            )


{-| Read a stream until it is exhausted (EOF) and
perform output on each value.

    printStream : Stream Never String -> IO String ()
    printStream stream =
        forEach IO.printLn stream

-}
forEach : (value -> IO String ()) -> Stream Never value -> IO String ()
forEach fn stream =
    reduce (\v _ -> fn v) () stream


{-| Write data to a stream.
-}
write : input -> Stream input x -> IO String ()
write input (Internal.Stream pipes encode _) =
    IO.callJs "writeStream"
        [ Encode.list Internal.encodePipe pipes
        , encode input
        ]
        (Internal.Js.decodeJsResultString (Decode.succeed ()))
        |> IO.andThen IO.fromResult


{-| Same as `read` but with a typed error.
-}
read_ : Stream x output -> IO ReadError output
read_ (Internal.Stream pipe _ decoder) =
    IO.callJs "readStream"
        [ Encode.list Internal.encodePipe pipe
        ]
        (Internal.Js.decodeJsResult (Decode.nullable decoder))
        |> IO.andThen IO.fromResult
        |> IO.mapError
            (\err ->
                case err.code of
                    _ ->
                        CouldNotRead { code = err.code, message = err.msg }
            )
        |> IO.andThen
            (\mb ->
                case mb of
                    Just v ->
                        IO.return v

                    Nothing ->
                        IO.fail (EOF "End-of-file")
            )


{-| Stream write errors
-}
type WriteError
    = BrokenPipe String
    | CouldNotWrite { code : String, message : String }


{-| Same as `write` but with a typed error.
-}
write_ : input -> Stream input x -> IO WriteError ()
write_ input (Internal.Stream pipes encode _) =
    IO.callJs "writeStream"
        [ Encode.list Internal.encodePipe pipes
        , encode input
        ]
        (Internal.Js.decodeJsResult (Decode.succeed ()))
        |> IO.andThen IO.fromResult
        |> IO.mapError
            (\err ->
                case err.code of
                    "EPIPE" ->
                        BrokenPipe err.msg

                    _ ->
                        CouldNotWrite { code = err.code, message = err.msg }
            )


{-| Connect the output of one stream to the input of another.

    readLineByLine : Stream Never String
    readLineByLine =
        stdIn
            |> pipeTo gunzip
            |> pipeTo utf8Decode
            |> pipeTo line

-}
pipeTo : Stream a output -> Stream input a -> Stream input output
pipeTo (Internal.Stream to _ decoder) (Internal.Stream from encode _) =
    Internal.Stream (from ++ to) encode decoder


{-| Run a pipeline where the input and output are connected.

    passthrough : IO String ()
    passthrough =
        stdIn
            |> pipeTo stdOut
            |> run

-}
run : Stream Never Never -> IO String ()
run r =
    IO.fail ""
