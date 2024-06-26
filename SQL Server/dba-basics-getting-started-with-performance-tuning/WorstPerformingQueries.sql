/*
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_WorstPerformingQueries] 
*/
DECLARE	
	@DBName varchar(128) 
	,@Count int 
	,@OrderBy varchar(4) 
DECLARE @Return int

SET @DBName = 'All Databases'
SET @Count = 50
SET @OrderBy = 'TE'
/*
Name: usp_WorstPerformingQueries
Description: This stored procedure displays the top worst performing queries based on CPU, Execution Count, 
             I/O and Elapsed_Time as identified using DMV information.  This can be display the worst 
             performing queries from an instance, or database perspective.   The number of records shown,
             the database, and the sort order are identified by passing pararmeters.

Parameters:  There are three different parameters that can be passed to this procedures: @DBName, @Count
             and @OrderBy.  The @DBName is used to constraint the output to a specific database.  If  
             when calling this SP this parameter is set to a specific database name then only statements 
             that are associated with that database will be displayed.  If the @DBName parameter is not set
             then this SP will return rows associated with any database.  The @Count parameter allows you 
             to control the number of rows returned by this SP.  If this parameter is used then only the 
             TOP x rows, where x is equal to @Count will be returned, based on the @OrderBy parameter.
             The @OrderBy parameter identifies the sort order of the rows returned in descending order.  
             This @OrderBy parameters supports the following type: CPU, AE, TE, EC or AIO, TIO, ALR, TLR, ALW, TLW, APR, and TPR 
             where "ACPU" represents Average CPU Usage
                   "TCPU" represents Total CPU usage 
                   "AE"   represents Average Elapsed Time
                   "TE"   represents Total Elapsed Time
                   "EC"   represents Execution Count
                   "AIO"  represents Average IOs
                   "TIO"  represents Total IOs 
                   "ALR"  represents Average Logical Reads
                   "TLR"  represents Total Logical Reads              
                   "ALW"  represents Average Logical Writes
                   "TLW"  represents Total Logical Writes
                   "APR"  represents Average Physical Reads
                   "TPR"  represents Total Physical Read

Typical execution calls
   
   Top 6 statements in the AdventureWorks database base on Average CPU Usage:
      EXEC usp_WorstPerformingQueries @DBName='AdventureWorks',@Count=6,@OrderBy='ACPU';
   
   Top 100 statements order by Average IO 
      EXEC usp_WorstPerformingQueries @Count=100,@OrderBy='ALR'; 

   Show top all statements by Average IO 
      EXEC usp_WorstPerformingQueries;

*/
--AS
-- Check for valid @OrderBy parameter
IF ((SELECT CASE WHEN 
          @OrderBy in ('ACPU','TCPU','AE','TE','EC','AIO','TIO','ALR','TLR','ALW','TLW','APR','TPR') 
             THEN 1 ELSE 0 END) = 0)
BEGIN 
   -- abort if invalid @OrderBy parameter entered
   RAISERROR('@OrderBy parameter not APCU, TCPU, AE, TE, EC, AIO, TIO, ALR, TLR, ALW, TLW, APR or TPR',11,1)
   --RETURN 1
 END
 
 /* Version SQL Server 2005 */
 
 SELECT TOP (@Count) 
         COALESCE(DB_NAME(ST.dbid), DB_NAME(CAST(PA.value AS INT)) + '*', 'Resource') as [Database Name]  
         -- find the offset of the actual statement being executed
           
         ,OBJECT_SCHEMA_NAME(ST.objectid,ST.dbid) as [Schema Name] 
         ,OBJECT_NAME(ST.objectid,ST.dbid) as [Object Name]   
         ,creation_time
		 ,getdate() PullDate
		 ,CP.objtype as [Cached Plan objtype] 
         ,QS.execution_count as [Execution Count]  
         ,(QS.total_logical_reads + QS.total_logical_writes + QS.total_physical_reads ) / QS.execution_count as [Average IOs] 
         ,QS.total_logical_reads + QS.total_logical_writes + QS.total_physical_reads as [Total IOs]  
         ,QS.total_logical_reads / QS.execution_count as [Avg Logical Reads] 
         ,QS.total_logical_reads as [Total Logical Reads]  
         ,QS.total_logical_writes / QS.execution_count as [Avg Logical Writes]  
         ,QS.total_logical_writes as [Total Logical Writes]  
         ,QS.total_physical_reads / execution_count as [Avg Physical Reads] 
         ,QS.total_physical_reads as [Total Physical Reads]   
         ,QS.total_worker_time / QS.execution_count as [Avg CPU] 
         ,QS.total_worker_time as [Total CPU] 
         ,QS.total_elapsed_time / QS.execution_count as [Avg Elapsed Time] 
         ,QS.total_elapsed_time  as [Total Elasped Time] 
         ,QS.last_execution_time as [Last Execution Time]
		 ,SUBSTRING(text, 
                   CASE WHEN QS.statement_start_offset = 0 
                          OR QS.statement_start_offset IS NULL  
                           THEN 1  
                           ELSE QS.statement_start_offset / 2 + 1 END, 
                   CASE WHEN QS.statement_end_offset = 0 
                          OR QS.statement_end_offset = -1  
                          OR QS.statement_end_offset IS NULL  
                           THEN LEN(text)  
                           ELSE QS.statement_end_offset / 2 END - 
                     CASE WHEN QS.statement_start_offset = 0 
                            OR QS.statement_start_offset IS NULL 
                             THEN 1  
                             ELSE QS.statement_start_offset / 2  END + 1 
                  ) as [Statement]  ,
				  QP.query_plan,
				  QS.query_hash,
				  QS.query_plan_hash
  -- INTO DBATools.dbo.TopOffenders_CPU_20170206_1130am
    FROM sys.dm_exec_query_stats QS  
    LEFT JOIN sys.dm_exec_cached_plans CP ON QS.plan_handle = CP.plan_handle 
    CROSS APPLY sys.dm_exec_sql_text(QS.plan_handle) ST 
    OUTER APPLY sys.dm_exec_plan_attributes(QS.plan_handle) PA 
	OUTER APPLY sys.dm_exec_query_plan(CP.plan_handle) QP
    WHERE attribute = 'dbid' AND  
     CASE WHEN @DBName = 'All Databases' THEN 'All Databases'
          ELSE COALESCE(DB_NAME(ST.dbid), DB_NAME(CAST(PA.value AS INT)) + '*', 'Resource') END IN (RTRIM(@DBName),RTRIM(@DBName) + '*')  
      
    ORDER BY CASE 
                WHEN @OrderBy = 'ACPU' THEN total_worker_time / execution_count 
                WHEN @OrderBy = 'TCPU'  THEN total_worker_time
                WHEN @OrderBy = 'AE'   THEN total_elapsed_time / execution_count
                WHEN @OrderBy = 'TE'   THEN total_elapsed_time  
                WHEN @OrderBy = 'EC'   THEN execution_count
                WHEN @OrderBy = 'AIO'  THEN (total_logical_reads + total_logical_writes + total_physical_reads) / execution_count  
                WHEN @OrderBy = 'TIO'  THEN total_logical_reads + total_logical_writes + total_physical_reads
                WHEN @OrderBy = 'ALR'  THEN total_logical_reads  / execution_count
                WHEN @OrderBy = 'TLR'  THEN total_logical_reads 
                WHEN @OrderBy = 'ALW'  THEN total_logical_writes / execution_count
                WHEN @OrderBy = 'TLW'  THEN total_logical_writes  
                WHEN @OrderBy = 'APR'  THEN total_physical_reads / execution_count 
                WHEN @OrderBy = 'TPR'  THEN total_physical_reads
           END DESC
	
        OPTION (RECOMPILE, MAXDOP 1);
