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
type alias IO a =
    Effect.IO a


{-| Exit Program with a status.
-}
exit : Int -> IO ()
exit status =
    IO.make
        (Decode.succeed ())
        (Effect.Exit status)


{-| -}
print : String -> IO ()
print s =
    File.write File.stdOut (s ++ "\n")


{-| -}
sleep : Float -> IO ()
sleep d =
    IO.make
        (Decode.succeed ())
        (Effect.Sleep d)


{-| -}
logErr : String -> IO ()
logErr s =
    File.write File.stdErr (s ++ "\n")
