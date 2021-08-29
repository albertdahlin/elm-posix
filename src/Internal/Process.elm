module Internal.Process exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Task exposing (Task)


type alias PosixProgram =
    PortIn Msg -> PortOut Msg -> Program Flags Model Msg


{-| -}
type alias Env =
    { argv : List String
    , pid : Int
    , env : Dict String String
    }


type alias Flags =
    { argv : List String
    , pid : Int
    , env : Value
    }


type alias ArgsToJs =
    { fn : String
    , args : List Value
    }


type alias PortIn msg =
    (Value -> msg) -> Sub msg


type alias PortOut msg =
    ArgsToJs -> Cmd msg


type Model
    = WaitingForValue ArgsToJs (Decoder Eff)
    | WaitingForTask
    | Exited


type Msg
    = GotValue Value
    | GotNext Eff


type Eff
    = CallJs ArgsToJs (Decoder Eff)
    | PerformTask (Task Never Eff)
    | Done (Result String Int)


init : PortOut Msg -> (Env -> Eff) -> Flags -> ( Model, Cmd Msg )
init portOut makeEff flags =
    let
        env =
            { argv = flags.argv
            , pid = flags.pid
            , env =
                Decode.decodeValue
                    (Decode.dict Decode.string)
                    flags.env
                    |> Result.withDefault Dict.empty
            }

        eff =
            makeEff env
    in
    next portOut eff


update : PortOut Msg -> Msg -> Model -> ( Model, Cmd Msg )
update callJs msg model =
    case ( msg, model ) of
        ( GotValue value, WaitingForValue args decoder ) ->
            case Decode.decodeValue decoder value of
                Ok eff ->
                    next callJs eff

                Err err ->
                    ( Exited
                    , "Return value from javascript function '"
                        ++ args.fn
                        ++ "' could not be decoded:\n"
                        ++ Decode.errorToString err
                        |> panic
                        |> callJs
                    )

        ( GotNext eff, WaitingForTask ) ->
            next callJs eff

        _ ->
            ( Exited
            , panic "This should never happen"
                |> callJs
            )


next : PortOut Msg -> Eff -> ( Model, Cmd Msg )
next callJs eff =
    case eff of
        CallJs args decoder ->
            ( WaitingForValue args decoder, callJs args )

        PerformTask task ->
            ( WaitingForTask
            , Task.perform GotNext task
            )

        Done result ->
            case result of
                Ok status ->
                    ( Exited
                    , { fn = "exit", args = [ Encode.int status ] }
                        |> callJs
                    )

                Err err ->
                    ( Exited
                    , { fn = "panic", args = [ Encode.string err ] }
                        |> callJs
                    )


subscriptions : PortIn Msg -> Model -> Sub Msg
subscriptions portIn model =
    portIn GotValue


makeProgram : (Env -> Eff) -> PosixProgram
makeProgram makeEff portIn portOut =
    Platform.worker
        { init = init portOut makeEff
        , update = update portOut
        , subscriptions = subscriptions portIn
        }


panic : String -> ArgsToJs
panic msg =
    { fn = "panic"
    , args =
        [ Encode.string msg
        ]
    }
