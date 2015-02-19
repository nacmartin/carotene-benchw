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
    {ok, {Sup, roomof10}}.

handle_info(trigger, {Sup, Phase}) ->
    case Phase of
        allsameroom -> 
            Room = benchw:get_random_string(),
            lists:foldl(fun(_E, I) -> supervisor:start_child(worker_sup, [Room]),
                        I+1 end, 0, lists:seq(1, 10000)),
            erlang:send_after(?INTERVAL, self(), trigger);
        everyinitsroom -> 
            lists:foldl(fun(_E, I) ->
                        Room2 = benchw:get_random_string(),
                        supervisor:start_child(worker_sup, [Room2]),
                        I+1 end, 0, lists:seq(1, 10000)),
            erlang:send_after(?INTERVAL, self(), trigger);
        roomof10 -> 
            lists:foldl(fun(_E, I) ->
                        lists:foldl(fun(_E2, I2) ->
                                    Room3 = benchw:get_random_string(),
                                    supervisor:start_child(worker_sup, [Room3]),
                                    I2+1 end, 0, lists:seq(1, 10)),
                        I+1 end, 0, lists:seq(1, 1000)),
            erlang:send_after(?INTERVAL, self(), trigger)
    end,

    {noreply, {Sup, Phase}}.

handle_cast(_, State) ->
    {noreply, State}.

handle_call(_, _From, State) ->
    {reply, ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
