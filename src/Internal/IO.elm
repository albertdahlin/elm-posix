module Internal.IO exposing (..)

import Internal.Process as Process exposing (Process(..))
import Json.Decode as Decode exposing (Decoder)


type alias R eff =
    ( Process eff, eff )


type IO eff a
    = IO ((a -> R eff) -> R eff)


{-| -}
make : Decoder a -> eff -> IO eff a
make resultDecoder effect =
    IO
        (\next ->
            ( Process (Decode.map next resultDecoder)
            , effect
            )
        )


{-| -}
do : IO eff a -> (a -> IO eff b) -> IO eff b
do (IO fn) cont =
    IO
        (\next ->
            fn
                (\a ->
                    let
                        (IO cont2) =
                            cont a
                    in
                    cont2 next
                )
        )


map : (a -> b) -> IO eff a -> IO eff b
map fn (IO a) =
    IO (\k -> a (k << fn))
