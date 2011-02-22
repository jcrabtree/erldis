-module(erldis_tests).

-include_lib("eunit/include/eunit.hrl").
-include("erldis.hrl").

quit_test() ->
	{ok, Client} = erldis:connect("localhost", 6379),
	?assertEqual(shutdown, erldis:quit(Client)),
	false = is_process_alive(Client).

utils_test() ->
	?assertEqual(<<"1">>, erldis_binaries:to_binary(1)),
	?assertEqual(<<"atom">>, erldis_binaries:to_binary(atom)).

basic_test() ->
	{ok, Client} = erldis:connect("localhost", 6379),
	?assertEqual(ok, erldis:flushdb(Client)),

	?assertEqual(nil, erldis:get(Client, <<"pippo">>)),
	ok = erldis:set(Client, <<"hello">>, <<"kitty!">>),
	?assert(erldis:setnx(Client, <<"foo">>, <<"bar">>)),
	?assertNot(erldis:setnx(Client, <<"foo">>, <<"bar">>)),
	
	?assert(erldis:exists(Client, <<"hello">>)),
	?assert(erldis:exists(Client, <<"foo">>)),
	?assertEqual(<<"bar">>, erldis:get(Client, <<"foo">>)),
	?assertEqual([<<"kitty!">>, <<"bar">>], erldis:mget(Client, [<<"hello">>, <<"foo">>])),
	?assertEqual([<<"foo">>], erldis:keys(Client, <<"f*">>)),
	erldis:set(Client,<<"foo1">>,<<"bar">>),
	erldis:set(Client,<<"foo2">>,<<"bar">>),
	erldis:set(Client,<<"foo3">>,<<"bar">>),
	?assertEqual([<<"foo">>,<<"foo1">>,<<"foo2">>,<<"foo3">>], lists:sort(erldis:keys(Client, <<"f*">>))),
	erldis:set(Client,<<"quux">>,<<"ohai">>),
	?assertEqual([<<"quux">>], erldis:keys(Client, <<"q*">>)),
	

	?assert(erldis:del(Client, <<"hello">>)),
	?assertEqual(5, erldis:delkeys(Client, [<<"foo">>, <<"funky">>, <<"foo1">>,<<"foo2">>,<<"foo3">>,<<"quux">>])),
	?assertNot(erldis:exists(Client, <<"hello">>)),
	?assertNot(erldis:exists(Client, <<"foo">>)),
	?assertNot(erldis:exists(Client, <<"funky">>)),
	?assertEqual([], erldis:keys(Client, <<"*">>)),

	?assertEqual(pong, erldis:ping(Client)),
	
	?assertEqual(shutdown, erldis:quit(Client)).

set_test() ->
	{ok, Client} = erldis:connect("localhost", 6379),
	?assertEqual(ok, erldis:flushdb(Client)),
	erldis:sadd(Client, <<"set">>, <<"toto">>),
	?assertEqual([<<"toto">>], erldis:smembers(Client, <<"set">>)),
	erldis:srem(Client, <<"set">>, <<"toto">>),
	?assertEqual([], erldis:smembers(Client, <<"set">>)),
	?assertEqual(shutdown, erldis:quit(Client)).

hash_test() ->
	{ok, Client} = erldis:connect(),
	?assertEqual(ok, erldis:flushdb(Client)),
	?assertEqual(true, erldis:hset(Client, <<"key">>, <<"field">>, <<"value">>)),
	?assert(erldis:hsetnx(Client, <<"keyNX">>, <<"fieldNX">>, <<"valueNX">>)),
	?assertNot(erldis:hsetnx(Client, <<"keyNX">>, <<"fieldNX">>, <<"valueNX">>)),
	?assertEqual(ok, erldis:hmset(Client, <<"key2">>, [{<<"field">>, <<"value2">>}])),
	?assertEqual(ok, erldis:hmset(Client, <<"key2">>, [{<<"fieldM">>, <<"valueM">>}, {<<"fieldK">>, <<"valueK">>}])),
	?assertEqual(<<"value">>, erldis:hget(Client, <<"key">>, <<"field">>)),
	?assertEqual(<<"value2">>, erldis:hget(Client, <<"key2">>, <<"field">>)),
	?assertEqual(<<"valueK">>, erldis:hget(Client, <<"key2">>, <<"fieldK">>)),
	?assertEqual(20, erldis:hincrby(Client, <<"increment-key">>, <<"by-20">>, 20)),
	?assertEqual(40, erldis:hincrby(Client, <<"increment-key">>, <<"by-20">>, 20)),
	?assertEqual(<<"40">>, erldis:hget(Client, <<"increment-key">>, <<"by-20">>)),
	?assertEqual(true, erldis:hdel(Client, <<"increment-key">>, <<"by-20">>)),
	?assertEqual(false, erldis:hdel(Client, <<"increment-key">>, <<"by-20">>)),
	?assertEqual(20, erldis:hincrby(Client, <<"increment-key">>, <<"by-20">>, 20)),
	?assertEqual(1, erldis:hlen(Client, <<"increment-key">>)),
	?assertEqual(1, erldis:hlen(Client, <<"key">>)),
	?assertEqual(true, erldis:hexists(Client, <<"key">>, <<"field">>)),
	?assertEqual(false, erldis:hexists(Client, <<"key">>, <<"non-field">>)),
	?assertEqual([<<"field">>], erldis:hkeys(Client, <<"key">>)),
	?assertEqual([<<"by-20">>], erldis:hkeys(Client, <<"increment-key">>)),
	?assertEqual([<<"value">>], erldis:hvals(Client, <<"key">>)),
	?assertEqual([<<"20">>], erldis:hvals(Client, <<"increment-key">>)),
	?assertEqual([{<<"field">>, <<"value">>}], erldis:hgetall(Client, <<"key">>)),
	?assertEqual([{<<"by-20">>, <<"20">>}], erldis:hgetall(Client, <<"increment-key">>)).

list_test() ->
	{ok, Client} = erldis:connect("localhost", 6379),
	?assertEqual(ok, erldis:flushdb(Client)),
	
	?assertEqual([], erldis:lrange(Client, <<"foo">>, 1, 2)),
	1 = erldis:rpush(Client, <<"a_list">>, <<"1">>),
	2 = erldis:rpush(Client, <<"a_list">>, <<"2">>),
	3 = erldis:rpush(Client, <<"a_list">>, <<"3">>),
	4 = erldis:rpush(Client, <<"a_list">>, <<"1">>),
	?assertEqual(1, erldis:lrem(Client, <<"a_list">>, 1, <<"1">>)),
	?assertEqual([<<"2">>, <<"3">>, <<"1">>], erldis:lrange(Client, <<"a_list">>, 0, 2)),
	?assertEqual([<<"1">>, <<"2">>, <<"3">>], erldis:sort(Client, <<"a_list">>)),
	?assertEqual([<<"3">>, <<"2">>, <<"1">>], erldis:sort(Client, <<"a_list">>, <<"DESC">>)),
	?assertEqual([<<"1">>, <<"2">>], erldis:sort(Client, <<"a_list">>, <<"LIMIT 0 2 ASC">>)),
	?assertEqual(<<"1">>, erldis:rpoplpush(Client, <<"a_list">>, <<"b_list">>)),
	?assertEqual(<<"1">>, erldis:lindex(Client, <<"b_list">>, 0)),
	
	?assertEqual(shutdown, erldis:quit(Client)).

zset_test() ->
	{ok, Client} = erldis:connect("localhost", 6379),
	?assertEqual(ok, erldis:flushdb(Client)),
	
	?assertEqual(0, erldis:zcard(Client, <<"foo">>)),
	?assertEqual(0, erldis:zcount(Client, <<"foo">>, 0, 2)),
	?assertEqual(0, erldis:zcount(Client, <<"foo">>, 0, 10)),
	?assertEqual([], erldis:zrange(Client, <<"foo">>, 0, 1)),
	?assertEqual(0, erldis:zscore(Client, <<"foo">>, <<"elem1">>)),
	
	?assertEqual(true, erldis:zadd(Client, <<"foo">>, 5, <<"elem1">>)),
	?assertEqual([<<"elem1">>], erldis:zrange(Client, <<"foo">>, 0, 1)),
	?assertEqual([<<"elem1">>], erldis:zrevrange(Client, <<"foo">>, 0, 1)),
	?assertEqual([{<<"elem1">>, 5}], erldis:zrange_withscores(Client, <<"foo">>, 0, 1)),
	?assertEqual([{<<"elem1">>, 5}], erldis:zrevrange_withscores(Client, <<"foo">>, 0, 1)),
	?assertEqual(false, erldis:zadd(Client, <<"foo">>, 6, <<"elem1">>)),
	?assertEqual(1, erldis:zcard(Client, <<"foo">>)),
	?assertEqual(0, erldis:zcount(Client, <<"foo">>, 0, 2)),
	?assertEqual(1, erldis:zcount(Client, <<"foo">>, 0, 10)),
	?assertEqual(6, erldis:zscore(Client, <<"foo">>, <<"elem1">>)),
	?assertEqual(8, erldis:zincrby(Client, <<"foo">>, 2, <<"elem1">>)),
	% can use list keys & values too
	?assertEqual(true, erldis:zadd(Client, "foo", 1.5, "a-elem")),
	?assertEqual(2, erldis:zcard(Client, "foo")),
	?assertEqual(1, erldis:zcount(Client, <<"foo">>, 0, 2)),
	?assertEqual(2, erldis:zcount(Client, <<"foo">>, 0, 10)),
	?assertEqual(1.5, erldis:zscore(Client, "foo", "a-elem")),
	?assertEqual([<<"a-elem">>, <<"elem1">>], erldis:zrange(Client, "foo", 0, 2)),
	?assertEqual([<<"elem1">>, <<"a-elem">>], erldis:zrevrange(Client, "foo", 0, 2)),
	?assertEqual([{<<"a-elem">>, 1.5}, {<<"elem1">>, 8}], erldis:zrange_withscores(Client, "foo", 0, 2)),
	?assertEqual([{<<"elem1">>, 8}, {<<"a-elem">>, 1.5}], erldis:zrevrange_withscores(Client, "foo", 0, 2)),
	?assertEqual([<<"a-elem">>], erldis:zrangebyscore(Client, "foo", 1.0, 2.0)),
	?assertEqual([<<"a-elem">>], erldis:zrangebyscore(Client, "foo", 1, 10, 0, 1)),
	?assertEqual([<<"a-elem">>, <<"elem1">>], erldis:zrangebyscore(Client, "foo", 1, 10, 0, 2)),
	?assertEqual([<<"elem1">>], erldis:zrangebyscore(Client, "foo", 1, 10, 1, 2)),
	?assertEqual([], erldis:zrangebyscore(Client, "foo", 1, 10, 2, 2)),
	?assertEqual([{<<"a-elem">>, 1.5}], erldis:zrangebyscore_withscores(Client, "foo", 1.0, 2.0)),
	?assertEqual([{<<"a-elem">>, 1.5}], erldis:zrangebyscore_withscores(Client, "foo", 1, 10, 0, 1)),
	?assertEqual([{<<"a-elem">>, 1.5}, {<<"elem1">>, 8}], erldis:zrangebyscore_withscores(Client, "foo", 1, 10, 0, 2)),
	?assertEqual([{<<"elem1">>, 8}], erldis:zrangebyscore_withscores(Client, "foo", 1, 10, 1, 2)),
	?assertEqual([], erldis:zrangebyscore_withscores(Client, "foo", 1, 10, 2, 2)),
	?assertEqual(1, erldis:zremrangebyscore(Client, "foo", 1, 2)),
	?assertEqual(false, erldis:zrem(Client, "foo", "a-elem")),
	?assertEqual(1, erldis:zcard(Client, "foo")),
	?assertEqual(0, erldis:zcount(Client, <<"foo">>, 0, 2)),
	?assertEqual(1, erldis:zcount(Client, <<"foo">>, 0, 10)),
	?assertEqual([<<"elem1">>], erldis:zrevrange(Client, "foo", 0, 1)),
	
	?assertEqual(true, erldis:zrem(Client, <<"foo">>, <<"elem1">>)),
	?assertEqual(false, erldis:zrem(Client, <<"foo">>, <<"elem1">>)),
	?assertEqual(0, erldis:zcard(Client, <<"foo">>)),
	?assertEqual(0, erldis:zcount(Client, <<"foo">>, 0, 2)),
	?assertEqual(0, erldis:zcount(Client, <<"foo">>, 0, 10)),
	?assertEqual([], erldis:zrange(Client, <<"foo">>, 0, 2)),
	
	?assertEqual(shutdown, erldis:quit(Client)).

% inline_tests(Client) ->
%	  [?_assertMatch(ok, erldis:set(Client, <<"hello">>, <<"kitty!">>)),
%	   ?_assertMatch(false, erldis:setnx(Client, <<"hello">>, <<"kitty!">>)),
%	   ?_assertMatch(true, erldis:exists(Client, <<"hello">>)),
%	   ?_assertMatch(true, erldis:del(Client, <<"hello">>)),
%	   ?_assertMatch(false, erldis:exists(Client, <<"hello">>)),
%
%	   ?_assertMatch(true, erldis:setnx(Client, <<"hello">>, <<"kitty!">>)),
%	   ?_assertMatch(true, erldis:exists(Client, <<"hello">>)),
%	   ?_assertMatch("kitty!">>, erldis:get(Client, <<"hello">>)),
%	   ?_assertMatch(true, erldis:del(Client, <<"hello">>)),
%
%
%	   ?_assertMatch(1, erldis:incr(Client, <<"pippo">>))
%	   ,?_assertMatch(2, erldis:incr(Client, <<"pippo">>))
%	   ,?_assertMatch(1, erldis:decr(Client, <<"pippo">>))
%	   ,?_assertMatch(0, erldis:decr(Client, <<"pippo">>))
%	   ,?_assertMatch(-1, erldis:decr(Client, <<"pippo">>))
%
%	   ,?_assertMatch(6, erldis:incrby(Client, <<"pippo">>, 7))
%	   ,?_assertMatch(2, erldis:decrby(Client, <<"pippo">>, 4))
%	   ,?_assertMatch(-2, erldis:decrby(Client, <<"pippo">>, 4))
%	   ,?_assertMatch(true, erldis:del(Client, <<"pippo">>))
%	  ].
