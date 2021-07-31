module Posix.IO.File.Permission exposing
    ( Permission, readWrite, true, false
    , Mask(..), default, toMask, fromMask, fromOctal
    )

{-|


# Permission Record

@docs Permission, readWrite, true, false


# Permission bitmask

@docs Mask, default, toMask, fromMask, fromOctal

-}

import Bitwise


{-| The permission bitmask is wrapped to avoid confusion with a
normal Int
-}
type Mask
    = Mask Int


{-| -}
type alias Permission =
    { ownerRead : Bool
    , ownerWrite : Bool
    , ownerExecute : Bool
    , groupRead : Bool
    , groupWrite : Bool
    , groupExecute : Bool
    , allRead : Bool
    , allWrite : Bool
    , allExecute : Bool
    }


{-| All permission set to `False`

    perm600 =
        { false
            | ownerRead = True
            , ownerWrite = True
        }

-}
false : Permission
false =
    { ownerRead = False
    , ownerWrite = False
    , ownerExecute = False
    , groupRead = False
    , groupWrite = False
    , groupExecute = False
    , allRead = False
    , allWrite = False
    , allExecute = False
    }


{-| All permission set to `True`

    perm775 =
        { true
            | allWrite = False
        }

-}
true : Permission
true =
    { ownerRead = True
    , ownerWrite = True
    , ownerExecute = True
    , groupRead = True
    , groupWrite = True
    , groupExecute = True
    , allRead = True
    , allWrite = True
    , allExecute = True
    }


{-| Read and write for everyone. (0o666)
-}
readWrite : Permission
readWrite =
    { ownerRead = True
    , ownerWrite = True
    , ownerExecute = False
    , groupRead = True
    , groupWrite = True
    , groupExecute = False
    , allRead = True
    , allWrite = True
    , allExecute = False
    }


{-| Default mask, 0666
-}
default : Mask
default =
    Mask 438


{-| Create a bitmask from a record.
-}
toMask : Permission -> Mask
toMask perm =
    let
        setIf pred i =
            if pred then
                Bitwise.or i

            else
                identity
    in
    0
        |> setIf perm.allExecute maskAllExecute
        |> setIf perm.allWrite maskAllWrite
        |> setIf perm.allRead maskAllRead
        |> setIf perm.groupExecute maskGroupExecute
        |> setIf perm.groupWrite maskGroupWrite
        |> setIf perm.groupRead maskGroupRead
        |> setIf perm.ownerExecute maskOwnerExecute
        |> setIf perm.ownerWrite maskOwnerWrite
        |> setIf perm.ownerRead maskOwnerRead
        |> Mask


{-| Construct a bitmask from an "octal" number. This is useful since
Elm does not support octal literal notation.

    fromOctal 775

    fromOctal 664

-}
fromOctal : Int -> Mask
fromOctal i =
    let
        o =
            modBy 10 (i // 100)
                |> clamp 0 7

        g =
            modBy 10 (i // 10)
                |> clamp 0 7

        a =
            modBy 10 i |> clamp 0 7
    in
    Bitwise.shiftLeftBy 6 o
        |> Bitwise.or (Bitwise.shiftLeftBy 3 g)
        |> Bitwise.or a
        |> Mask


{-| Create a record from a bitmask.
-}
fromMask : Mask -> Permission
fromMask (Mask i) =
    let
        isset mask =
            Bitwise.and mask i > 0
    in
    Permission
        (isset maskOwnerRead)
        (isset maskOwnerWrite)
        (isset maskOwnerExecute)
        (isset maskGroupRead)
        (isset maskGroupWrite)
        (isset maskGroupExecute)
        (isset maskAllRead)
        (isset maskAllWrite)
        (isset maskAllExecute)


{-| 0000 0000 0001
-}
maskAllExecute : Int
maskAllExecute =
    1


{-| 0000 0000 0010
-}
maskAllWrite : Int
maskAllWrite =
    2


{-| 0000 0000 0100
-}
maskAllRead : Int
maskAllRead =
    4


{-| 0000 0000 1000
-}
maskGroupExecute : Int
maskGroupExecute =
    8


{-| 0000 0001 0000
-}
maskGroupWrite : Int
maskGroupWrite =
    16


{-| 0000 0010 0000
-}
maskGroupRead : Int
maskGroupRead =
    32


{-| 0000 0100 0000
-}
maskOwnerExecute : Int
maskOwnerExecute =
    64


{-| 0000 1000 0000
-}
maskOwnerWrite : Int
maskOwnerWrite =
    128


{-| 0001 0000 0000
-}
maskOwnerRead : Int
maskOwnerRead =
    256
