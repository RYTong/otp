%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2009-2013. All Rights Reserved.
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

%%%-------------------------------------------------------------------
%%% File: ct_telnet_SUITE
%%%
%%% Description:
%%% Edit your ts.unix.config or ts.win32.config before runnings these tests
%%% Test ct_telnet_SUITE module
%%%
%%%-------------------------------------------------------------------
-module(ct_telnet_SUITE).
-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("common_test/include/ct_event.hrl").

-define(eh, ct_test_support_eh).

%%--------------------------------------------------------------------
%% TEST SERVER CALLBACK FUNCTIONS
%%--------------------------------------------------------------------

%%--------------------------------------------------------------------
%% Description: Since Common Test starts another Test Server
%% instance, the tests need to be performed on a separate node (or
%% there will be clashes with logging processes etc).
%%--------------------------------------------------------------------
init_per_suite(Config) ->
    ct_test_support:init_per_suite(Config).

end_per_suite(Config) ->
    ct_test_support:end_per_suite(Config).

init_per_testcase(TestCase, Config) ->
    ct_test_support:init_per_testcase(TestCase, Config).

end_per_testcase(TestCase, Config) ->
    ct_test_support:end_per_testcase(TestCase, Config).

suite() -> [{ct_hooks,[ts_install_cth]}].

all() ->
    [
     default
    ].

%%--------------------------------------------------------------------
%% TEST CASES
%%--------------------------------------------------------------------

%%%-----------------------------------------------------------------
%%%
default(Config) when is_list(Config) ->
    DataDir = ?config(data_dir, Config),
    Suite = filename:join(DataDir, "ct_telnet_basic_SUITE"),
    Cfg = {unix, ct:get_config(unix)},
    ok = file:write_file(filename:join(DataDir, "telnet.cfg"), io_lib:write(Cfg) ++ "."),
    CfgFile = filename:join(DataDir, "telnet.cfg"),
    {Opts,ERPid} = setup([{suite,Suite},{label,default}, {config, CfgFile}], Config),
    ok = execute(default, Opts, ERPid, Config).

%%%-----------------------------------------------------------------
%%% HELP FUNCTIONS
%%%-----------------------------------------------------------------

setup(Test, Config) ->
    Opts0 = ct_test_support:get_opts(Config),
    Level = ?config(trace_level, Config),
    EvHArgs = [{cbm,ct_test_support},{trace_level,Level}],
    Opts = Opts0 ++ [{event_handler,{?eh,EvHArgs}}|Test],
    ERPid = ct_test_support:start_event_receiver(Config),
    {Opts,ERPid}.

execute(Name, Opts, ERPid, Config) ->
    ok = ct_test_support:run(Opts, Config),
    Events = ct_test_support:get_events(ERPid, Config),

    ct_test_support:log_events(Name,
			       reformat(Events, ?eh),
			       ?config(priv_dir, Config),
			       Opts),

    TestEvents = events_to_check(Name,Config),
    ct_test_support:verify_events(TestEvents, Events, Config).

reformat(Events, EH) ->
    ct_test_support:reformat(Events, EH).

%%%-----------------------------------------------------------------
%%% TEST EVENTS
%%%-----------------------------------------------------------------
events_to_check(default,Config) ->
    {module,_} = code:load_abs(filename:join(?config(data_dir,Config),
					     ct_telnet_basic_SUITE)),
    TCs = ct_telnet_basic_SUITE:all(),
    code:purge(ct_telnet_basic_SUITE),
    code:delete(ct_telnet_basic_SUITE),

    OneTest =
	[{?eh,start_logging,{'DEF','RUNDIR'}}] ++
	[{?eh,tc_done,{ct_telnet_basic_SUITE,TC,ok}} || TC <- TCs] ++
	[{?eh,stop_logging,[]}],

    %% 2 tests (ct:run_test + script_start) is default
    OneTest ++ OneTest.
