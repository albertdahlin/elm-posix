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
    | Return a


type Model
    = WaitingForTask
    | WaitingForValue ArgsToJs (Decoder Proc)


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

        Return a ->
            Return (fn a)


next : (ArgsToJs -> Cmd Msg) -> Proc -> ( Model, Cmd Msg )
next callJs (Proc handler) =
    case handler of
        CallJs arg decoder ->
            ( WaitingForValue arg decoder, callJs arg )

        PerformTask task ->
            ( WaitingForTask, Task.perform GotNext task )

        Return proc ->
            next callJs proc


update : (ArgsToJs -> Cmd Msg) -> Msg -> Model -> ( Model, Cmd Msg )
update sendToJs msg model =
    case ( msg, model ) of
        ( GotValue value, WaitingForValue arg decoder ) ->
            case Decode.decodeValue decoder value of
                Ok proc ->
                    next sendToJs proc

                Err err ->
                    let
                        errorMsg =
                            "The value returned from calling \""
                                ++ arg.fn
                                ++ "\" could not be decoded.\n"
                                ++ Decode.errorToString err
                    in
                    ( model
                    , panic errorMsg
                        |> sendToJs
                    )

        ( GotNext proc, WaitingForTask ) ->
            next sendToJs proc

        _ ->
            ( model
            , panic "Unexpected msg and model combination."
                |> sendToJs
            )


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


panic : String -> ArgsToJs
panic msg =
    { fn = "panic"
    , args =
        [ Encode.string msg
        ]
    }
