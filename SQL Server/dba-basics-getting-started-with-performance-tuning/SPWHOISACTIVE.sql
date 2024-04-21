/* Open Source Script (C) 2007-2020, Adam Machanic 
Updates: http://whoisactive.com
*/


/* Here is how most people execute sp_whoIsActive */
exec sp_whoisactive 




exec sp_whoIsActive  @sort_order = '[CPU] DESC', @get_task_info=2




/* The best command */
exec sp_whoIsActive @help = 1



exec sp_whoIsActive @get_plans = 1




exec sp_whoIsActive  @sort_order = '[CPU] DESC', @get_task_info=2





exec sp_whoIsActive @get_plans=1, @show_sleeping_spids = 0





exec sp_whoIsActive @find_block_leaders  = 1, 
@sort_order = '[blocked_session_count] DESC'




exec sp_whoIsActive @find_block_leaders  = 1,@get_task_info = 2,
@get_additional_info = 1, @sort_order = '[blocked_session_count] DESC'


/* Log sp_whoIsActive to table */
DECLARE @destination_table VARCHAR(4000) ;
SET @destination_table = 'WhoIsActive_' + CONVERT(VARCHAR, GETDATE(), 112) ;

DECLARE @schema VARCHAR(4000) ;
EXEC sp_WhoIsActive
@get_transaction_info = 1,
@get_plans = 1,
@find_block_leaders = 1,
@RETURN_SCHEMA = 1,
@SCHEMA = @schema OUTPUT ;

SET @schema = REPLACE(@schema, '<table_name>', @destination_table) ;

PRINT @schema
EXEC(@schema) ;

/* Collect data */

DECLARE
    @destination_table VARCHAR(4000) ,
    @msg NVARCHAR(1000) ;

SET @destination_table = 'WhoIsActive_' + CONVERT(VARCHAR, GETDATE(), 112) ;

DECLARE @numberOfRuns INT ;
SET @numberOfRuns = 10 ;

WHILE @numberOfRuns > 0
    BEGIN;
        EXEC dbo.sp_WhoIsActive @get_transaction_info = 1, @get_plans = 1,
            @find_block_leaders = 1, @DESTINATION_TABLE = @destination_table ;

        SET @numberOfRuns = @numberOfRuns - 1 ;

        IF @numberOfRuns > 0
            BEGIN
                SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + ': ' +
                 'Logged info. Waiting...'
                RAISERROR(@msg,0,0) WITH nowait ;

                WAITFOR DELAY '00:00:05'
            END
        ELSE
            BEGIN
                SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + ': ' + 'Done.'
                RAISERROR(@msg,0,0) WITH nowait ;
            END

    END ;
GO

/* Query Results */
DECLARE @destination_table NVARCHAR(2000), @dSQL NVARCHAR(4000) ;
SET @destination_table = 'WhoIsActive_' + CONVERT(VARCHAR, GETDATE(), 112) ;
SET @dSQL = N'SELECT collection_time, * FROM dbo.' +
 QUOTENAME(@destination_table) + N' order by 1 desc, blocked_session_count desc' ;

print @dSQL;

EXEC sp_executesql @dSQL;