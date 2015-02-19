-module(data_collector).

-behaviour(gen_server).

-export([start_link/1]).
-export([stop/1]).
-export([init/1, terminate/2, code_change/3, handle_call/3,
         handle_cast/2, handle_info/2]).

-record(data, {samples, requests, responses, sup}).

-define(INTERVAL, 10000).

start_link(Sup) ->
    Opts = [],
    io:format("starting data collector~n"),
    gen_server:start_link({local, ?MODULE}, ?MODULE, [Sup], Opts).


stop(Pid) ->
    gen_server:call(Pid, stop, infinity).

init([Sup]) ->
    io:format("starting data collector~n"),
    erlang:send_after(?INTERVAL, self(), trigger),
    State = #data{samples=[], requests=0, responses=0, sup=Sup},
    {ok, State}.

handle_info(trigger, #data{samples=Samples, requests=Requests, responses=Responses, sup=Sup}) ->
    erlang:send_after(?INTERVAL, self(), trigger),
    Children = supervisor:count_children(worker_sup),
    {_, Users} = lists:keyfind(active, 1, Children),
    io:format("Requests: ~p , Responses: ~p, Users: ~p, Latency: ~p~n", [Requests, Responses, Users, average(Samples)]),
    NewState = #data{samples=[], requests=0, responses=0, sup=Sup},
    {noreply, NewState}.

handle_cast(message_sent, State=#data{requests=Requests}) ->
    {noreply, State#data{requests=Requests + 1}};

handle_cast({message_received, Time}, State=#data{samples=Samples, responses=Responses}) ->
    {noreply, State#data{samples=[Time|Samples], responses=Responses + 1}}.

handle_call(_, _From, State) ->
    {reply, ok, State}.

terminate(_Reason, _State) ->
    io:format("Terminating data collector~n"),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

average([]) ->
        0;

average(X) ->
        average(X, 0, 0).

average([H|T], Length, Sum) ->
        average(T, Length + 1, Sum + H);

average([], Length, Sum) ->
        Sum / Length.
