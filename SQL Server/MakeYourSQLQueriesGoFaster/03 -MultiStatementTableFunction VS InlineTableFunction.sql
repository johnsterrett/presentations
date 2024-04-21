/* Start comparing MSTVF and ILTVF before SQL 2017 AQP */
USE [master]
GO
ALTER DATABASE [WideWorldImporters] SET COMPATIBILITY_LEVEL = 130
GO

use WideWorldImporters
go


/* 
creating multi-statement TVF 
*/ 
create or alter function mstvf() 
returns @SaleDetail table ([SalespersonPersonID] int, [StockItemID] int) 
as 
begin 
insert into @SaleDetail 
SELECT [SalespersonPersonID], [StockItemID]
from [Sales].[Orders] o
JOIN [Sales].[OrderLines] ol on o.OrderID = ol.OrderID
return 
end

go


/*TODO: Turn on actual execution plan */
set statistics io on 
set statistics time on 
go 


select c.PersonID, c.PreferredName, c.FullName, si.StockItemName, 
COUNT (*) 'units' 
from [Application].[People] c inner join 
dbo.mstvf() m on c.PersonID = m.SalespersonPersonID
inner join [Warehouse].[StockItems] si on m.StockItemID = si.[StockItemID]
group by c.PersonID, c.PreferredName, c.FullName, si.StockItemName


/* 
  the estimate is inaccurate for tvf_multi_Test (100 rows SQL 2017, 2016, 1 row before SQL 2016) 
  Note: Sort spilled to tempdb and we used nested lookups 231,412 rows going into nested loop.
  Note: memory grant is 1024.  Due to low estimate of rows we have a low estimate of memory neeeded 
  hense our sort dumping to tempdb.

  Table 'People'. Scan count 0, logical reads 477296, physical reads 0, read-ahead reads 1, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 5378, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 0, logical reads 462824, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table '#B21EE057'. Scan count 1, logical reads 487, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(11 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 1922 ms,  elapsed time = 2408 ms.
*/ 


go
/* Inline Table Value Function example */


drop function if exists intvf
go

create or alter function intvf() 
returns table 
as 
return 
SELECT [SalespersonPersonID], [StockItemID]
from [Sales].[Orders] o
JOIN [Sales].[OrderLines] ol on o.OrderID = ol.OrderID

go

select c.PersonID, c.PreferredName, c.FullName, si.StockItemName, 
COUNT (*) 'numer of unit' 
from [Application].[People] c inner join 
dbo.intvf() i on c.PersonID = i.SalespersonPersonID
inner join [Warehouse].[StockItems] si on i.StockItemID = si.[StockItemID]
group by c.PersonID, c.PreferredName, c.FullName, si.StockItemName
go
/*
NOTE: You don't see function call in plan or I/o. Inline table function is treated like a view.
NOTE: Nested loop now turns into Hash due to good stats of the tables.
NOTE: Memory Grant is almost 20x higher than MSTVF

(2270 rows affected)
Table 'OrderLines'. Scan count 2, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 159, lob physical reads 0, lob read-ahead reads 0.
Table 'OrderLines'. Segment reads 1, segment skipped 0.
Table 'Orders'. Scan count 1, logical reads 138, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'People'. Scan count 1, logical reads 80, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 6, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(11 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 78 ms,  elapsed time = 264 ms.
*/


/* SQL 2019 It just goes faster.... Right? */
USE [master]
GO
ALTER DATABASE [WideWorldImporters] SET COMPATIBILITY_LEVEL = 150
GO


set statistics io on 
set statistics time on 
go 

use [WideWorldImporters]
go

select c.PersonID, c.PreferredName, c.FullName, si.StockItemName, 
COUNT (*) 'units' 
from [Application].[People] c inner join 
dbo.mstvf() m on c.PersonID = m.SalespersonPersonID
inner join [Warehouse].[StockItems] si on m.StockItemID = si.[StockItemID]
group by c.PersonID, c.PreferredName, c.FullName, si.StockItemName

/*
NOTE: The stats on MSTVF is pushed to be done first. We have good stats now.
NOTE: Good stats gets us a hash join instead of the nested loop
NOTE: Memory ~4mb
(2270 rows affected)
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table '#BD909303'. Scan count 1, logical reads 487, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'People'. Scan count 1, logical reads 80, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 6, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(10 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 912 ms,  elapsed time = 1236 ms.
   */


select c.PersonID, c.PreferredName, c.FullName, si.StockItemName, 
COUNT (*) 'units' 
from [Application].[People] c inner join 
dbo.intvf() i on c.PersonID = i.SalespersonPersonID
inner join [Warehouse].[StockItems] si on i.StockItemID = si.[StockItemID]
group by c.PersonID, c.PreferredName, c.FullName, si.StockItemName

go 

set statistics io off 
set statistics time off

/*

(2270 rows affected)
Table 'OrderLines'. Scan count 2, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 159, lob physical reads 0, lob read-ahead reads 0.
Table 'OrderLines'. Segment reads 1, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 6, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Orders'. Scan count 1, logical reads 138, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'People'. Scan count 1, logical reads 80, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 62 ms,  elapsed time = 156 ms.

*/
