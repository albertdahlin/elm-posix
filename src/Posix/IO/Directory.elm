module Posix.IO.Directory exposing
    ( Path, Entry, FileType(..)
    , stat, Stat
    , Pattern, list
    , copy, rename, delete, symlink, mkdir
    , setPermission, addPermission, removePermission
    )

{-| This module provides an API for working with the
file system.


# Directory Entry

@docs Path, Entry, FileType


# File Stat

@docs stat, Stat


# Directory Contents

@docs Pattern, list


# Directory Operations

@docs copy, rename, delete, symlink, mkdir


# Permissions

@docs setPermission, addPermission, removePermission

-}

import Internal.Js
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Posix.IO as IO exposing (IO)
import Posix.IO.File.Permission as Permission exposing (Permission)
import Time


{-| -}
type alias Path =
    String


{-| File name, dir, glob pattern etc.
-}
type alias Pattern =
    String


{-| -}
type alias Entry =
    { type_ : FileType
    , name : String
    , absolutePath : Path
    }


{-| -}
type alias Stat =
    { type_ : FileType
    , mode : Permission.Mask
    , owner : Int
    , group : Int
    , size : Int
    , lastAccessed : Time.Posix
    , lastModified : Time.Posix
    , lastStatusChanged : Time.Posix
    , createdAt : Time.Posix
    , absolutePath : Path
    }


{-| -}
type FileType
    = BlockDevice
    | CharacterDevice
    | Dir
    | FIFO
    | File
    | Socket
    | SymbolicLink


decodeFileType : Decoder FileType
decodeFileType =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "BlockDevice" ->
                        Decode.succeed BlockDevice

                    "CharacterDevice" ->
                        Decode.succeed CharacterDevice

                    "Dir" ->
                        Decode.succeed Dir

                    "FIFO" ->
                        Decode.succeed FIFO

                    "File" ->
                        Decode.succeed File

                    "Socket" ->
                        Decode.succeed Socket

                    "SymbolicLink" ->
                        Decode.succeed SymbolicLink

                    _ ->
                        Decode.fail "Bug"
            )


decodeEntry : Decoder Entry
decodeEntry =
    Decode.map3 Entry
        (Decode.field "fileType" decodeFileType)
        (Decode.field "name" Decode.string)
        (Decode.field "absolutePath" Decode.string)


decodeStat : Decoder Stat
decodeStat =
    let
        decodePosix =
            Decode.map (round >> Time.millisToPosix) Decode.float
    in
    Decode.field "fileType" decodeFileType
        |> Decode.andThen
            (\fileType ->
                Decode.field "mode" Decode.int
                    |> Decode.andThen
                        (\mode ->
                            Decode.field "uid" Decode.int
                                |> Decode.andThen
                                    (\uid ->
                                        Decode.field "gid" Decode.int
                                            |> Decode.andThen
                                                (\gid ->
                                                    Decode.field "atimeMs" decodePosix
                                                        |> Decode.andThen
                                                            (\atime ->
                                                                Decode.field "mtimeMs" decodePosix
                                                                    |> Decode.andThen
                                                                        (\mtime ->
                                                                            Decode.field "ctimeMs" decodePosix
                                                                                |> Decode.andThen
                                                                                    (\ctime ->
                                                                                        Decode.field "birthtimeMs" decodePosix
                                                                                            |> Decode.andThen
                                                                                                (\birthtime ->
                                                                                                    Decode.field "size" Decode.int
                                                                                                        |> Decode.andThen
                                                                                                            (\size ->
                                                                                                                Decode.field "absolutePath" Decode.string
                                                                                                                    |> Decode.map
                                                                                                                        (\absolutePath ->
                                                                                                                            { type_ = fileType
                                                                                                                            , mode = Permission.Mask mode
                                                                                                                            , owner = uid
                                                                                                                            , group = gid
                                                                                                                            , size = size
                                                                                                                            , lastAccessed = atime
                                                                                                                            , lastModified = mtime
                                                                                                                            , lastStatusChanged = ctime
                                                                                                                            , createdAt = birthtime
                                                                                                                            , absolutePath = absolutePath
                                                                                                                            }
                                                                                                                        )
                                                                                                            )
                                                                                                )
                                                                                    )
                                                                        )
                                                            )
                                                )
                                    )
                        )
            )


{-| -}
stat : Path -> IO String Stat
stat path =
    IO.callJs "stat"
        [ Encode.string path
        ]
        (Internal.Js.decodeJsResultString decodeStat)
        |> IO.andThen IO.fromResult



-- DIRECTORY CONTENTS


{-| -}
list : Pattern -> IO String (List Entry)
list path =
    IO.callJs "listDir"
        [ Encode.string path
        ]
        (Internal.Js.decodeJsResultString (Decode.list decodeEntry))
        |> IO.andThen IO.fromResult



-- DIRECTORY OPERATIONS


{-| -}
delete : List Pattern -> IO String ()
delete name =
    IO.return ()


{-| -}
copy : List Pattern -> Path -> IO String ()
copy src target =
    IO.return ()


{-| -}
rename : Pattern -> Path -> IO String ()
rename src target =
    IO.return ()


{-| -}
symlink : Path -> Path -> IO String ()
symlink src target =
    IO.return ()


{-| -}
mkdir : Path -> IO String ()
mkdir target =
    IO.return ()



-- PERMISSIONS


{-| Set the permission
-}
setPermission : Permission -> Pattern -> IO String ()
setPermission perm pat =
    IO.return ()


{-| -}
addPermission : Permission -> Pattern -> IO String ()
addPermission perm pat =
    IO.return ()


{-| -}
removePermission : Permission -> Pattern -> IO String ()
removePermission perm pat =
    IO.return ()
