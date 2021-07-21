module Posix.IO.Random exposing (seed, generate)

{-| This module is a workaround for the `Random` module not supporting creating Tasks.

Uses NodeJs [crypto.randomBytes()](https://nodejs.org/dist/latest-v14.x/docs/api/crypto.html#crypto_crypto_randombytes_size_callback) to generate a 32bit seed.

@docs seed, generate

-}

import Json.Decode as Decode
import Posix.IO as IO exposing (IO)
import Random exposing (Generator)


{-| Generate a seed than can be used with `Random.step` from elm/random.

    roll : IO x Int
    roll =
        IO.seed
            |> IO.map
                (Random.step (Random.int 1 6)
                    |> Tuple.first
                )

-}
seed : IO x Random.Seed
seed =
    IO.callJs "randomSeed"
        []
        (Decode.int |> Decode.map Random.initialSeed)


{-| Generate a random value using a Generator.

    roll : IO x Int
    roll =
        generate (Random.int 1 6)

-}
generate : Generator a -> IO x a
generate gen =
    IO.map (Random.step gen >> Tuple.first) seed
