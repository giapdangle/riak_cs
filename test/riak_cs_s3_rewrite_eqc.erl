%% ---------------------------------------------------------------------
%%
%% Copyright (c) 2007-2013 Basho Technologies, Inc.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% ---------------------------------------------------------------------

%% @doc Quickcheck test module for `riak_cs_s3_rewrite'.

-module(riak_cs_s3_rewrite_eqc).

-include("riak_cs.hrl").

-ifdef(EQC).
-include_lib("eqc/include/eqc.hrl").
-include_lib("eunit/include/eunit.hrl").

%% eqc property
-export([prop_extract_bucket_from_host/0]).

%% Helpers
-export([test/0,
         test/1]).

-define(QC_OUT(P),
        eqc:on_output(fun(Str, Args) ->
                              io:format(user, Str, Args) end, P)).
-define(TEST_ITERATIONS, 1000).

%%====================================================================
%% Eunit tests
%%====================================================================

eqc_test_() ->
    {spawn,
     [
      {timeout, 30, ?_assertEqual(true, quickcheck(numtests(?TEST_ITERATIONS, ?QC_OUT(prop_extract_bucket_from_host()))))}
     ]
    }.

%% ====================================================================
%% EQC Properties
%% ====================================================================

prop_extract_bucket_from_host() ->
    ?FORALL({Bucket, BaseHost},
            {riak_cs_gen:bucket_or_blank(), base_host()},
    ?IMPLIES(nomatch == re:run(Bucket, ":", [{capture, first}]),
            begin
                BucketStr = binary_to_list(Bucket),
                Host = compose_host(BucketStr, BaseHost),
                ExpectedBucket = expected_bucket(BucketStr, BaseHost),
                ResultBucket =
                    riak_cs_s3_rewrite:bucket_from_host(Host, BaseHost),
                equals(ExpectedBucket, ResultBucket)
            end)).

%%====================================================================
%% Helpers
%%====================================================================

test() ->
    test(500).

test(Iterations) ->
    eqc:quickcheck(eqc:numtests(Iterations, prop_extract_bucket_from_host())).

base_host() ->
    oneof(["s3.amazonaws.com", "riakcs.net", "snarf", "hah-hah", ""]).

compose_host([], BaseHost) ->
    BaseHost;
compose_host(Bucket, []) ->
    Bucket;
compose_host(Bucket, BaseHost) ->
    Bucket ++ "." ++  BaseHost.

expected_bucket([], _BaseHost) ->
    undefined;
expected_bucket(_Bucket, []) ->
    undefined;
expected_bucket(Bucket, _) ->
    Bucket.

-endif.
