module Posix.IO.Directory exposing
    ( Path, Entry, resolve, absolutePath, fileType, FileType(..)
    , stat, Stat
    , Pattern, list
    , delete, copy, rename, symlink, mkdir
    , setPermission, addPermission, removePermission
    )

{-|


# Directory Entry

@docs Path, Entry, resolve, absolutePath, fileType, FileType


# File Stat

@docs stat, Stat


# Directory Contents

@docs Pattern, list


# Directory Operations

@docs delete, copy, rename, symlink, mkdir


# Permissions

@docs setPermission, addPermission, removePermission

-}

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
type Entry
    = Entry DirEntry


{-| -}
type alias DirEntry =
    { type_ : FileType
    , absolutePath : Path
    }


{-| -}
type alias Stat =
    { type_ : FileType
    , mode : Permission
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


{-| -}
resolve : Path -> IO String Entry
resolve path =
    IO.fail ""


{-| -}
absolutePath : Entry -> Path
absolutePath f =
    ""


{-| -}
fileType : Entry -> FileType
fileType (Entry dirEnt) =
    dirEnt.type_


{-| -}
stat : Entry -> Stat
stat f =
    Debug.todo ""



-- DIRECTORY CONTENTS


{-| -}
list : Pattern -> IO String (List Entry)
list name =
    IO.return []



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
