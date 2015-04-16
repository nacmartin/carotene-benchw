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

-define(CONNTIMEOUT, 20000).
-define(MSGTIMEOUT, 10000).


start_link(Room) ->
    websocket_client:start_link("ws://52.10.7.46:8081/stream", ?MODULE, [Room]).

init([Room], _ConnState) ->
    Msg = jsx:encode([{subscribe, Room}]),
    websocket_client:cast(self(), {text, Msg}),
    erlang:start_timer(?CONNTIMEOUT, self(), trigger),
    {ok, {1, Room, undefined, erlang:now()}}.
%init([Room], _ConnState) ->
%    random:seed(erlang:now()),
%    Msg = jsx:encode([{subscribe, Room}]),
%    websocket_client:cast(self(), {text, Msg}),
%    MsgExpected = get_random_string(),
%    erlang:start_timer(?CONNTIMEOUT, self(), trigger),
%    Msg2 = jsx:encode([{publish, MsgExpected}, {channel, Room}]),
%    websocket_client:cast(self(), {text, Msg2}),
%    gen_server:cast(data_collector, message_sent),
%    {ok, {1, Room, MsgExpected, erlang:now()}}.

websocket_handle({pong, _}, _ConnState, State) ->
    {ok, State};
websocket_handle({text, <<"pong">>}, _ConnState, State) ->
    {ok, State};
websocket_handle({text, _Msg}, _ConnState, {NumMsg, Room, MsgExpected, Timestamp}) ->
            {ok, {NumMsg, Room, MsgExpected, Timestamp}}.
    %Received = jsx:decode(Msg),
    %{_, MsgInternal} = lists:keyfind(<<"message">>, 1, Received),
    %case MsgInternal of
    %    MsgExpected ->
    %        gen_server:cast(data_collector, {message_received, timer:now_diff(erlang:now(), Timestamp)}),
    %        NumMsg2 = NumMsg + 1,
    %        erlang:start_timer(?MSGTIMEOUT, self(), sendmsg),
%{ok, {NumMsg2, Room, undefined, undefined}};
    %    _ ->
    %        {ok, {NumMsg, Room, MsgExpected, Timestamp}}
    %end.

websocket_info({timeout, _, sendmsg}, _CS, {NumMsg, Room, _MsgExpected, _Timestamp}) ->
    
    MsgExpected = get_random_string(),
    Msg2 = jsx:encode([{publish, MsgExpected}, {channel, Room}]),
    websocket_client:cast(self(), {text, Msg2}),
    gen_server:cast(data_collector, message_sent),
    {ok, {NumMsg, Room, MsgExpected, erlang:now()}};
websocket_info({timeout, _, _}, _CS, State) ->
    erlang:start_timer(?CONNTIMEOUT, self(), trigger),
    {reply, {text, <<"ping">>}, State};

websocket_info(start, _ConnState, State) ->
    {reply, {text, <<"erlang message received">>}, State}.

websocket_terminate(Reason, _ConnState, _State) ->
    io:format("terminating: ~p~n", [Reason]),
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
