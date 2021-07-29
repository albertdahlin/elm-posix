module Internal.Js exposing (..)

import Json.Decode as Decode exposing (Decoder)


type alias Error =
    { code : String
    , msg : String
    }


decodeJsResult : Decoder ok -> Decoder (Result Error ok)
decodeJsResult =
    decodeResult
        (Decode.map2 Error
            (Decode.field "code" Decode.string)
            (Decode.field "msg" Decode.string)
        )


decodeJsResultString : Decoder ok -> Decoder (Result String ok)
decodeJsResultString =
    decodeResult (Decode.field "msg" Decode.string)


decodeResult : Decoder err -> Decoder ok -> Decoder (Result err ok)
decodeResult decodeErr decodeOk =
    Decode.field "result" Decode.string
        |> Decode.andThen
            (\result ->
                case result of
                    "Ok" ->
                        Decode.field "data" decodeOk
                            |> Decode.map Ok

                    "Err" ->
                        Decode.field "data" decodeErr
                            |> Decode.map Err

                    _ ->
                        Decode.fail "Result must be either Ok or Err"
            )
