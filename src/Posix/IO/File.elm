module Posix.IO.File exposing
    ( Filename
    , contentsOf, stat, Stats
    , readDir, Entry(..)
    , FD, Flag, open
    , flagRead, flagReadPlus, flagWrite, flagWritePlus, flagAppend, flagAppendPlus
    , read, write
    , stdErr, stdIn, stdOut
    )

{-|


# Common file IO

@docs Filename

@docs contentsOf, stat, Stats


# Directory IO

@docs readDir, Entry


# Posix Stream IO

@docs FD, Flag, open
@docs flagRead, flagReadPlus, flagWrite, flagWritePlus, flagAppend, flagAppendPlus

@docs read, write


# Standard IO streams

@docs stdErr, stdIn, stdOut

-}

import Internal.Effect as Effect exposing (Effect)
import Internal.IO as IO
import Json.Decode as Decode exposing (Decoder)


{-| -}
type alias IO a =
    IO.IO Effect a


{-| File Descriptor
-}
type FD ability
    = FD Int


{-| -}
type Flag a
    = Flag String


{-| -}
type alias Filename =
    String


{-| -}
type Error
    = CouldNotOpen String


type alias Readable a =
    { a
        | readable : ()
    }


type alias Writable a =
    { a
        | writable : ()
    }


type alias Seekable a =
    { a
        | seekable : ()
    }


{-| Standard Int
-}
stdIn : FD (Readable {})
stdIn =
    FD 0


{-| Standard Out
-}
stdOut : FD (Writable {})
stdOut =
    FD 1


{-| Standard Error
-}
stdErr : FD (Writable {})
stdErr =
    FD 2


{-| Open file for reading. (`r`)

An error occurs if the file does not exist.
The stream is positioned at the beginning of the file.

-}
flagRead : Flag (Readable (Seekable {}))
flagRead =
    Flag "r"


{-| Open file for reading and writing. (`r+`)

An exception occurs if the file does not exist.
The stream is positioned at the beginning of the file.

-}
flagReadPlus : Flag (Readable (Writable (Seekable {})))
flagReadPlus =
    Flag "r+"


{-| Open file for appending (writing at the end of a file). (`a`)

The file is created if it does not exist.
The stream is positioned at the end of the file.

-}
flagAppend : Flag (Writable {})
flagAppend =
    Flag "a"


{-| Open file for reading and appending. (`a+`)

The file is created if it does not exist.
The stream is positioned at the end of the file.

-}
flagAppendPlus : Flag (Readable (Writable {}))
flagAppendPlus =
    Flag "a+"


{-| Open file for writing. (`w`)

The file is created (if it does not exist) or truncated (if it exists).
The stream is positioned at the beginning of the file.

-}
flagWrite : Flag (Writable (Seekable {}))
flagWrite =
    Flag "w"


{-| Open file for reading and writing. (`w+`)

The file is created (if it does not exist) or truncated (if it exists).
The stream is positioned at the beginning of the file.

-}
flagWritePlus : Flag (Readable (Writable (Seekable {})))
flagWritePlus =
    Flag "w+"


{-| Open a file
-}
open : Filename -> Flag a -> IO (Result String (FD a))
open filename (Flag flag) =
    IO.make
        (Decode.oneOf
            [ Decode.int
                |> Decode.map (FD >> Ok)
            , Decode.string
                |> Decode.map Err
            ]
        )
        (Effect.File <| Effect.Open filename flag)


{-| Read a file
-}
read : FD (Readable a) -> IO String
read (FD fd) =
    IO.make
        Decode.string
        (Effect.File <| Effect.Read fd)


{-| File stats
-}
type alias Stats =
    { size : Int
    , atime : Float
    , mtime : Float
    , ctime : Float
    }


{-| Read file stats
-}
stat : Filename -> IO (Result String Stats)
stat filename =
    IO.make
        (Decode.oneOf
            [ Decode.string
                |> Decode.map Err
            , Decode.map4
                (\size atime mtime ctime ->
                    { size = size
                    , atime = atime
                    , mtime = mtime
                    , ctime = ctime
                    }
                        |> Ok
                )
                (Decode.field "size" Decode.int)
                (Decode.field "atimeMs" Decode.float)
                (Decode.field "mtimeMs" Decode.float)
                (Decode.field "ctimeMs" Decode.float)
            ]
        )
        (Effect.File <| Effect.Stat filename)


{-| Read the contents of a file.
-}
contentsOf : Filename -> IO (Result String String)
contentsOf filename =
    IO.do (open filename flagRead)
        (\result ->
            case result of
                Ok fd ->
                    IO.map Ok (read fd)

                Err e ->
                    IO.make (Decode.succeed (Err e)) Effect.NoOp
        )


{-| Directory entry
-}
type Entry
    = File String
    | Directory String
    | Other String


{-| Read the contents of a directory.
-}
readDir : String -> IO (Result String (List Entry))
readDir dir =
    IO.make
        (Decode.oneOf
            [ Decode.list
                (Decode.map3
                    (\name isDir isFile ->
                        if isDir then
                            Directory name

                        else if isFile then
                            File name

                        else
                            Other name
                    )
                    (Decode.field "name" Decode.string)
                    (Decode.field "isDir" Decode.bool)
                    (Decode.field "isFile" Decode.bool)
                )
                |> Decode.map Ok
            , Decode.string
                |> Decode.map Err
            ]
        )
        (Effect.File <| Effect.ReadDir dir)


{-| Write to a file
-}
write : FD (Writable a) -> String -> IO ()
write (FD fd) content =
    IO.make
        (Decode.succeed ())
        (Effect.File <| Effect.Write fd content)
