module HttpRequest exposing (..)

{-| Fetch data using http.

-}

import Posix.IO as IO exposing (IO)
import Json.Decode as Decode
import Http


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    fetchJoke
        |> IO.andThen IO.printLn


fetchJoke : IO String String
fetchJoke =
    Http.task
        { method = "GET"
        , headers = []
        , url = "https://api.chucknorris.io/jokes/random"
        , body = Http.emptyBody
        , resolver = Http.stringResolver resolver
        , timeout = Just 10
        }
        |> IO.attemptTask


resolver : Http.Response String -> Result String String
resolver response =
    case response of
        Http.GoodStatus_ _ body ->
            Decode.decodeString
                (Decode.field "value" Decode.string)
                body
                |> Result.mapError Decode.errorToString

        _ ->
            Err "Could not fetch"
