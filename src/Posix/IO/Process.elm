module Posix.IO.Process exposing (exit, sleep, print, logErr)

{-|


# Process Operations

@docs exit, sleep, print, logErr

-}

import Internal.Effect as Effect exposing (Effect)
import Internal.IO as IO
import Json.Decode as Decode exposing (Decoder)
import Posix.IO.File as File


{-| -}
type alias IO e a =
    Effect.IO (Result e a)


{-| Exit Program with a status.
-}
exit : Int -> IO x ()
exit status =
    IO.make
        (Decode.succeed (Ok ()))
        (Effect.Exit status)


{-| -}
print : String -> IO String ()
print s =
    File.write File.stdOut (s ++ "\n")


{-| -}
sleep : Float -> IO x ()
sleep d =
    IO.make
        (Decode.succeed <| Ok ())
        (Effect.Sleep d)


{-| -}
logErr : String -> IO String ()
logErr s =
    File.write File.stdErr (s ++ "\n")
