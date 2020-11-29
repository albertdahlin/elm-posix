module Posix.IO.File exposing
    ( Error(..), FD
    , Filename, open, read, write
    , stdErr, stdIn, stdOut
    )

{-|

@docs Error, FD
@docs Filename, open, read, write

# Standard IO

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
type FD
    = FD Int


{-| -}
type alias Filename =
    String


{-| -}
type Error
    = CouldNotOpen String


{-| -}
stdIn : FD
stdIn =
    FD 0


{-| -}
stdOut : FD
stdOut =
    FD 1


{-| -}
stdErr : FD
stdErr =
    FD 2


{-| -}
open : Filename -> IO (Result String FD)
open filename =
    IO.make
        (Decode.oneOf
            [ Decode.int
                |> Decode.map (FD >> Ok)
            , Decode.string
                |> Decode.map (Err)
            ]
        )
        (Effect.File <| Effect.Open filename)


{-| -}
read : FD -> IO String
read (FD fd) =
    IO.make
        Decode.string
        (Effect.File <| Effect.Read fd)


{-| -}
write : FD -> String -> IO ()
write (FD fd) content =
    IO.make
        (Decode.succeed ())
        (Effect.File <| Effect.Write fd content)
