module Posix.IO.File exposing
    ( Filename
    , read, read_, ReadError(..)
    , write, write_, WriteError(..)
    , WriteMode(..), WhenExists(..)
    , File, Readable, Writable
    , openRead, openWrite, openReadWrite
    , readStream, ReadResult(..), writeStream
    )

{-| This module provides a simple API for reading and writing whole
files at once.

File IO can fail for many reasons. If there is an IO problem you basically have two
options:

  - Recover by handing the error case in your code.
  - Exit the program and display an error message.

To make both these approaches ergonomic each function comes in two flavours. One fails
with a typed error, the other fails with an error message.

@docs Filename


# Read File

@docs read, read_, ReadError


# Write File

@docs write, write_, WriteError


## How should a file be written?

@docs WriteMode, WhenExists


# Stream API

@docs File, Readable, Writable


## Open a File

@docs openRead, openWrite, openReadWrite


## Read / Write to a Stream

@docs readStream, ReadResult, writeStream

-}

import Posix.IO as IO exposing (IO)
import Posix.IO.File.Permission as Permission exposing (Permission)


{-| -}
type alias Filename =
    String


{-| -}
type Option
    = Create
    | Appenda
    | Exclusives


{-| -}
type ReadError
    = ReadFileNotFound
    | ReadNoPermission
    | ReadNotReadable


{-| -}
read : Filename -> IO String String
read name =
    IO.fail ""


{-| -}
read_ : Filename -> IO ReadError String
read_ name =
    IO.return ""


{-| -}
type WriteError
    = WriteFileNotFound
    | WriteNoPermission
    | WriteNotExclusive
    | WriteNotWritable


{-| -}
write : WriteMode -> Filename -> String -> IO String ()
write writeMode name content =
    IO.return ()


{-| -}
write_ : WriteMode -> Filename -> String -> IO WriteError ()
write_ writeMode content options =
    IO.return ()



-- STREAM API


{-| An open file descriptor.
-}
type File a
    = File


{-| Phantom type indicating that a file is readable.
-}
type Readable
    = Readable


{-| Phantom type indicating that a file is writable.
-}
type Writable
    = Writable


{-| Open file for reading. Will fail if the file does not exist.
-}
openRead : Filename -> IO String (File Readable)
openRead filename =
    IO.fail ""


{-| How to handle writes?

  - `CreateIfNotExists` - Create the file if it does not exist.
  - `FailIfExists` - Open as exclusive write.
    If the file already exists the operation will fail.
    This is useful when you want to avoid overwriting a file by accident.

-}
type WriteMode
    = CreateIfNotExists WhenExists Permission.Mask
    | FailIfExists Permission.Mask


{-| What should we do when a file exists?

  - `Truncate` - Truncates the file and places the file pointer at the beginning.
    This will cause the file to be overwritten.
  - `Append` - Place the file pointer at the end of the file.

-}
type WhenExists
    = Truncate
    | Append


{-| Open a file for writing.

    openLogFile : IO String (File Writable)
    openLogFile =
        openWrite
            (CreateIfNotExists Append Permission.readWrite)
            "my.log"

-}
openWrite : WriteMode -> Filename -> IO String (File Writable)
openWrite writeMode filename =
    case writeMode of
        CreateIfNotExists whenExists mask ->
            case whenExists of
                Truncate ->
                    --"w" mask
                    IO.fail ""

                Append ->
                    --"a" mask
                    IO.fail ""

        FailIfExists mask ->
            -- "wx"
            IO.fail ""


{-| Open a file for reading and writing.
-}
openReadWrite : WriteMode -> Filename -> IO String (File both)
openReadWrite writeMode filename =
    case writeMode of
        CreateIfNotExists whenExists mask ->
            case whenExists of
                Truncate ->
                    --"w+" mask
                    IO.fail ""

                Append ->
                    --"a+" mask
                    IO.fail ""

        FailIfExists mask ->
            -- "wx+"
            IO.fail ""


{-| The result of reading a file stream.
-}
type ReadResult
    = EndOfFile
    | ReadBytes Int String


{-| Read _length_ bytes from a file stream. Will advance
the file pointer on a successful read
-}
readStream : { length : Int } -> File Readable -> IO String ReadResult
readStream len file =
    IO.fail ""


{-| Write string to a file stream. Will advance the file pointer
on a successful write.
-}
writeStream : File Writable -> String -> IO String ()
writeStream file content =
    IO.fail ""
