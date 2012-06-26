-module(math2).
-export([f/1]).

f(0) ->
	1;
f(N) ->
	N * f(N -1).