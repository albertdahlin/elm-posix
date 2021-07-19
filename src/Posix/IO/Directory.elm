module Posix.IO.Directory exposing
    ( Path, Pattern
    , Node, Dir, File, pathOf
    , file, dir, Entry(..), resolve, list, files
    , delete, copy, rename, symlink
    )

{-|

@docs Path, Pattern

@docs Node, Dir, File, pathOf


# Directory Contents

@docs file, dir, Entry, resolve, list, files


# Directory Operations

@docs delete, copy, rename, symlink

-}

import Posix.IO as IO exposing (IO)


{-| -}
type alias Path =
    String


{-| File name, dir, glob pattern etc.
-}
type alias Pattern =
    String


{-| -}
type Node a
    = NNode


{-| -}
type File
    = FFile


{-| -}
type Dir
    = DDir


{-| -}
type Entry
    = File (Node File)
    | Dir (Node Dir)


{-| -}
pathOf : Node a -> Path
pathOf f =
    ""


{-| -}
file : Path -> IO String (Node File)
file name =
    IO.fail ""


{-| -}
dir : Path -> IO String (Node Dir)
dir name =
    IO.fail ""


{-| -}
resolve : Path -> IO String Entry
resolve path =
    IO.fail ""


{-| -}
list : Pattern -> IO String (List Entry)
list name =
    IO.return []


{-| -}
files : Node Dir -> IO String (List (Node File))
files d =
    IO.return []


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
