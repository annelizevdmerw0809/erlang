%% 
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 2004-2009. All Rights Reserved.
%% 
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%% 
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% 
%% %CopyrightEnd%
%% 

-module(snmpm_supervisor).

-behaviour(supervisor).


%% External exports
-export([start_link/2, stop/0]).

%% supervisor callbacks
-export([init/1]).


-define(SERVER, ?MODULE).

-include("snmp_debug.hrl").


%%%-------------------------------------------------------------------
%%% API
%%%-------------------------------------------------------------------
start_link(Type, Opts) ->
    ?d("start_link -> entry with"
       "~n   Opts: ~p", [Opts]),
    SupName = {local, ?MODULE}, 
    supervisor:start_link(SupName, ?MODULE, [Type, Opts]).

stop() ->
    ?d("stop -> entry", []),
    case whereis(?SERVER) of
	Pid when pid(Pid) ->
	    ?d("stop -> Pid: ~p", [Pid]),
	    exit(Pid, shutdown),
	    ?d("stop -> stopped", []),
	    ok;
	_ ->
	    ?d("stop -> not running", []),
	    not_running
    end.


%%%-------------------------------------------------------------------
%%% Callback functions from supervisor
%%%-------------------------------------------------------------------

%%--------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}   
%%--------------------------------------------------------------------
init([Opts]) when is_list(Opts) ->    %% OTP-5963: Due to the addition
    init([normal, Opts]);             %% OTP-5963: of server_sup
init([Type, Opts]) ->
    ?d("init -> entry with"
       "~n   Type: ~p"
       "~n   Opts: ~p", [Type, Opts]),
    Restart   = get_restart(Opts), 
    Flags     = {one_for_all, 0, 3600},
    Config    = worker_spec(snmpm_config, [Opts], Restart, [gen_server]),
    MiscSup   = sup_spec(snmpm_misc_sup, [], Restart),
    ServerSup = sup_spec(snmpm_server_sup, [Type, Opts], Restart),
    Sups      = [Config, MiscSup, ServerSup],
    {ok, {Flags, Sups}}.


%%%-------------------------------------------------------------------
%%% Internal functions
%%%-------------------------------------------------------------------

get_restart(Opts) ->
    get_opt(Opts, restart_type, transient).

get_opt(Opts, Key, Def) ->
    snmp_misc:get_option(Key, Opts, Def).
	
sup_spec(Name, Args, Restart) ->
    ?d("sup_spec -> entry with"
       "~n   Name:    ~p"
       "~n   Args:    ~p"
       "~n   Restart: ~p", [Name, Args, Restart]),
    {Name, 
     {Name, start_link, Args}, 
     Restart, 2000, supervisor, [Name,supervisor]}.

worker_spec(Name, Args, Restart, Modules) ->
    ?d("worker_spec -> entry with"
       "~n   Name:    ~p"
       "~n   Args:    ~p"
       "~n   Restart: ~p"
       "~n   Modules: ~p", [Name, Args, Restart, Modules]),
    {Name, 
     {Name, start_link, Args}, 
     Restart, 2000, worker, [Name] ++ Modules}.



