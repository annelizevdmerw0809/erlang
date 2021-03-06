%% -*- erlang-indent-level: 2 -*-
%%-----------------------------------------------------------------------
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 2006-2009. All Rights Reserved.
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

%%%----------------------------------------------------------------------
%%% File    : dialyzer_options.erl
%%% Authors : Richard Carlsson <richardc@it.uu.se>
%%% Description : Provides a better way to start Dialyzer from a script.
%%%
%%% Created : 17 Oct 2004 by Richard Carlsson <richardc@it.uu.se>
%%%----------------------------------------------------------------------

-module(dialyzer_options).

-export([build/1]).

-include("dialyzer.hrl").

%%-----------------------------------------------------------------------

-spec build(dial_options()) -> #options{} | {'error', string()}.

build(Opts) ->
  DefaultWarns = [?WARN_RETURN_NO_RETURN,
		  ?WARN_NOT_CALLED,
		  ?WARN_NON_PROPER_LIST,
		  ?WARN_FUN_APP,
		  ?WARN_MATCHING,
		  ?WARN_OPAQUE,
		  ?WARN_CALLGRAPH,
		  ?WARN_FAILING_CALL,
		  ?WARN_BIN_CONSTRUCTION,
		  ?WARN_CALLGRAPH,
		  ?WARN_CONTRACT_TYPES,
		  ?WARN_CONTRACT_SYNTAX],
  DefaultWarns1 = ordsets:from_list(DefaultWarns),
  InitPlt = dialyzer_plt:get_default_plt(),
  DefaultOpts = #options{},
  DefaultOpts1 = DefaultOpts#options{legal_warnings = DefaultWarns1,
				      init_plt = InitPlt},
  try 
    NewOpts = build_options(Opts, DefaultOpts1),
    postprocess_opts(NewOpts)
  catch
    throw:{dialyzer_options_error, Msg} -> {error, Msg}
  end.

postprocess_opts(Opts = #options{}) ->
  Opts1 = check_output_plt(Opts),
  adapt_get_warnings(Opts1).

check_output_plt(Opts = #options{analysis_type = Mode, from = From,
				 output_plt = OutPLT}) ->
  case is_plt_mode(Mode) of
    true ->
      case From =:= byte_code of
	true -> Opts;
	false ->
	  Msg = "Byte code compiled with debug_info is needed to build the PLT",
	  throw({dialyzer_error, Msg})
      end;
    false ->
      case OutPLT =:= none of
	true -> Opts;
	false ->
	  Msg = io_lib:format("Output PLT cannot be specified "
			      "in analysis mode ~w", [Mode]),
	  throw({dialyzer_error, lists:flatten(Msg)})
      end
  end.

adapt_get_warnings(Opts = #options{analysis_type = Mode,
				   get_warnings = Warns}) ->
  %% Warnings are off by default in plt mode, and on by default in
  %% success typings mode. User defined warning mode overrides the
  %% default.
  case is_plt_mode(Mode) of
    true ->
      case Warns =:= maybe of
	true -> Opts#options{get_warnings = false};
	false -> Opts
      end;
    false ->
      case Warns =:= maybe of
	true -> Opts#options{get_warnings = true};
	false -> Opts
      end
  end.

-spec bad_option(string(), term()) -> no_return().

bad_option(String, Term) ->
  Msg = io_lib:format("~s: ~P", [String, Term, 25]),
  throw({dialyzer_options_error, lists:flatten(Msg)}).

build_options([{OptName, undefined}|Rest], Options) when is_atom(OptName) ->
  build_options(Rest, Options);
build_options([{OptionName, Value} = Term|Rest], Options) ->
  case OptionName of
    files ->
      assert_filenames(Term, Value),
      build_options(Rest, Options#options{files = Value});
    files_rec ->
      assert_filenames(Term, Value),
      build_options(Rest, Options#options{files_rec = Value});
    analysis_type ->
      NewOptions =
	case Value of
	  succ_typings -> Options#options{analysis_type = Value};
	  plt_add      -> Options#options{analysis_type = Value};
	  plt_build    -> Options#options{analysis_type = Value};
	  plt_check    -> Options#options{analysis_type = Value};
	  plt_remove   -> Options#options{analysis_type = Value};
	  dataflow  -> bad_option("Analysis type is no longer supported", Term);
	  old_style -> bad_option("Analysis type is no longer supported", Term);
	  Other     -> bad_option("Unknown analysis type", Other)
	end,
      assert_plt_op(Options, NewOptions),
      build_options(Rest, NewOptions);
    check_plt when is_boolean(Value) ->
      build_options(Rest, Options#options{check_plt = Value});
    defines ->
      assert_defines(Term, Value),
      OldVal = Options#options.defines,
      NewVal = ordsets:union(ordsets:from_list(Value), OldVal),
      build_options(Rest, Options#options{defines = NewVal});
    from when Value =:= byte_code; Value =:= src_code ->
      build_options(Rest, Options#options{from = Value});
    get_warnings ->
      build_options(Rest, Options#options{get_warnings = Value});
    init_plt ->
      assert_filenames([Term], [Value]),
      build_options(Rest, Options#options{init_plt = Value});
    include_dirs ->
      assert_filenames(Term, Value),
      OldVal = Options#options.include_dirs,
      NewVal = ordsets:union(ordsets:from_list(Value), OldVal),
      build_options(Rest, Options#options{include_dirs = NewVal});
    use_spec ->
      build_options(Rest, Options#options{use_contracts = Value});
    old_style ->
      bad_option("Analysis type is no longer supported", old_style);
    output_file ->
      assert_filename(Value),
      build_options(Rest, Options#options{output_file = Value});
    output_format ->
      assert_output_format(Value),
      build_options(Rest, Options#options{output_format = Value});
    output_plt ->
      assert_filename(Value),
      build_options(Rest, Options#options{output_plt = Value});
    report_mode ->
      build_options(Rest, Options#options{report_mode = Value});
    erlang_mode ->
      build_options(Rest, Options#options{erlang_mode = true});
    warnings ->
      NewWarnings = build_warnings(Value, Options#options.legal_warnings),
      build_options(Rest, Options#options{legal_warnings = NewWarnings});
    callgraph_file ->
      assert_filename(Value),
      build_options(Rest, Options#options{callgraph_file = Value});
    _ ->
      bad_option("Unknown dialyzer command line option", Term)
  end;
build_options([], Options) ->
  Options.

assert_filenames(Term, [FileName|Left]) when length(FileName) >= 0 ->
  case filelib:is_file(FileName) orelse filelib:is_dir(FileName) of
    true -> ok;
    false -> bad_option("No such file or directory", FileName)
  end,
  assert_filenames(Term, Left);
assert_filenames(_Term, []) ->
  ok;
assert_filenames(Term, [_|_]) ->
  bad_option("Malformed or non-existing filename", Term).

assert_filename(FileName) when length(FileName) >= 0 ->
  ok;
assert_filename(FileName) ->
  bad_option("Malformed or non-existing filename", FileName).

assert_defines(Term, [{Macro, _Value}|Defs]) when is_atom(Macro) ->
  assert_defines(Term, Defs);
assert_defines(_Term, []) ->
  ok;
assert_defines(Term, [_|_]) ->
  bad_option("Malformed define", Term).

assert_output_format(raw) ->
  ok;
assert_output_format(formatted) ->
  ok;
assert_output_format(Term) ->
  bad_option("Illegal value for output_format", Term).

assert_plt_op(#options{analysis_type = OldVal}, 
	      #options{analysis_type = NewVal}) ->
  case is_plt_mode(OldVal) andalso is_plt_mode(NewVal) of
    true -> bad_option("Options cannot be combined", [OldVal, NewVal]);
    false -> ok
  end.

is_plt_mode(plt_add)      -> true;
is_plt_mode(plt_build)    -> true;
is_plt_mode(plt_remove)   -> true;
is_plt_mode(plt_check)    -> true;
is_plt_mode(succ_typings) -> false.

-spec build_warnings([atom()], [dial_warning()]) -> [dial_warning()].

build_warnings([Opt|Left], Warnings) ->
  NewWarnings =
    case Opt of
      no_return ->
	ordsets:del_element(?WARN_RETURN_NO_RETURN, Warnings);
      no_unused ->
	ordsets:del_element(?WARN_NOT_CALLED, Warnings);
      no_improper_lists ->
	ordsets:del_element(?WARN_NON_PROPER_LIST, Warnings);
      no_fun_app ->
	ordsets:del_element(?WARN_FUN_APP, Warnings);
      no_match ->
	ordsets:del_element(?WARN_MATCHING, Warnings);
      no_opaque ->
	ordsets:del_element(?WARN_OPAQUE, Warnings);
      no_fail_call ->
	ordsets:del_element(?WARN_FAILING_CALL, Warnings);
      no_contracts ->
	Warnings1 = ordsets:del_element(?WARN_CONTRACT_SYNTAX, Warnings),
	ordsets:del_element(?WARN_CONTRACT_TYPES, Warnings1);
      unmatched_returns ->
	ordsets:add_element(?WARN_UNMATCHED_RETURN, Warnings);
      error_handling ->
	ordsets:add_element(?WARN_RETURN_ONLY_EXIT, Warnings);
      possible_races ->
	ordsets:add_element(?WARN_POSSIBLE_RACE, Warnings);
      specdiffs ->
	S = ordsets:from_list([?WARN_CONTRACT_SUBTYPE, 
			       ?WARN_CONTRACT_SUPERTYPE,
			       ?WARN_CONTRACT_NOT_EQUAL]),
	ordsets:union(S, Warnings);
      overspecs ->
	ordsets:add_element(?WARN_CONTRACT_SUBTYPE, Warnings);
      underspecs ->
	ordsets:add_element(?WARN_CONTRACT_SUPERTYPE, Warnings);
      OtherAtom ->
	bad_option("Unknown dialyzer warning option", OtherAtom)
    end,
  build_warnings(Left, NewWarnings);
build_warnings([], Warnings) ->
  Warnings.
