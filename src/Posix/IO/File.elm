module Posix.IO.File exposing
    ( Filename
    , read, read_, ReadError(..)
    , write, write_, WriteError(..)
    , Option, create, append, exclusive
    , delete, copy, rename
    )

{-| File IO can fail for many reasons. If there is an IO problem you basically have two
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


## Write Options

@docs Option, create, append, exclusive


# Other operations

@docs delete, copy, rename

-}

import Posix.IO as IO exposing (IO)


{-| -}
type alias Filename =
    String


{-| -}
type Option
    = Create
    | Append
    | Exclusive


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
write : List Option -> Filename -> String -> IO String ()
write options name content =
    IO.return ()


{-| -}
write_ : List Option -> Filename -> String -> IO WriteError ()
write_ name content options =
    IO.return ()


{-| Create file if it does not exist.
-}
create : Option
create =
    Create


{-| Append data to file instead of overwriting it.
-}
append : Option
append =
    Append


{-| Exclusive write. Makes the write operation fail if the file already exists.
-}
exclusive : Option
exclusive =
    Append


{-| -}
delete : Filename -> IO String ()
delete name =
    IO.return ()


{-| -}
copy : Filename -> Filename -> IO String ()
copy src target =
    IO.return ()


{-| -}
rename : Filename -> Filename -> IO String ()
rename src target =
    IO.return ()
