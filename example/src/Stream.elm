module Stream exposing (..)

{-| Loop implementation
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Posix.IO as IO exposing (IO)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : IO.Process -> IO String ()
program process =
    let
        filename =
            case process.argv of
                [ _, str ] ->
                    str

                _ ->
                    "elm.json"
    in
    --Debug.toString test |> IO.printLn
    openRead filename
        |> IO.andThen
            (\src ->
                src
                    |> pipeTo utf8Decode
                    --|> pipeTo line
                    |> readUntilEof IO.print
            )



{-
   numbersFrom 1
       |> IO.andThen
           (\numbers -> tenTimes numbers)
-}


tenTimes numbers =
    read numbers
        |> IO.andThen
            (\n ->
                if n < 10 then
                    IO.printLn (String.fromInt n)
                        |> IO.andThen (\_ -> tenTimes numbers)

                else
                    IO.none
            )


test =
    stdIn
        |> pipeTo line
        |> pipeTo stdOut


type Stream i o
    = Stream (List Pipe) (i -> Encode.Value) (Decoder o)


type alias Pipe =
    { id : String
    , args : List Encode.Value
    }


encodePipe pipe =
    Encode.object
        [ ( "id", Encode.string pipe.id )
        , ( "args", Encode.list identity pipe.args )
        ]


openRead : String -> IO String (Stream Never String)
openRead name =
    IO.callJs "createStream"
        [ Encode.string "openRead"
        , Encode.string name
        ]
        (Decode.field "id" Decode.string
            |> Decode.map
                (\id ->
                    Stream
                        [ { id = id, args = [] } ]
                        (\_ -> Encode.null)
                        Decode.string
                )
        )


openWrite : String -> IO String (Stream String Never)
openWrite name =
    IO.callJs "createStream"
        [ Encode.string "openWrite"
        , Encode.string name
        ]
        (Decode.field "id" Decode.string
            |> Decode.map
                (\id ->
                    Stream
                        [ { id = id, args = [] } ]
                        Encode.string
                        (Decode.fail "")
                )
        )


stdIn : Stream Never String
stdIn =
    Stream
        [ { id = "stdIn", args = [] } ]
        (\_ -> Encode.null)
        Decode.string


stdOut : Stream String Never
stdOut =
    Stream
        [ { id = "stdOut", args = [] } ]
        Encode.string
        (Decode.fail "")


utf8Decode : Stream String String
utf8Decode =
    Stream
        [ { id = "toString", args = [] } ]
        Encode.string
        Decode.string


line : Stream String String
line =
    Stream
        [ { id = "line", args = [] } ]
        Encode.string
        Decode.string


numbersFrom : Int -> IO String (Stream Never Int)
numbersFrom n =
    IO.callJs "createStream"
        [ Encode.string "numbersFrom"
        , Encode.int n
        ]
        (Decode.field "id" Decode.string
            |> Decode.map
                (\id ->
                    Stream
                        [ { id = id, args = [] } ]
                        (\_ -> Encode.null)
                        Decode.int
                )
        )


pipeTo : Stream a output -> Stream input a -> Stream input output
pipeTo (Stream to _ decoder) (Stream from encode _) =
    Stream (from ++ to) encode decoder


type Read a
    = EOF
    | Data a

read : Stream Never o -> IO String o
read (Stream pipe _ decoder) =
    IO.callJs "readStream"
        [ Encode.list encodePipe pipe
        ]
        (Decode.maybe decoder)
        |> IO.andThen
            (\mb ->
                case mb of
                    Just v ->
                        IO.return v

                    Nothing ->
                        IO.fail "EOF"
            )


readUntilEof : (o -> IO String ()) -> Stream Never o -> IO String ()
readUntilEof fn stm =
    read stm
        |> IO.andThen fn
        |> IO.andThen (\_ -> readUntilEof fn stm)
        |> IO.recover
            (\err ->
                if err == "EOF" then IO.none else IO.fail err
            )


write : i -> Stream i Never -> IO String ()
write value (Stream pipe encode _) =
    IO.callJs "writeStream"
        [ Encode.list encodePipe pipe
        , encode value
        ]
        (Decode.succeed ())
