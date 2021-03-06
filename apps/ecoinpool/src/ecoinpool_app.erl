
%%
%% Copyright (C) 2011  Patrick "p2k" Schneider <patrick.p2k.schneider@gmail.com>
%%
%% This file is part of ecoinpool.
%%
%% ecoinpool is free software: you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation, either version 3 of the License, or
%% (at your option) any later version.
%%
%% ecoinpool is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with ecoinpool.  If not, see <http://www.gnu.org/licenses/>.
%%

-module(ecoinpool_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    % Init hash library
    ok = ecoinpool_hash:init(),
    % Get or create an unique server ID
    ServerIdFile = filename:join(code:priv_dir(ecoinpool), "server_id.txt"),
    ServerId = case file:read_file(ServerIdFile) of
        {ok, Data} ->
            Data;
        {error, _} ->
            NewServerId = ecoinpool_util:new_random_uuid(),
            ok = file:write_file(ServerIdFile, NewServerId),
            NewServerId
    end,
    application:set_env(ecoinpool, server_id, ServerId),
    % Load configuration
    {ok, DBHost} = application:get_env(ecoinpool, db_host),
    {ok, DBPort} = application:get_env(ecoinpool, db_port),
    {ok, DBPrefix} = application:get_env(ecoinpool, db_prefix),
    {ok, DBOptions} = application:get_env(ecoinpool, db_options),
    case application:get_env(ecoinpool, blowfish_secret) of % Make sure this is not set to the default
        {ok, "Replace me!"} -> error(please_set_a_better_blowfish_secret);
        {ok, _} -> ok
    end,
    % Start service port
    {ok, ServicePort} = application:get_env(ecoinpool, service_port),
    ecoinpool_http_service:start(ServicePort),
    % log4erl
    log4erl:conf(filename:join(code:priv_dir(ecoinpool), "log4erl.conf")),
    {ok, VSN} = application:get_key(ecoinpool, vsn),
    log4erl:warn("==> Welcome to ecoinpool v~s written by p2k! <==", [VSN]),
    ecoinpool_sup:start_link(ServerId, {DBHost, DBPort, DBPrefix, DBOptions}).

stop(_State) ->
    % Stop service port
    ecoinpool_http_service:stop(),
    ok.
