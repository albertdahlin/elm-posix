module Posix.IO.File exposing
    ( Filename
    , read, write
    , WriteMode(..), WhenExists(..)
    , read_, write_, ReadError(..), WriteError(..), OpenError(..), readErrorToString, writeErrorToString, openErrorToString
    , openReadStream, defaultReadOptions, ReadOptions, openWriteStream
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

@docs read_, write_, ReadError, WriteError, OpenError, readErrorToString, writeErrorToString, openErrorToString


# Stream API

Open files as composable streams. Head over to the [Stream](Posix-IO-Stream) module
to learn more about Streams.


## Open a File

@docs openReadStream, defaultReadOptions, ReadOptions, openWriteStream


## Open a File with typed error

@docs openReadStream_, openWriteStream_

-}

import Bytes exposing (Bytes)
import Internal.Js
import Internal.Stream exposing (Stream)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Posix.IO as IO exposing (IO)
import Posix.IO.File.Permission as Permission exposing (Permission)


{-| -}
type alias Filename =
    String


{-| -}
type OpenError
    = FileDoesNotExist String
    | MissingPermission String
    | IsDirectory String
    | TooManyFilesOpen String
    | FileAlreadyExists String
    | CouldNotOpen String


{-| -}
type ReadError
    = CouldNotOpenRead OpenError
    | CouldNotRead String


{-| -}
type WriteError
    = CouldNotOpenWrite OpenError
    | CouldNotWrite String


{-| -}
openErrorToString : OpenError -> String
openErrorToString err =
    case err of
        FileDoesNotExist msg ->
            msg

        MissingPermission msg ->
            msg

        IsDirectory msg ->
            msg

        TooManyFilesOpen msg ->
            msg

        FileAlreadyExists msg ->
            msg

        CouldNotOpen msg ->
            msg


{-| -}
readErrorToString : ReadError -> String
readErrorToString err =
    case err of
        CouldNotOpenRead openErr ->
            openErrorToString openErr

        CouldNotRead msg ->
            msg


{-| -}
writeErrorToString : WriteError -> String
writeErrorToString err =
    case err of
        CouldNotOpenWrite openErr ->
            openErrorToString openErr

        CouldNotWrite msg ->
            msg


{-| -}
read : Filename -> IO String String
read name =
    callReadFile name
        |> IO.mapError .msg


{-| -}
read_ : Filename -> IO ReadError String
read_ name =
    callReadFile name
        |> IO.mapError
            (handleOpenErrors
                CouldNotOpenRead
                (\error ->
                    case error.code of
                        _ ->
                            CouldNotRead error.msg
                )
            )


callReadFile : String -> IO Internal.Js.Error String
callReadFile name =
    Internal.Js.decodeJsResult Decode.string
        |> IO.callJs "readFile" [ Encode.string name ]
        |> IO.andThen IO.fromResult


handleOpenErrors :
    (OpenError -> err)
    -> (Internal.Js.Error -> err)
    -> Internal.Js.Error
    -> err
handleOpenErrors wrapOpenErr handleRest error =
    case error.code of
        "ENOENT" ->
            FileDoesNotExist error.msg
                |> wrapOpenErr

        "EACCES" ->
            MissingPermission error.msg
                |> wrapOpenErr

        "EISDIR" ->
            IsDirectory error.msg
                |> wrapOpenErr

        "EMFILE" ->
            TooManyFilesOpen error.msg
                |> wrapOpenErr

        "EEXIST" ->
            FileAlreadyExists error.msg
                |> wrapOpenErr

        _ ->
            handleRest error


{-| -}
write : WriteMode -> Filename -> String -> IO String ()
write writeMode name content =
    callWriteFile writeMode name content
        |> IO.mapError .msg


{-| -}
write_ : WriteMode -> Filename -> String -> IO WriteError ()
write_ writeMode name content =
    callWriteFile writeMode name content
        |> IO.mapError
            (handleOpenErrors
                CouldNotOpenWrite
                (\error ->
                    case error.code of

                        _ ->
                            CouldNotWrite error.msg
                )
            )

callWriteFile writeMode name content =
    Internal.Js.decodeJsResult (Decode.succeed ())
        |> IO.callJs "writeFile"
            [ Encode.string name
            , Encode.string content
            , encodeWriteMode writeMode
            ]
        |> IO.andThen IO.fromResult


-- STREAM API


{-| Read options
-}
type alias ReadOptions =
    { bufferSize : Int
    }


{-| Default read options

Default values:

  - `bufferSize`: `16384`

-}
defaultReadOptions : ReadOptions
defaultReadOptions =
    { bufferSize = 16384
    }


{-| Open file for reading.
-}
openReadStream : ReadOptions -> Filename -> IO String (Stream Never Bytes)
openReadStream options filename =
    Internal.Js.decodeJsResultString
        (Internal.Stream.decoder
            (\_ -> Encode.null)
            Internal.Stream.decodeBytes
        )
        |> IO.callJs "openReadStream"
            [ Encode.string filename
            , Encode.int options.bufferSize
            ]
        |> IO.andThen IO.fromResult


{-| -}
openReadStream_ : ReadOptions -> Filename -> IO OpenError (Stream Never Bytes)
openReadStream_ options filename =
    Internal.Js.decodeJsResult
        (Internal.Stream.decoder
            (\_ -> Encode.null)
            Internal.Stream.decodeBytes
        )
        |> IO.callJs "openReadStream"
            [ Encode.string filename
            , Encode.int options.bufferSize
            ]
        |> IO.andThen IO.fromResult
        |> IO.mapError (handleOpenErrors identity (.msg >> CouldNotOpen))


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

    openLogFile : IO String (Stream Binary Never)
    openLogFile =
        openWriteStream
            (CreateIfNotExists Append Permission.readWrite)
            "my.log"

-}
encodeWriteMode : WriteMode -> Encode.Value
encodeWriteMode writeMode =
    let
        encodeObj mode mask =
            Encode.object
                [ ( "flag", Encode.string mode )
                , ( "mode", Encode.int mask )
                ]
    in
    case writeMode of
        CreateIfNotExists whenExists (Permission.Mask mask) ->
            case whenExists of
                Truncate ->
                    encodeObj "w" mask

                Append ->
                    encodeObj "a" mask

        FailIfExists (Permission.Mask mask) ->
            encodeObj "wx" mask


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
