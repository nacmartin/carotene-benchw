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
    websocket_client:start_link("ws://localhost:8080/websocket", ?MODULE, []).

init([], _ConnState) ->
    random:seed(erlang:now()),
    Rdstr = get_random_string(),
    Msg = jsx:encode([{joinexchange, Rdstr}]),
    websocket_client:cast(self(), {text, Msg}),
    Msg2 = jsx:encode([{send, hola}, {exchange, Rdstr}]),
    websocket_client:cast(self(), {text, Msg2}),
    gen_server:cast(data_collector, message_sent),
    {ok, {1, Msg2, erlang:now()}}.

websocket_handle({pong, _}, _ConnState, State) ->
    {ok, State};
websocket_handle({text, Msg}, _ConnState, {NumMsg, Room, Timestamp}) ->
    gen_server:cast(data_collector, {message_received, timer:now_diff(erlang:now(), Timestamp)}),
    case NumMsg of
        6000 ->
            {close, <<>>, "done"};
        _ ->
            timer:sleep(10),
            websocket_client:cast(self(), {text, Room}),
            gen_server:cast(data_collector, message_sent),
            NumMsg2 = NumMsg + 1,
            {ok, {NumMsg2, Room, erlang:now()}}
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
