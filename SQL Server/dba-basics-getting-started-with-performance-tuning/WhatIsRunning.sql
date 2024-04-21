-- Do not lock anything, and do not get held up by any locks.
   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
   SELECT @@SERVERNAME, DB_NAME(DB_ID()) AS DatabaseName 
   SELECT [Spid] = sp.session_Id    ,
--er.request_id,--ecid    ,
er.command,
[Database] = DB_NAME(er.database_id)    ,
[User] = login_name    ,
er.group_id,
sp.group_id AS SP_GroupID,
er.blocking_session_id,
[Status] = er.status    ,
[Wait] = wait_type    ,

CAST('<?query --'+CHAR(13)+SUBSTRING(qt.text, (er.statement_start_offset / 2)+1, 
    ((CASE er.statement_end_offset
    WHEN -1 THEN DATALENGTH(qt.text)
    ELSE er.statement_end_offset
    END - er.statement_start_offset)/2) + 1)+CHAR(13)+'--?>' AS xml) as sql_statement,

[Parent Query] = qt.text    ,
p.query_plan,
er.cpu_time, er.reads, er.writes, er.Logical_reads, er.row_count, Program = program_name,
Host_name    ,
start_time
FROM sys.dm_exec_requests er
JOIN sys.dm_exec_sessions sp ON er.session_id = sp.session_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle)as qt
CROSS apply sys.dm_exec_query_plan(er.plan_handle) p
WHERE 1=1
AND sp.is_user_process = 1 
AND sp.session_Id NOT IN (@@SPID)
 ORDER BY 1, 2

 --SELECT * FROM sys.resource_governor_workload_groups

 --exec sp_WhoIsActive --@get_task_info = 1, @get_locks=1, @find_block_leaders=1 --@help=1


--select * from sys.dm_exec_requests where session_id = 568

--SELECT * FROM sys.dm_exec_query_memory_grants where grant_time is null  