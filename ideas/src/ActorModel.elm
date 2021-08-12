module ActorModel exposing
    ( Address, Inbox
    , spawn
    , send, recv
    , addressOf, deferTo, defer, call, createInbox, recvOnly, recvIf, sendTo, spawnFSM
    )

{-|


# The Basic Stuff

The actor model adopts the philosophy that everything is an actor. This is similar to the everything is an object philosophy used by some object-oriented programming languages.

An actor is a computational entity that, in response to a message it receives, can concurrently:

  - send a finite number of messages to other actors;
  - create a finite number of new actors;
  - designate the behavior to be used for the next message it receives.

There is no assumed sequence to the above actions and they could be carried out in parallel.

Decoupling the sender from communications sent was a fundamental advance of the actor model enabling asynchronous communication and control structures as patterns of passing messages.

Recipients of messages are identified by address, sometimes called "mailing address". Thus an actor can only communicate with actors whose addresses it has. It can obtain those from a message it receives, or if the address is for an actor it has itself created.

The actor model is characterized by inherent concurrency of computation within and among actors, dynamic creation of actors, inclusion of actor addresses in messages, and interaction only through direct asynchronous message passing with no restriction on message arrival order.

@docs Address, Inbox


## Spawning a process (Actor)

A process is just a function that takes an `Inbox msg` as argument.
The inbox can be used to receive messages from other processes (actors).
As long as you don't send this `Inbox` to someone else, only you can read
messages.

`spawn` returns the `Address` to the same inbox so that other actors
can send messages to it.

@docs spawn


## Sending & Receiving Messages

@docs send, recv

This is everything you need to build distributed concurrent systems.
Everyghing else is just here to make things more convenient.


# Convenient Stuff

@docs addressOf, deferTo, defer, call, createInbox, recvOnly, recvIf, sendTo, spawnFSM

-}

import Dict exposing (Dict)
import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Posix.IO as IO exposing (IO)



-- ACTOR MODEL


{-| An Address of an `Inbox` that you can send messages to.
-}
type Address msg
    = Address Int


{-| An inbox where you can retrieve messages from.
-}
type Inbox msg
    = Inbox Int


{-| -}
createInbox : IO x (Inbox msg)
createInbox =
    IO.return (Inbox 1)


{-|

    main =
        spawn helloProcess
            |> IO.andThen
                (\helloAddress ->
                    IO.send SayHello helloAddress
                )

    type HelloMsg
        = SayHello

    helloProcess : Inbox HelloMsg -> IO String ()
    helloProcess inbox =
        IO.recv inbox
            |> IO.andThen
                (\msg ->
                    case msg of
                        SayHello ->
                            IO.printLn "Hello"
                )

-}
spawn : (Inbox msg -> IO err ()) -> IO err (Address msg)
spawn fn =
    IO.return (Address 1)


{-|

    type Msg
        = Say String

    myProcess : Inbox Msg -> IO String ()
    myProcess inbox =
        let
            helloAddress : Address String
            helloAddress =
                addressOf Say inbox
        in
        "Hello world"
            |> sendTo helloAddress

-}
addressOf : (val -> msg) -> Inbox msg -> Address val
addressOf fn m =
    Address 1


{-| Perform IO asynchronusly.

    type Msg
        = GotResult String

    myProcess : Inbox Msg -> IO String ()
    myProcess inbox =
        fetchFromSlowHttp
            |> deferTo (addressOf GotResult inbox)
            |> IO.andThen continueWithoutWaiting

-}
deferTo : Address msg -> IO err msg -> IO err ()
deferTo replyAddress io =
    spawn
        (\_ ->
            IO.andThen (sendTo replyAddress) io
        )
        |> IO.and IO.none


{-| -}
defer : IO err msg -> Address msg -> IO err ()
defer io replyAddress =
    deferTo replyAddress io


{-| Send a message to an Inbox identified by an address.
-}
send : msg -> Address msg -> IO String ()
send msg chan =
    IO.fail ""


{-| Might block if channel buffer is full
-}
sendTo : Address msg -> msg -> IO err ()
sendTo msg chan =
    IO.return ()


{-| Retrieve a message from an inbox. Will block
if the inbox is empty.
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


{-| Send a message to a process and wait for the reply.

    type CounterMsg
        = Increment
        | SendValueTo (Address Int)

    getCounterValue : Address CounterMsg -> IO String Int
    getCounterValue address =
        call SendValueTo address

-}
call : (Address value -> msg) -> Address msg -> IO String value
call toMsg addr =
    createInbox
        |> IO.andThen
            (\inbox ->
                addressOf identity inbox
                    |> toMsg
                    |> sendTo addr
                    |> IO.andThen (\_ -> recv inbox)
            )


type alias StateMachine state msg =
    msg -> state -> ( state, IO String () )


{-| Spawn a "The-Elm-Architecture" update function (finite state machine).

    main =
        spawnFSM counter 0

    type Msg
        = Increment
        | SendValueTo (Address Int)

    type alias Model =
        Int

    counter : Msg -> Model -> ( Model, IO String () )
    counter msg model =
        case msg of
            Increment ->
                ( model + 1
                , IO.none
                )

            SendValueTo replyAddress ->
                ( model
                , send model replyAddress
                )

-}
spawnFSM :
    (msg -> model -> ( model, IO String () ))
    -> model
    -> IO String (Address msg)
spawnFSM sm model =
    spawn (makeActor sm model)


makeActor : StateMachine state msg -> state -> Inbox msg -> IO String ()
makeActor fn state inbox =
    recv inbox
        |> IO.andThen
            (\msg ->
                let
                    ( state2, io ) =
                        fn msg state
                in
                IO.andThen (\_ -> makeActor fn state2 inbox) io
            )



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
    spawnFSM counterActor int


getCounterValue : Address CounterMsg -> IO String Int
getCounterValue addr =
    call GetValue addr


counterActor : CounterMsg -> Int -> ( Int, IO String () )
counterActor msg model =
    case msg of
        Inc ->
            ( model + 1, IO.none )

        GetValue replyAddress ->
            ( model, send model replyAddress )



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
