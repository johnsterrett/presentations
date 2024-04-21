USE [AdventureWorks2012]
GO

/**
DROP INDEX [IX_Person_LastName_FirstName_MiddleName] ON [Person].[Person]
GO

DROP INDEX [IX_Person_LastName_FirstName_MiddleName2] ON [Person].[Person]
**/

/**** Always have Clean starting point in Non-Prod ****/
/* Why should we do a checkpoint before dropping clean buffers? */

CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
/* 
DID YOU KNOW?
You can free just a statement by using plan handle or sql_handle?
select * from sys.dm_exec_query_stats
DBCC FREEPROCCACHE (0x02000000660A4835A89ED75CBC7DEC5D570533AC4934517A0000000000000000000000000000000000000000);

*/

SET STATISTICS IO ON
SET STATISTICS TIME ON

-- Which query has less cost? How do we know?

SELECT *
FROM Person.Person


CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SELECT FirstName, LastName, MiddleName
FROM Person.Person

/*
(19972 rows affected)
Table 'Person'. Scan count 1, logical reads 3816, physical reads 1, page server reads 0, read-ahead reads 3815, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 125 ms,  elapsed time = 1520 ms.

(19972 rows affected)
Table 'Person'. Scan count 1, logical reads 3816, physical reads 1, page server reads 0, read-ahead reads 3815, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 31 ms,  elapsed time = 1139 ms.
*/




SELECT FirstName, LastName
FROM Person.Person

CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SELECT FirstName, LastName
FROM Person.Person
WHERE LastName like 'Smith'

/* Alt-F1 or run sp_help */
sp_help 'Person.Person'


/*
(103 row(s) affected)
Table 'Person'. Scan count 1, logical reads 3816, physical reads 1, read-ahead reads 3815, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

*/
CREATE NONCLUSTERED INDEX [IX_Person_LastName_FirstName_MiddleName] ON [Person].[Person]
(
	[LastName] ASC
)

SELECT FirstName, LastName --, MiddleName
FROM Person.Person
WHERE LastName like 'Smith'

/*
(103 row(s) affected)
Table 'Person'. Scan count 1, logical reads 327, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
*/

--DROP INDEX [IX_Person_LastName_FirstName_MiddleName] ON [Person].[Person]
CREATE NONCLUSTERED INDEX [IX_Person_LastName_FirstName_MiddleName] ON [Person].[Person]
(
	[LastName]
)
INCLUDE (	[FirstName] )
WITH DROP_EXISTING

SELECT FirstName, LastName
FROM Person.Person
WHERE LastName like 'Smith'
/*
(103 row(s) affected)
Table 'Person'. Scan count 1, logical reads 4, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
*/

/* Now what do we do? Typically, I see people create another index */
SELECT FirstName, LastName, MiddleName
FROM Person.Person
WHERE LastName like 'Smith'


/*

(103 row(s) affected)
Table 'Person'. Scan count 1, logical reads 328, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
*/

CREATE NONCLUSTERED INDEX [IX_Person_LastName_FirstName_MiddleName2] ON [Person].[Person]
(
	[LastName]
)
INCLUDE (	[FirstName], [MiddleName] )


SELECT FirstName, LastName, MiddleName
FROM Person.Person
WHERE LastName like 'Smith'
/*

(103 row(s) affected)
Table 'Person'. Scan count 1, logical reads 3, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
*/


/* The second variation of this query finds partial, or duplicate, indexes that share leading key columns,
 e.g. Ix1(col1, col2, col3) and Ix2(col1, col2) would be considered duplicate indexes. 
 This query only examines key columns and does not consider included columns. 
These types of indexes are probable dead indexes walking.

-- Overlapping indxes
*/
;with indexcols as
(
select object_id as id, index_id as indid, name,
(select case keyno when 0 then NULL else colid end as [data()]
from sys.sysindexkeys as k
where k.id = i.object_id
and k.indid = i.index_id
order by keyno, colid
for xml path('')) as cols
from sys.indexes as i
)
select
object_schema_name(c1.id) + '.' + object_name(c1.id) as 'table',
c1.name as 'index',
c2.name as 'partialduplicate'
from indexcols as c1
join indexcols as c2
on c1.id = c2.id
and c1.indid < c2.indid
and ((c1.cols like c2.cols + '%' and SUBSTRING(c1.cols,LEN(c2.cols)+1,1) = ' ')
or (c2.cols like c1.cols + '%' and SUBSTRING(c2.cols,LEN(c1.cols)+1,1) = ' ')) ;


/* Disable execution plan and Run our query 1k */
SELECT FirstName, LastName, MiddleName
FROM Person.Person
WHERE LastName like 'Smith'
GO 100

/* Look at index usage */
;with cte AS (SELECT object_name(i.object_id) as table_name
,COALESCE(i.name, space(0)) as index_name
,ps.partition_number
,ps.row_count
,Cast((ps.reserved_page_count * 8)/1024. as decimal(12,2)) as size_in_mb
,COALESCE(ius.user_seeks,0) as user_seeks
,COALESCE(ius.user_scans,0) as user_scans
,COALESCE(ius.user_lookups,0) as user_lookups
,i.type_desc
,fg.name as FilegroupName
FROM sys.all_objects t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
INNER JOIN sys.filegroups fg ON i.data_space_id = fg.data_space_id
LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON ius.database_id = db_id() AND i.object_id = ius.object_id AND i.index_id = ius.index_id )

SELECT * FROM cte
where table_name like 'Person'
ORDER BY size_in_mb desc

/* Which index does it use for both queries? */
SELECT FirstName, LastName, MiddleName
FROM Person.Person
WHERE LastName like 'Smith'

SELECT FirstName, LastName
FROM Person.Person
WHERE LastName like 'Smith'

/* Fix partical duplicate index */
DROP INDEX [IX_Person_LastName_FirstName_MiddleName] ON [Person].[Person]

SELECT FirstName, LastName, MiddleName
FROM Person.Person
WHERE LastName like 'Smith'

SELECT FirstName, LastName
FROM Person.Person
WHERE LastName like 'Smith'

/* Clean up the demo */
SET STATISTICS IO OFF
SET STATISTICS TIME OFF