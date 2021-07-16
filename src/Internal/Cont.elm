module Internal.Cont exposing (..)

{-| -}


type alias Cont r a =
    (a -> r) -> r


{-| -}
return : a -> Cont r a
return a =
    \a2r -> a2r a


{-| -}
andThen : (a -> Cont r b) -> Cont r a -> Cont r b
andThen a2b2r2r a2r2r =
    \b2r ->
        a2r2r
            (\a2r ->
                a2b2r2r a2r b2r
            )


{-| -}
run : (a -> r) -> Cont r a -> r
run a2r a2r2r =
    a2r2r a2r


{-| -}
map : (a -> b) -> Cont r a -> Cont r b
map a2b a2r2r =
    \b2r -> a2r2r (b2r << a2b)
