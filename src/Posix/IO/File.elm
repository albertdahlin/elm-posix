module Posix.IO.File exposing
    ( Filename
    , read, write
    , WriteMode(..), WhenExists(..)
    , read_, write_, Error(..), OpenError(..), ReadError(..), WriteError(..), errorToString
    , openReadStream, openWriteStream
    , openReadStream_, openWriteStream_
    )

{-| This module provides a simple API for reading and writing whole
files at once as well as a streaming API.

File IO can fail for many reasons. If there is an IO problem you basically have two
options:

  - Recover by handing the error case in your code.
  - Exit the program and display an error message.

To make both these approaches ergonomic each function comes in two flavours. One fails
with a typed error, the other fails with an error message.

@docs Filename


# Read / Write File

Read or write a whole file at once.

@docs read, write


## How should a file be written?

@docs WriteMode, WhenExists


## Read / Write with typed Error

@docs read_, write_, Error, OpenError, ReadError, WriteError, errorToString


# Stream API

Open files as composable streams. Head over to the [Stream](Posix-IO-Stream) module
to learn more about Streams.


## Open a File

@docs openReadStream, openWriteStream


## Open a File with typed error

@docs openReadStream_, openWriteStream_

-}

import Bytes exposing (Bytes)
import Internal.Js
import Internal.Stream as Stream exposing (Stream)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Posix.IO as IO exposing (IO)
import Posix.IO.File.Permission as Permission exposing (Permission)


{-| -}
type alias Filename =
    String


{-| -}
type Error
    = OpenError OpenError
    | ReadError ReadError
    | WriteError WriteError
    | Other String


{-| -}
type OpenError
    = FileDoesNotExist String
    | MissingPermission String
    | IsDirectory String
    | ToManyFilesOpen String


{-| -}
type ReadError
    = CouldNotRead String


{-| -}
type WriteError
    = CouldNotCreateFile String
    | FileAlreadyExists String


{-| -}
errorToString : Error -> String
errorToString err =
    case err of
        Other msg ->
            msg

        OpenError (FileDoesNotExist msg) ->
            msg

        OpenError (MissingPermission msg) ->
            msg

        OpenError (IsDirectory msg) ->
            msg

        OpenError (ToManyFilesOpen msg) ->
            msg

        ReadError (CouldNotRead msg) ->
            msg

        WriteError (FileAlreadyExists msg) ->
            msg

        WriteError (CouldNotCreateFile msg) ->
            msg


{-| -}
read : Filename -> IO String String
read name =
    callReadFile name
        |> IO.mapError .msg


{-| -}
read_ : Filename -> IO Error String
read_ name =
    callReadFile name
        |> IO.mapError
            (handleOpenErrors
                (\error ->
                    case error.code of
                        _ ->
                            ReadError (CouldNotRead error.msg)
                )
            )


callReadFile : String -> IO Internal.Js.Error String
callReadFile name =
    Internal.Js.decodeJsResult Decode.string
        |> IO.callJs "readFile" [ Encode.string name ]
        |> IO.andThen IO.fromResult


handleOpenErrors : (Internal.Js.Error -> Error) -> Internal.Js.Error -> Error
handleOpenErrors handleRest error =
    case error.code of
        "ENOENT" ->
            FileDoesNotExist error.msg
                |> OpenError

        "EACCES" ->
            MissingPermission error.msg
                |> OpenError

        "EISDIR" ->
            IsDirectory error.msg
                |> OpenError

        "EMFILE" ->
            ToManyFilesOpen error.msg
                |> OpenError

        _ ->
            handleRest error


{-| -}
write : WriteMode -> Filename -> String -> IO String ()
write writeMode name content =
    IO.return ()


{-| -}
write_ : WriteMode -> Filename -> String -> IO Error ()
write_ writeMode content options =
    IO.return ()



-- STREAM API


{-| Open file for reading. Will fail if the file does not exist.
-}
openReadStream : Filename -> IO String (Stream Never Bytes)
openReadStream filename =
    IO.fail ""


{-| -}
openReadStream_ : Filename -> IO OpenError (Stream Never Bytes)
openReadStream_ filename =
    IO.fail (FileDoesNotExist "")


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
        openWriteStream
            (CreateIfNotExists Append Permission.readWrite)
            "my.log"

-}
openWriteStream : WriteMode -> Filename -> IO String (Stream Bytes Never)
openWriteStream writeMode filename =
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
openWriteStream_ : WriteMode -> Filename -> IO OpenError (Stream Bytes Never)
openWriteStream_ writeMode filename =
    IO.fail (FileDoesNotExist "")
