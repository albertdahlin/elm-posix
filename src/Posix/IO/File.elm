module Posix.IO.File exposing
    ( Filename
    , read, read_, ReadError(..)
    , write, write_, WriteError(..)
    , WriteMode(..), WhenExists(..)
    , File, Readable, Writable
    , stdIn, stdOut, stdErr
    , openRead, openWrite, openReadWrite
    , OpenError(..), openErrorToString, openRead_, openWrite_, openReadWrite_
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


## Standard I/O streams

@docs stdIn, stdOut, stdErr


## Open a File

@docs openRead, openWrite, openReadWrite


## Open a File with typed error

@docs OpenError, openErrorToString, openRead_, openWrite_, openReadWrite_


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


{-| -}
type OpenError
    = FileDoesNotExist
    | MissingPermission
    | FileAlreadyExists
    | CouldNotCreateFile


{-| -}
openErrorToString : Filename -> OpenError -> String
openErrorToString fn err =
    ""


{-| Standard input stream.
-}
stdIn : File Readable
stdIn =
    File


{-| Standard output stream.
-}
stdOut : File Writable
stdOut =
    File


{-| Standard error stream.
-}
stdErr : File Writable
stdErr =
    File


{-| Open file for reading. Will fail if the file does not exist.
-}
openRead : Filename -> IO String (File Readable)
openRead filename =
    IO.fail ""


{-| -}
openRead_ : Filename -> IO OpenError (File Readable)
openRead_ filename =
    IO.fail FileDoesNotExist


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


{-| -}
openWrite_ : WriteMode -> Filename -> IO OpenError (File Writable)
openWrite_ writeMode filename =
    IO.fail FileDoesNotExist


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


{-| -}
openReadWrite_ : WriteMode -> Filename -> IO OpenError (File both)
openReadWrite_ writeMode filename =
    IO.fail FileDoesNotExist


{-| The result of reading a file stream.
-}
type ReadResult
    = EndOfFile
    | ReadBytes Int String


{-| Read _length_ bytes from a file stream.

If _position_ is `Nothing`, data will be read from the current
file position, and the file position will be updated.

If position is `Just pos`, data will be read from that offset
and the file position will remain unchanged.

-}
readStream :
    { length : Int
    , position : Maybe Int
    }
    -> File Readable
    -> IO String ReadResult
readStream opts file =
    IO.fail ""


{-| Write string to a file stream. Returns the number
of bytes written.

If _position_ is `Nothing`, data will be written to the current
file position, and the file position will be advanced.

If position is `Just pos`, data will be written at that offset
and the file position will remain unchanged.

-}
writeStream :
    { position : Maybe Int }
    -> File Writable
    -> String
    -> IO String Int
writeStream opts file content =
    IO.fail ""
