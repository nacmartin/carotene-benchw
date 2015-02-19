-module(benchw).

-behaviour(websocket_client_handler).

-export([
         start_link/1,
         init/2,
         websocket_handle/3,
         websocket_info/3,
         websocket_terminate/3,
         get_random_string/0
        ]).

start_link(Room) ->
    websocket_client:start_link("ws://arizona:9090/websocket", ?MODULE, [Room]).

init([Room], _ConnState) ->
    random:seed(erlang:now()),
    Msg = jsx:encode([{joinexchange, Room}]),
    websocket_client:cast(self(), {text, Msg}),
    MsgExpected = get_random_string(),
    Msg2 = jsx:encode([{send, MsgExpected}, {exchange, Room}]),
    websocket_client:cast(self(), {text, Msg2}),
    gen_server:cast(data_collector, message_sent),
    {ok, {1, Room, MsgExpected, erlang:now()}}.

websocket_handle({pong, _}, _ConnState, State) ->
    {ok, State};
websocket_handle({text, Msg}, _ConnState, {NumMsg, Room, MsgExpected, Timestamp}) ->
    Received = jsx:decode(Msg),
    {_, MsgInternal} = lists:keyfind(<<"message">>, 1, Received),
    case MsgInternal of
        MsgExpected ->
            gen_server:cast(data_collector, {message_received, timer:now_diff(erlang:now(), Timestamp)}),
            case NumMsg of
                6000 ->
                    {close, <<>>, "done"};
                _ ->
                    timer:sleep(1000),
                    Msg2 = jsx:encode([{send, MsgExpected}, {exchange, Room}]),
                    websocket_client:cast(self(), {text, Msg2}),
                    gen_server:cast(data_collector, message_sent),
                    NumMsg2 = NumMsg + 1,
                    {ok, {NumMsg2, Room, MsgExpected, erlang:now()}}
            end;
        _ ->
            {ok, {NumMsg, Room, MsgExpected, Timestamp}}
    end.


websocket_info(start, _ConnState, State) ->
    {reply, {text, <<"erlang message received">>}, State}.

websocket_terminate(_Reason, _ConnState, _State) ->
    ok.

get_random_string() ->
    Length = 10,
    AllowedChars = "abcdefghijklmnoprstuvwxyz1234567890",
    Str = lists:foldl(fun(_, Acc) ->
                        [lists:nth(random:uniform(length(AllowedChars)),
                                   AllowedChars)]
                        ++ Acc
                end, [], lists:seq(1, Length)),
    list_to_binary(Str).
