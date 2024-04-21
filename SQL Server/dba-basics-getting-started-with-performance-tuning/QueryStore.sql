/* The first thing we want to know in query store is 
how much data exists and what are our query store settings. */
select * FROM sys.database_query_store_options;


/* Time period of data in Query Store */
;with cte as (select max(runtime_stats_interval_id) as max, min(runtime_stats_interval_id) as min
from sys.query_store_runtime_stats rs)
select min.start_time, max.end_time 
from cte
left join sys.query_store_runtime_stats_interval min on cte.min = min.runtime_stats_interval_id
left join sys.query_store_runtime_stats_interval max on cte.max = max.runtime_stats_interval_id
option(maxdop 1, recompile);

/* Time slices
The following are the time interval slices used to aggregate execution data.
*/
select *, datediff(mi,  start_time,end_time) DiffMinutes 
from sys.query_store_runtime_stats_interval

/* Top Offenders per Exection Plan
The Query Store keeps query runtime metrics down tp the execution plan level.
An query can have multiple execution plans, for queries that are very similar. 
An perfect example, is query that is exactly the same expect for literal 
values being used instead of parameters.
*/
;with cte as (SELECT SUM(Count_executions) AS TotalExecutions,
	   SUM(Count_executions*avg_duration) AS TotalDuration,
	   SUM(Count_executions*avg_logical_io_reads) AS TotalReads,
	   SUM(Count_executions*avg_logical_io_writes) AS TotalWrites,
	   SUM(count_executions*avg_cpu_time) AS TotalCPU,
	   query_hash

FROM sys.query_store_runtime_stats rs
JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
JOIN sys.query_store_query q ON p.query_id = q.query_id
GROUP BY q.query_hash)
select TOP 50 *,  (select top 1 OBJECT_NAME(object_id) from sys.query_store_query q WHERE q.query_hash = cte.query_hash) AS ObjectID
 from cte
where TotalExecutions > 10
ORDER BY TotalCPU DESC
option (maxdop 1, recompile);

/* */
declare @query_hash binary(8) = 0x89CCED864C067FDB

;with cte as (select query_id, query_text_id, context_settings_id, q.object_id, o.name AS ObjectName,
query_hash, initial_compile_start_time, last_compile_start_time, last_execution_time, avg_compile_duration 
from sys.query_store_query q 
left join sys.objects o on o.object_id = q.object_id
where q.query_hash = @query_hash)
select t.query_sql_text, cte.* from cte
left join sys.query_store_query_text t on cte.query_text_id = t.query_text_id
option (recompile, maxdop 1)


select [plan_id], [query_id], [plan_group_id], [engine_version], [compatibility_level], [query_plan_hash], TRY_CAST(query_plan AS XML) AS XPlan , [is_online_index_plan], [is_trivial_plan], [is_parallel_plan], [is_forced_plan], [is_natively_compiled], [force_failure_count], [last_force_failure_reason], [last_force_failure_reason_desc], [count_compiles], [initial_compile_start_time], [last_compile_start_time], [last_execution_time], [avg_compile_duration], [last_compile_duration], [plan_forcing_type], [plan_forcing_type_desc]
from sys.query_store_plan p
where p.query_id IN (select query_id from sys.query_store_query where query_hash = @query_hash)
ORDER BY query_id desc
option (recompile, maxdop 1)
GO

/* Waits per Query */
declare @query_hash binary(8) = 0x89CCED864C067FDB

select  plan_id, wait_category_desc, SUM(total_query_wait_time_ms) TotalWaitMs 
from sys.query_store_wait_stats
where plan_id in (SELECT plan_id 
                from sys.query_store_plan WHERE query_id IN (
                    SELECT query_id from sys.query_store_query where query_hash = @Query_Hash)
                  )
group by plan_id, wait_category_desc
order by plan_id, TotalWaitMs DESC

/* Find Missing Indexes for Top Offenders */
/* Get plans with missing indexes from top 50 top read offenders in last week */

;with cte as (SELECT SUM(Count_executions) AS TotalExecutions,
	   SUM(Count_executions*avg_duration) AS TotalDuration,
	   SUM(Count_executions*avg_logical_io_reads) AS TotalReads,
	   SUM(Count_executions*avg_logical_io_writes) AS TotalWrites,
	   SUM(count_executions*avg_cpu_time) AS TotalCPU,
	   query_hash

FROM sys.query_store_runtime_stats rs
JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
JOIN sys.query_store_query q ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats_interval qsrsi on rs.runtime_stats_interval_id=qsrsi.runtime_stats_interval_id
WHERE qsrsi.start_time >= DATEADD(DAY, -7, SYSDATETIME())
GROUP BY q.query_hash) 

select TOP 50 * 
into #tmp
from cte 
where TotalExecutions > 10 
ORDER BY TotalReads DESC
option (maxdop 1, recompile);

;with cte as (SELECT qsq.query_hash, qsq.query_id, qsp.plan_id, count(*) AS Intervals
FROM #tmp a
JOIN sys.query_store_query qsq on a.query_hash = qsq.query_hash
JOIN sys.query_store_plan qsp on qsq.query_id=qsp.query_id
JOIN sys.query_store_runtime_stats qrs on qsp.plan_id = qrs.plan_id
JOIN sys.query_store_runtime_stats_interval qsrsi on qrs.runtime_stats_interval_id=qsrsi.runtime_stats_interval_id
WHERE    
    1=1
    and qsrsi.start_time >= DATEADD(DAY, -7, SYSDATETIME())
GROUP BY  qsq.query_hash, qsq.query_id, qsp.plan_id
)
select query_hash, cte.query_id, cte.plan_id, Intervals, TRY_CAST(query_plan AS XML) AS XPlan 
from cte
join sys.query_store_plan p on cte.plan_id = p.plan_id
where p.query_plan like N'%<MissingIndexes>%'
ORDER BY 4 DESC

DROP TABLE #tmp
GO