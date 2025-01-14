%%% -------------------------------------------------------------------
%%% Author  : LiuYaohua
%%% Description :
%%%
%%% Created : 2012-7-5
%%% -------------------------------------------------------------------
-module(account_server_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/0, start_children/0]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([
	 init/1
        ]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%启动相应进程
start_children() ->
	receive 
		_ -> ok
	after 0 -> ok
	end,
	MySqlSpec = {mysql, {mysql, start_link, [?DB, ?DB_HOST, ?DB_PORT, ?DB_USER, ?DB_PASS, ?DB_NAME, fun(_, _, _, _) -> ok end, ?DB_ENCODE]},
				 permanent, 10000, worker, [mysql]},
	supervisor:start_child(?MODULE, MySqlSpec),
	
	LoginServeSpce = {login_server, {login_server, start_link, []}, permanent, 1000, worker, [login_server]},	
	supervisor:start_child(?MODULE, LoginServeSpce),
	
	GameId = {game_id, {game_id, start_link, []},permanent,1000,worker,[game_id]},
	supervisor:start_child(?MODULE, GameId),
	
	ok.



%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {
	 ok, 
	 {{one_for_one, 20, 10}, []}
	}. 

%% ====================================================================
%% Internal functions
%% ====================================================================

