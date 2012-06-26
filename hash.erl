-module(hash).
-compile(export_all).

factorial(N) when N > 0 -> 
	N * factorial(N-1);
factorial(0) -> 
	1.
	
ascii(C, N) when N > 0 ->
    io:format("~c",[C]),
	ascii(C+1,N-1);
ascii(_,$_) -> io:format("~n",[]).

ascii(C) ->
	T = io:format("~w",[C]),
	I = list_to_integer(T),
	K = I+1,
	integer_to_list(K).
	
numbers(N) when N >= 48, N < 57 ->
	{N + 1, next};
numbers(_) ->
	{48, reset}.
	
increment([]) ->
	{L,_} = numbers([]),
	[L];
increment([H|T]) ->
	{N,Action} = numbers(H),
	if
		Action == next ->
			[N|T];
		Action == reset ->
			[N|increment(T)]
	end.

numbers_list([]) ->
	numbers_list(increment([]));
numbers_list([H|T]) ->
	{N,Action} = numbers(H),
	if
		Action == next ->
			numbers_list([N,H|T]);
		Action == reset ->
			[H|T]
	end.
	
% generate a list of charset numbers large enough to accomodate N elements
gen_numbers(L,N) ->
	C = length(L),
	% io:format("~s~w~w~n",[L,C,N]),
	if 
		C >= N ->
			L;
		true ->
			gen_numbers(append_numbers(L),N)
	end.

% deepen the list to hte next level
append_numbers([]) ->
	[ [X] || X <- numbers_list([])];
append_numbers(List) ->
	[ lists:flatten([X],[Y]) || X <- List, Y <- numbers_list([])].

% splits the workload evenly across N parts
split_work(N) ->
	List = gen_numbers([],N),
	C = length(List) div N,
	R = length(List) rem N,
	% io:format("~s ~w ~w ~w~n",[List,N,C,R]),
	split_work(List,N,C,R,[]).

split_work(List,N,C,R,Result) ->
	L = length(Result),
	% io:format("~w ~w~n",[L,Result]),
	if
		% list is more than 2 items short and there is still a remainder to be used
		L < (N - 1), R > 0 ->
			{Head, Tail} = lists:split(C+1,List),
			Res = lists:append([Head],Result),
			% io:format("~w ~w ~w~n",[Head,Tail,Res]),
			split_work(Tail,N,C,R-1,Res);
		% list is more than 2 items short, and tehre is no more remainder left
		L < (N - 1) ->
			{Head, Tail} = lists:split(C,List),
			Res = lists:append([Head],Result),
			% io:format("~w ~w ~w~n",[Head,Tail,Res]),
			split_work(Tail,N,C,R,Res);
		% list is exactly one item short
		L == (N - 1) ->
			[List|Result];
		% list is the correct length
		L == N ->
			Result
	end.
	
			
% work(D,B) ->
	% map(hash:loop([],D,B,hexstr_to_bin("d3eb9a9233e52948740d7eb8c3062d14")])).

double([],D) ->
	[D];
double(List,_) ->
	lists:append(List,List).
		
wait(N) ->
	receive
		done ->
			if
				N > 0 ->
					wait(N-1);
				true ->	
					true
			end
	after 60000 ->
		true
	end.
	
master(Passes) -> 
	master([],Passes).
	
master(N,Passes) ->
	{_,D} = bench(),
	List = double(N,D),
	C = length(List),
	Primer = split_work(N),
	Fun = fun(Depth) -> spawn(hash,slave,[self(),Depth,Primer,Passes]) end,
	lists:map(Fun,List),
	wait(C).

% slave(MasterId,Depth,Primer,Passes) ->
	% true.
			
	
% calculates the speed of the system based on the the time it took and the range it tested
speed(Seconds,Base,Depth) ->
	erlang:round(math:pow(Base,Depth) / Seconds).
	
% benches the system
bench() ->
	bench(4).

% will bench this system until a reliable speed is found
bench(D) ->
	{Reliability,Speed,_} = bench_loop(D),
	% io:format("~w ~w~n",[Reliability,Speed]),
	if
		Reliability == reliable ->
			{Speed,D};
		true ->
			bench(D+1)
	end.
	
% checks the time it took to run this round of work
bench_loop(D) ->
	{Microseconds, Value} = timer:tc(hash, loop, [[],D,[],[]]),
	Seconds = Microseconds / 1000000,
	if
		Seconds /= 0 ->
			Speed = speed(Seconds,10,D),
			if 
				Seconds > 1 ->
					{reliable, Speed, Value};
				true ->
					{unreliable, Speed, Value}
			end;
		true ->
			{infinity,0,Value}
	end.

% Calls loop on each element of primer
% work(D,Primer,C) ->
	% {Status,Result} = loop([],hd(Primer),C),
	% if
		% Status == found ->
			% send the result to the main process
		% true ->
			% true
	% end.

% Does the actual work, with a base
loop(L,D,B,C) ->
	R = increment(L),
	H = crypto:md5(lists:append(R,B)),
	% io:format("~w~n",[lists:append(R,B)]),
	if
		H == C ->
			{found,lists:append(R,B)};
		length(R) > D ->
			{not_found,C};
		true ->
			loop(R,D,B,C)
	end.

% Does the actual work, with no base
loop(L,D,C) ->
	R = increment(L),
	H = crypto:md5(R),
	% io:format("~w~n",[lists:append(R,B)]),
	if
		H == C ->
			{found,R};
		length(R) > D ->
			not_found;
		true ->
			loop(R,D,C)
	end.
	
hash_md5(L) ->
	hexstring(crypto:md5(L)).
	
hexstring(<<X:128/big-unsigned-integer>>) ->
    lists:flatten(io_lib:format("~32.16.0b", [X]));
hexstring(<<X:160/big-unsigned-integer>>) ->
    lists:flatten(io_lib:format("~40.16.0b", [X]));
hexstring(<<X:256/big-unsigned-integer>>) ->
    lists:flatten(io_lib:format("~64.16.0b", [X]));
hexstring(<<X:512/big-unsigned-integer>>) ->
    lists:flatten(io_lib:format("~128.16.0b", [X])).
	
hexstr_to_bin(S) ->
  hexstr_to_bin(S, []).
hexstr_to_bin([], Acc) ->
  list_to_binary(lists:reverse(Acc));
hexstr_to_bin([X,Y|T], Acc) ->
  {ok, [V], []} = io_lib:fread("~16u", [X,Y]),
  hexstr_to_bin(T, [V | Acc]).
	