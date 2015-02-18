-module(benchw).

-behaviour(websocket_client_handler).

-export([
         start_link/0,
         init/2,
         websocket_handle/3,
         websocket_info/3,
         websocket_terminate/3
        ]).

start_link() ->
    crypto:start(),
    ssl:start(),
    websocket_client:start_link("ws://localhost:8080/websocket", ?MODULE, []).

init([], _ConnState) ->
    random:seed(erlang:now()),
    Msg = jsx:encode([{joinexchange, room1}]),
    websocket_client:cast(self(), {text, Msg}),
    BinMsg = get_random_string(),
    MsgReply = jsx:encode([{send, BinMsg}, {exchange, room1}]),
    websocket_client:cast(self(), {text, MsgReply}),
    gen_server:cast(data_collector, message_sent),
    {ok, {1, BinMsg, erlang:now()}}.

websocket_handle({pong, _}, _ConnState, State) ->
    {ok, State};
websocket_handle({text, Msg}, _ConnState, {NumMsg, WaitingFor, Timestamp}) ->
    Received = jsx:decode(Msg),
    {_, MsgInternal} = lists:keyfind(<<"message">>, 1, Received),
    case MsgInternal of
        WaitingFor -> 
            gen_server:cast(data_collector, {message_received, timer:now_diff(erlang:now(), Timestamp)}),
            case NumMsg of
                6 -> 
                    {close, <<>>, "done"};
                _ -> 
                    timer:sleep(1000),
                    BinMsg = get_random_string(),
                    MsgReply = jsx:encode([{send, BinMsg}, {exchange, room1}]),
                    websocket_client:cast(self(), {text, MsgReply}),
                    gen_server:cast(data_collector, message_sent),
                    {ok, {NumMsg + 1, BinMsg, erlang:now()}}
            end;
        _ -> 
            {ok, {NumMsg, WaitingFor, Timestamp}}
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
