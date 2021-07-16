module Internal.Process exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Task exposing (Task)


type Proc
    = Proc (Handler Proc)


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


type Handler a
    = CallJs ArgsToJs (Decoder a)
    | PerformTask (Task Never a)


type Model
    = WaitingForTask
    | WaitingForValue (Decoder Proc)


type Msg
    = GotValue Value
    | GotNext Proc


map : (a -> b) -> Handler a -> Handler b
map fn handler =
    case handler of
        CallJs arg decoder ->
            Decode.map fn decoder
                |> CallJs arg

        PerformTask task ->
            Task.map fn task
                |> PerformTask


next : (ArgsToJs -> Cmd Msg) -> Proc -> ( Model, Cmd Msg )
next callJs (Proc handler) =
    case handler of
        CallJs arg decoder ->
            ( WaitingForValue decoder, callJs arg )

        PerformTask task ->
            ( WaitingForTask, Task.perform GotNext task )


update : (ArgsToJs -> Cmd Msg) -> Msg -> Model -> ( Model, Cmd Msg )
update sendToJs msg model =
    case ( msg, model ) of
        ( GotValue value, WaitingForValue decoder ) ->
            case Decode.decodeValue decoder value of
                Ok proc ->
                    next sendToJs proc

                Err err ->
                    ( model, Cmd.none )

        ( GotNext proc, WaitingForTask ) ->
            next sendToJs proc

        _ ->
            ( model, Cmd.none )


init : PortOut Msg -> (Env -> Proc) -> Flags -> ( Model, Cmd Msg )
init portOut makeProcess flags =
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

        process =
            makeProcess env
    in
    next portOut process


subscriptions : PortIn Msg -> Model -> Sub Msg
subscriptions portIn model =
    portIn GotValue


makeProgram : (Env -> Proc) -> PosixProgram
makeProgram makeIo portIn portOut =
    Platform.worker
        { init = init portOut makeIo
        , update = update portOut
        , subscriptions = subscriptions portIn
        }
