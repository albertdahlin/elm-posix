module Internal.ContWithResult exposing (..)

import Internal.Cont as Cont


type alias Cont r err ok =
    Cont.Cont r (Result err ok)


return : a -> Cont r err a
return a =
    Cont.return (Ok a)


fail : err -> Cont r err a
fail err =
    Cont.return (Err err)


map : (a -> b) -> Cont r err a -> Cont r err b
map fn cont =
    Cont.map (Result.map fn) cont


mapError : (x -> y) -> Cont r x a -> Cont r y a
mapError fn cont =
    Cont.map (Result.mapError fn) cont


andThen : (a -> Cont r x b) -> Cont r x a -> Cont r x b
andThen fn =
    Cont.andThen
        (\resultA ->
            case resultA of
                Ok contB ->
                    fn contB

                Err err ->
                    fail err
        )


recover : (err -> Cont r x ok) -> Cont r err ok -> Cont r x ok
recover handle =
    Cont.andThen
        (\result ->
            case result of
                Ok ok ->
                    return ok

                Err err ->
                    handle err
        )


combine : List (Cont r x a) -> Cont r x (List a)
combine =
    List.foldl
        (\c st ->
            andThen (\a -> map ((::) a) st) c
        )
        (return [])
        >> map List.reverse


{-| -}
andMap : Cont r x a -> Cont r x (a -> b) -> Cont r x b
andMap c f =
    \k ->
        f
            (\g ->
                c
                    (\a ->
                        k (resultAndMap a g)
                    )
            )


resultAndMap : Result x a -> Result x (a -> b) -> Result x b
resultAndMap ra rfn =
    case ( ra, rfn ) of
        ( _, Err x ) ->
            Err x

        ( o, Ok fn ) ->
            Result.map fn o
