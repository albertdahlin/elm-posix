module Internal.Program exposing (..)

{-|

@docs PosixProgram, Env, program

-}

import Dict exposing (Dict)
import Internal.Effect as Effect exposing (Effect, IO)
import Internal.IO as IO
import Internal.Process as Process exposing (Process)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Task exposing (Task)


type alias PortIn =
    (Value -> Msg) -> Sub Msg


type alias PortOut =
    ArgsToJs -> Cmd Msg


type alias ArgsToJs =
    { fn : String
    , args : List Value
    }


type Msg
    = GotNextValue Value


type alias Model =
    Process Effect


{-| -}
type alias PosixProgram =
    PortIn -> PortOut -> Program Flags Model Msg


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


{-| -}
program : (Env -> IO ()) -> PosixProgram
program makeIo portIn portOut =
    Platform.worker
        { init = init portOut makeIo
        , update = update portOut
        , subscriptions = subscriptions portIn
        }


init : PortOut -> (Env -> IO ()) -> Flags -> ( Model, Cmd Msg )
init portOut io flags =
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

        ( process, effect ) =
            start (io env)
    in
    ( process
    , effectToCmd portOut effect
    )


start (IO.IO io) =
    io
        (\_ ->
            ( Process.Process (Decode.fail "Exit")
            , Effect.Exit 0
            )
        )


update : PortOut -> Msg -> Model -> ( Model, Cmd Msg )
update portOut msg model =
    case msg of
        GotNextValue value ->
            case Process.step value model of
                Ok ( nextProcess, effect ) ->
                    ( nextProcess
                    , effectToCmd portOut effect
                    )

                Err err ->
                    ( model
                    , effectToCmd portOut (Effect.Exit 255)
                    )


effectToCmd : PortOut -> Effect -> Cmd Msg
effectToCmd portOut effect =
    case effect of
        Effect.Exit status ->
            portOut { fn = "exit", args = [ Encode.int status ] }

        Effect.File file ->
            case file of
                Effect.Read fd ->
                    portOut { fn = "fread", args = [ Encode.int fd ] }

                Effect.Write fd content ->
                    portOut
                        { fn = "fwrite"
                        , args =
                            [ Encode.int fd
                            , Encode.string content
                            ]
                        }

                Effect.Open filename ->
                    portOut { fn = "fopen", args = [ Encode.string filename ] }

        Effect.NoOp ->
            callSelf (GotNextValue Encode.null)


callSelf : Msg -> Cmd Msg
callSelf msg =
    Task.succeed msg
        |> Task.perform identity


subscriptions : PortIn -> Model -> Sub Msg
subscriptions portIn model =
    portIn GotNextValue
