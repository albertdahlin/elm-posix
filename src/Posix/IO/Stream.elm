module Posix.IO.Stream exposing
    ( Stream
    , stdIn, stdOut, utf8Decode, utf8Encode, line, gunzip, gzip
    , pipeTo, run
    , read, write
    , read_, ReadError(..), write_, WriteError(..)
    )

{-| This module provides an API for working with
strams and pipes.

@docs Stream


# Stream pipes

@docs stdIn, stdOut, utf8Decode, utf8Encode, line, gunzip, gzip


# Stream pipelines

@docs pipeTo, run


# Read / write streams

@docs read, write


# Read / write streams

@docs read_, ReadError, write_, WriteError

-}

import Bytes exposing (Bytes)
import Internal.Stream as Internal
import Posix.IO as IO exposing (IO)


{-| -}
type alias Stream input output =
    Internal.Stream input output



-- CREATE STREAM


{-| -}
stdIn : Stream Never Bytes
stdIn =
    Internal.Stream


{-| -}
stdOut : Stream Bytes Never
stdOut =
    Internal.Stream


{-| Uncompress stream using gzip
-}
gunzip : Stream Bytes Bytes
gunzip =
    Internal.Stream


{-| Compress stream using gzip
-}
gzip : Stream Bytes Bytes
gzip =
    Internal.Stream


{-| Convert bytes to utf8 string

    stdInAsString : Stream Never String
    stdInAsString =
        stdIn
            |> pipeTo utf8Decode

-}
utf8Decode : Stream Bytes String
utf8Decode =
    Internal.Stream


{-| Convert an utf8 string to bytes.
-}
utf8Encode : Stream String Bytes
utf8Encode =
    Internal.Stream


{-| Read stream line by line
-}
line : Stream String (List String)
line =
    Internal.Stream



-- READ


{-| Stream read errors
-}
type ReadError
    = TODO_ReadError


{-| Read _size_ bytes/length/lines from a stream.
Depending on the type of stream, _size_ represent different things:

    read10Bytes : IO String Bytes
    read10Bytes =
        stdIn
            |> read 10

    readStringOfLength10 : IO String String
    readStringOfLength10 =
        stdIn
            |> pipeTo utf8Decode
            |> read 10

    read10Lines : IO String String
    read10Lines =
        stdIn
            |> pipeTo utf8Decode
            |> pipeTo line
            |> read 10

-}
read : Int -> Stream x output -> IO String output
read size stream =
    IO.fail ""


{-| Write data to a stream.
-}
write : input -> Stream input x -> IO String ()
write str stream =
    IO.fail ""


{-| Same as `read` but with a typed error.
-}
read_ : Int -> Stream x output -> IO ReadError output
read_ size stream =
    IO.fail TODO_ReadError


{-| Stream write errors
-}
type WriteError
    = TODO_WriteError


{-| Same as `write` but with a typed error.
-}
write_ : input -> Stream input x -> IO WriteError ()
write_ str stream =
    IO.fail TODO_WriteError


{-| Connect the output of one stream to the input of another.

    readLineByLine : Stream Never (List String)
    readLineByLine =
        stdIn
            |> pipeTo gunzip
            |> pipeTo utf8Decode
            |> pipeTo line

-}
pipeTo : Stream a output -> Stream input a -> Stream input output
pipeTo r w =
    Internal.Stream


test : Stream Never (List String)
test =
        stdIn
            |> pipeTo gunzip
            |> pipeTo utf8Decode
            |> pipeTo line


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
