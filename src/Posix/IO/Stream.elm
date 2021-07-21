module Posix.IO.Stream exposing
    ( Stream
    , stdIn, stdOut, string, bytes, gunzip, gzip, line
    , read, write
    , pipeTo, run
    )

{-|

@docs Stream


# Stream pipes

@docs stdIn, stdOut, string, bytes, line, gunzip, gzip


# Read / write streams

@docs read, write


# Stream pipelines

@docs pipeTo, run

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
gunzip : Stream Bytes String
gunzip =
    Internal.Stream


{-| Compress stream using gzip
-}
gzip : Stream String Bytes
gzip =
    Internal.Stream


{-| Convert to utf8 string
-}
string : Stream Bytes String
string =
    Internal.Stream


{-| Convert to bytes.
-}
bytes : Stream String Bytes
bytes =
    Internal.Stream


{-| Read stream line by line
-}
line : Stream String String
line =
    Internal.Stream



-- READ


{-| Stream read errors
-}
type ReadError
    = TODO_ReadError


{-| Read *size* bytes/length/lines from a stream.


    read10Bytes : IO String Bytes
    read10Bytes =
        stdIn
            |> read 10

    readStringOfLength10 : IO String String
    readStringOfLength10 =
        stdIn
            |> pipeTo string
            |> read 10

    read10Lines : IO String String
    read10Lines =
        stdIn
            |> pipeTo string
            |> pipeTo line
            |> read 10

-}
read : Int -> Stream x output -> IO String output
read size stream =
    IO.fail ""


{-| Write a string to a stream.
-}
write : input -> Stream input x -> IO String ()
write str stream =
    IO.fail ""


{-| Connect the output of one stream to the input of another.

    readLineByLine : Stream Never String
    readLineByLine =
        stdIn
            |> pipeTo gunzip
            |> pipeTo line

-}
pipeTo : Stream a output -> Stream input a -> Stream input output
pipeTo r w =
    Internal.Stream


test : IO String ()
test =
    stdIn
        |> pipeTo string
        |> pipeTo gzip
        |> pipeTo stdOut
        |> run


{-| Run a pipeline where the input and output is connected.

    passthrough : IO String ()
    passthrough =
        stdIn
            |> pipeTo stdOut
            |> run

-}
run : Stream Never Never -> IO String ()
run r =
    IO.fail ""
