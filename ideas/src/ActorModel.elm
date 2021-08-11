module ActorModel exposing (..)

import Dict exposing (Dict)
import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Posix.IO as IO exposing (IO)



-- ROOT


type Subject2
    = GotCounterValue Int


root2 : Inbox Subject2 -> IO String ()
root2 inbox =
    startCounter 1
        |> IO.andThen
            (\counter ->
                send Inc counter
                    |> IO.and (send Inc counter)
                    |> IO.and (send (GetValue <| addressOf GotCounterValue inbox) counter)
                    |> IO.and (recv inbox)
                    |> IO.andThen
                        (\msg ->
                            case msg of
                                GotCounterValue val ->
                                    IO.printLn (String.fromInt val)
                        )
            )


type Subject3
    = GotProduct3 Product


root3 : Inbox Subject3 -> IO String ()
root3 inbox =
    startCatalog
        |> IO.andThen
            (\catalogService ->
                getProductFrom catalogService "1"
                    |> IO.andThen
                        (\product ->
                            IO.printLn product.name
                        )
            )



-- COUNTER


type CounterMsg
    = Inc
    | GetValue (Address Int)


startCounter : Int -> IO String (Address CounterMsg)
startCounter int =
    spawn (counterActor int)


counterActor : Int -> Inbox CounterMsg -> IO String ()
counterActor state inbox =
    recv inbox
        |> IO.andThen
            (\msg ->
                case msg of
                    Inc ->
                        counterActor (state + 1) inbox

                    GetValue mbox ->
                        send state mbox
                            |> IO.andThen (\_ -> counterActor state inbox)
            )



-- PRODUCTS


type alias Id =
    String


type alias Product =
    { id : Id
    , name : String
    }


decodeProduct : Decoder Product
decodeProduct =
    { id = "1"
    , name = "Product"
    }
        |> Json.Decode.succeed


type CatalogMsg
    = RequestProduct Id (Address Product)
    | GotProductResult Id (Result Json.Decode.Error Product)


type Error
    = Loading
    | Error


type alias CatalogState =
    Dict Id (Result Error Product)


getProductFrom : Address CatalogMsg -> Id -> IO String Product
getProductFrom service id =
    createInbox
        |> IO.andThen
            (\inbox ->
                RequestProduct id (addressOf identity inbox)
                    |> sendTo service
                    |> IO.and (recv inbox)
            )


startCatalog : IO String (Address CatalogMsg)
startCatalog =
    spawn (catalogActor Dict.empty)


catalogActor : CatalogState -> Inbox CatalogMsg -> IO String ()
catalogActor state inbox =
    recv inbox
        |> IO.andThen
            (\msg ->
                case msg of
                    RequestProduct id reply ->
                        case Dict.get id state of
                            Just (Ok product) ->
                                send product reply
                                    |> IO.and (catalogActor state inbox)

                            Just (Err Loading) ->
                                catalogActor state inbox

                            Just (Err Error) ->
                                catalogActor state inbox

                            Nothing ->
                                getJson ("http://example.com/product/" ++ id) decodeProduct
                                    |> toResult
                                    |> deferTo (addressOf (GotProductResult id) inbox)
                                    |> IO.and (catalogActor (Dict.insert id (Err Loading) state) inbox)

                    GotProductResult id (Ok product) ->
                        catalogActor (Dict.insert id (Ok product) state) inbox

                    GotProductResult id (Err e) ->
                        catalogActor (Dict.insert id (Err Error) state) inbox
            )



-- IO


toResult : IO err ok -> IO x (Result err ok)
toResult io =
    IO.map Ok io
        |> IO.recover (Err >> IO.return)


getJson : String -> Decoder v -> IO Json.Decode.Error v
getJson url decoder =
    IO.fail (Json.Decode.Failure "Not Implemented" Json.Encode.null)



-- ACTOR MODEL


type Address msg
    = Address Int


type Inbox msg
    = Inbox Int


createInbox : IO x (Inbox msg)
createInbox =
    IO.return (Inbox 1)


spawn : (Inbox msg -> IO err ()) -> IO err (Address msg)
spawn fn =
    IO.return (Address 1)


addressOf : (val -> msg) -> Inbox msg -> Address val
addressOf fn m =
    Address 1


deferTo : Address msg -> IO err msg -> IO err ()
deferTo replyAddress io =
    spawn
        (\_ ->
            IO.andThen (sendTo replyAddress) io
        )
        |> IO.and IO.none


{-| Might block if channel buffer is full
-}
send : msg -> Address msg -> IO String ()
send msg chan =
    IO.fail ""


{-| Might block if channel buffer is full
-}
sendTo : Address msg -> msg -> IO err ()
sendTo msg chan =
    IO.return ()


{-| Blocks if channel buffer is empty
-}
recv : Inbox msg -> IO String msg
recv inbox =
    IO.fail "Not Implemented"


{-| Blocks until an accepted message can be received.
-}
recvOnly : (recv -> Maybe msg) -> Inbox recv -> IO String msg
recvOnly shouldAccept chan =
    IO.fail ""


{-| Blocks until an accepted message can be received.
-}
recvIf : (msg -> Bool) -> Inbox msg -> IO String msg
recvIf shouldAccept chan =
    recvOnly
        (\msg ->
            if shouldAccept msg then
                Just msg

            else
                Nothing
        )
        chan
