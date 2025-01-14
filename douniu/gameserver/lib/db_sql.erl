%%%--------------------------------------
%%% @Module  : db_sql
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.05.10
%%% @Description: MYSQL数据库操作 
%%%--------------------------------------
-module(db_sql).
-export(
    [
        execute/1,
        transaction/1,
        select_limit/3,
        select_limit/4,
        get_one/1,
        get_one/2,
        get_row/1,
        get_row/2,
        get_all/1,
        get_all/2,
        make_insert_sql/3,
        make_update_sql/5,
		make_replace_sql/3,
        sql_format/1,
		sql_format2/1,
		sql_str_escape/2,
		execute/2
    ]
).
-include("common.hrl").
-include("mysql.hrl").

%%define a timeout for gen server call
-define(TIMEOUT,60*1000).

%% 执行一个SQL查询,返回影响的行数
%% execute(Sql) ->
%%     case mysql:fetch(?DB, Sql) of
%%         {updated, {_, _, _, R, _}} -> R;
%%         {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason]);
%% 		{data, {_, _, ResultList, _, _}} -> ResultList
%%     end.
%% execute(Sql, Args) when is_atom(Sql) ->
%%     case mysql:execute(?DB, Sql, Args) of
%%         {updated, {_, _, _, R, _}} -> R;
%%         {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
%%     end;
%% execute(Sql, Args) ->
%%     mysql:prepare(s, Sql),
%%     case mysql:execute(?DB, s, Args) of
%%         {updated, {_, _, _, R, _}} -> R;
%%         {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
%%     end.

execute(Connection,Sql) ->
    case mysql:fetch(Connection, Sql,?TIMEOUT) of
        {data, MysqlResult} ->
            {ok, MysqlResult#mysql_result.rows};
        {updated, MysqlResult} ->
            {ok, MysqlResult#mysql_result.affectedrows};
        {error, _MysqlResult} ->
%%            ?ERR(db, "~n[Database Error]: ~nQuery:   ~ts~nError:   ~ts", [Sql, _MysqlResult#mysql_result.error]),
            error
    end.


%% 执行一条sql语句
%% @spec execute(Sql) -> {ok, Result} | error
execute(Sql) ->
	%%?DEBUG(who, "~p", [self()]),
    case mysql:fetch(?DB, Sql,?TIMEOUT) of
        {data, MysqlResult} ->
            {ok, MysqlResult#mysql_result.rows};
        {updated, MysqlResult} ->
            {ok, MysqlResult#mysql_result.affectedrows};
        {error, MysqlResult} ->
            ?ERR("~n[Database Error]: ~nQuery:   ~ts~nError:   ~ts", [Sql, MysqlResult#mysql_result.error]),
            error
    end.

%% 事务处理
transaction(F) ->
    case mysql:transaction(?DB, F,?TIMEOUT) of
        {atomic, R} -> R;
        {updated, {_, _, _, R, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Reason]);
        {aborted, {Reason, _}} -> mysql_halt([Reason]);
        Error -> mysql_halt([Error])
    end.

%% 执行分页查询返回结果中的所有行
select_limit(Sql, Offset, Num) ->
    S = list_to_binary([Sql, <<" limit ">>, integer_to_list(Offset), <<", ">>, integer_to_list(Num)]),
    case mysql:fetch(?DB, S,?TIMEOUT) of
        {data, {_, _, R, _, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end.
select_limit(Sql, Args, Offset, Num) ->
    S = list_to_binary([Sql, <<" limit ">>, list_to_binary(integer_to_list(Offset)), <<", ">>, list_to_binary(integer_to_list(Num))]),
    mysql:prepare(s, S),
    case mysql:execute(?DB, s, Args,?TIMEOUT) of
        {data, {_, _, R, _, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end.

%% 取出查询结果中的第一行第一列
%% 未找到时返回null
get_one(Sql) ->
    case mysql:fetch(?DB, Sql,?TIMEOUT) of
        {data, {_, _, [], _, _}} -> null;
        {data, {_, _, [[R]], _, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end.
get_one(Sql, Args) when is_atom(Sql) ->
    case mysql:execute(?DB, Sql, Args,?TIMEOUT) of
        {data, {_, _, [], _, _}} -> null;
        {data, {_, _, [[R]], _, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end;
get_one(Sql, Args) ->
    mysql:prepare(s, Sql),
    case mysql:execute(?DB, s, Args,?TIMEOUT) of
        {data, {_, _, [], _, _}} -> null;
        {data, {_, _, [[R]], _, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end.

%% 取出查询结果中的第一行
get_row(Sql) ->
    case mysql:fetch(?DB, Sql,?TIMEOUT) of
        {data, {_, _, [], _, _}} -> [];
        {data, {_, _, R, _, _}} -> hd(R);
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end.
get_row(Sql, Args) when is_atom(Sql) ->
    case mysql:execute(?DB, Sql, Args,?TIMEOUT) of
        {data, {_, _, [], _, _}} -> [];
        {data, {_, _, R, _, _}} -> hd(R);
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end;
get_row(Sql, Args) ->
    mysql:prepare(s, Sql),
    case mysql:execute(?DB, s, Args,?TIMEOUT) of
        {data, {_, _, [], _, _}} -> [];
        {data, {_, _, R, _, _}} -> hd(R);
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end.

%% 取出查询结果中的所有行
get_all(Sql) ->
    case mysql:fetch(?DB, Sql,?TIMEOUT) of
        {data, {_, _, R, _, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end.
get_all(Sql, Args) when is_atom(Sql) ->
    case mysql:execute(?DB, Sql, Args,?TIMEOUT) of
        {data, {_, _, R, _, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end;
get_all(Sql, Args) ->
    mysql:prepare(s, Sql),
    case mysql:execute(?DB, s, Args,?TIMEOUT) of
        {data, {_, _, R, _, _}} -> R;
        {error, {_, _, _, _, Reason}} -> mysql_halt([Sql, Reason])
    end.

%% @doc 显示人可以看得懂的错误信息
mysql_halt([Sql, Reason]) ->
    erlang:error({db_error, [Sql, Reason]}).

%%组合mysql insert语句
%% 使用方式make_insert_sql(test,["row","r"],["测试",123]) 相当 insert into `test` (row,r) values('测试','123')
%%Table:表名
%%Field:字段
%%Data:数据
make_insert_sql(Table, Field, Data) ->
    L = make_conn_sql(Field, Data, []),
    lists:concat(["insert into `", Table, "` set ", L]).
    
%%组合mysql insert语句
%% 使用方式make_update_sql(test,["row","r"],["测试",123],"id",1) 相当 update `test` set row='测试', r = '123' where id = '1'
%%Table:表名
%%Field：字段
%%Data:数据
%%Key:键
%%Data:值
make_update_sql(Table, Field, Data, Key, Value) ->
    L = make_conn_sql(Field, Data, []),
    lists:concat(["update `", Table, "` set ",L," where ",Key,"= '",sql_format(Value),"'"]).

%%组合mysql replace语句
%% 使用方式make_insert_sql(test,["row","r"],["测试",123]) 
%%相当 replace into `test` (row,r) values('测试','123')
%%Table:表名
%%Field：字段
%%Data:数据
make_replace_sql(Table, Field, Data) ->
    L = make_conn_sql(Field, Data, []),
    lists:concat(["replace into `", Table, "` set ", L]).

make_conn_sql([], _, L ) ->
    L ;
make_conn_sql(_, [], L ) ->
    L ;
make_conn_sql([F | T1], [D | T2], []) ->
    L  = [F," = '",sql_format(D),"'"],
    make_conn_sql(T1, T2, L);
make_conn_sql([F | T1], [D | T2], L) ->
    L1  = L ++ [",", F," = '",sql_format(D),"'"],
    make_conn_sql(T1, T2, L1).

sql_format(S) when is_integer(S)->
    integer_to_list(S);
sql_format(S) when is_float(S)->
    float_to_list(S);
sql_format(S) when is_list(S) ->
	sql_str_escape(S, "");
sql_format(S) ->
    S.

sql_format2(S) when is_list(S) ->
	sql_str_escape(S, "");
sql_format2(S) ->
    S.

sql_str_escape([], Acc) ->
	lists:reverse(Acc);
sql_str_escape([H | T], Acc) ->
	NewAcc = 
		case H of
			$"  -> [H, $\\ | Acc];
			$'  -> [H, $\\ | Acc];
			$\\ -> [H, $\\ | Acc];
			_   -> [H | Acc]
		end,
	sql_str_escape(T, NewAcc);

sql_str_escape(<<>>, Acc) ->
	Acc;
sql_str_escape(<<H:8, T/binary>>, Acc) ->
	NewAcc = 
		case H of
			$"  -> <<Acc/binary, $\\:8, H:8>>;
			$'  -> <<Acc/binary, $\\:8, H:8>>;
			$\\ -> <<Acc/binary, $\\:8, H:8>>;
			_   -> <<Acc/binary, H:8>>
		end,
	sql_str_escape(T, NewAcc).
