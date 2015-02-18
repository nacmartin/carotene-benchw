-module(carotene_benchw_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    random:seed(erlang:now()),
    Sup = worker_sup:start_link(),
    data_collector:start_link(Sup),
    scheduler:start_link(Sup).

stop(_State) ->
    ok.
