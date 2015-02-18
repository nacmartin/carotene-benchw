-module(scheduler).

-behaviour(gen_server).

-export([start_link/1]).
-export([stop/1]).
-export([init/1, terminate/2, code_change/3, handle_call/3,
         handle_cast/2, handle_info/2]).

-define(INTERVAL, 1000).

start_link(Sup) ->
    Opts = [],
    io:format("starting scheduler~n"),
    gen_server:start_link({local, ?MODULE}, ?MODULE, [Sup], Opts).


stop(Pid) ->
    gen_server:call(Pid, stop, infinity).

init([Sup]) ->
    erlang:send_after(?INTERVAL, self(), trigger),
    {ok, {Sup, 0}}.

handle_info(trigger, {Sup, Phase}) ->
    lists:foldl(fun(_E, I) -> supervisor:start_child(worker_sup, []),
%                              timer:sleep(5),
                              I+1 end, 0, lists:seq(1, 1000)),
    erlang:send_after(?INTERVAL, self(), trigger),
    {noreply, {Sup, Phase}}.

handle_cast(_, State) ->
    {noreply, State}.

handle_call(_, _From, State) ->
    {reply, ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
