module Internal.Cont exposing (..)

{-| -}


type alias Cont r a =
    (a -> r) -> r


{-| -}
return : a -> Cont r a
return a =
    \a_r -> a_r a


{-| -}
andThen : (a -> Cont r b) -> Cont r a -> Cont r b
andThen a_br_r ar_r =
    \b_r ->
        ar_r
            (\a_r ->
                a_br_r a_r b_r
            )


{-| -}
run : (a -> r) -> Cont r a -> r
run f c =
    c f


{-| -}
map : (a -> b) -> Cont r a -> Cont r b
map f c =
    \k -> c (k << f)


{-| -}
andMap : Cont r a -> Cont r (a -> b) -> Cont r b
andMap c f =
    \k -> f (\g -> c (\a -> k (g a)))


combine : List (Cont r a) -> Cont r (List a)
combine =
    List.foldl
        (\c st ->
            andThen (\a -> map ((::) a) st) c
        )
        (return [])
        >> map List.reverse

