USE [ContosoRetailDW]
GO
CHECKPOINT
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO
SET STATISTICS IO, TIME ON
SELECT TOP 20 fos.DateKey, dp.ProductName, 
	SUM(fos.SalesQuantity * fos.SalesAmount) AS TotalSalesAmount 
  FROM ContosoRetailDW.dbo.DimStore ds
  JOIN [ContosoRetailDW].[dbo].[FactOnlineSales] fos ON (ds.StoreKey = fos.StoreKey)
  JOIN ContosoRetailDW.dbo.DimDate dd ON (fos.DateKey = dd.Datekey)
  JOIN ContosoRetailDW.dbo.DimProduct dp ON (fos.ProductKey = dp.ProductKey)
  WHERE dp.ProductName like 'Contoso Mouse Lock Bundle E200 White'
  AND ds.StoreName like 'Contoso North America Online Store'
  AND dd.CalendarYear >= 2007
  GROUP BY fos.DateKey, dp.ProductName
  ORDER BY SUM(fos.SalesQuantity * fos.SalesAmount) desc
SET STATISTICS TIME OFF
SET STATISTICS IO OFF

/* Identify What Tables are accessed by Query 

FROM ContosoRetailDW.dbo.DimStore ds
  JOIN [ContosoRetailDW].[dbo].[FactOnlineSales] fos 
  JOIN ContosoRetailDW.dbo.DimDate dd 
  JOIN ContosoRetailDW.dbo.DimProduct dp 
*/


/* Identify Columns being Selected 
fos.DateKey, 
dp.ProductName, 
fos.SalesQuantity 
fos.SalesAmount
*/

/* Identify filters (HINT: JOIN and WHERE) 
   
  WHERE dp.ProductName like 'Contoso Mouse Lock Bundle E200 White'
  AND ds.StoreName like 'Contoso North America Online Store'
  AND dd.CalendarYear >= 2007

   ds.StoreKey = fos.StoreKey
  fos.DateKey = dd.Datekey
  fos.ProductKey = dp.ProductKey

*/


/*  Find total rows for each table accessed by Query  */

SELECT COUNT(*) FROM DimStore  -- 306
SELECT COUNT(*) FROM FactOnlineSales --12,627,608
SELECT COUNT(*) FROM DimDate --2556
SELECT COUNT(*) FROM DimProduct --2517




/* Find total selectivity for filters ( rows with filter applied divided by table rows) */

SELECT COUNT(*) FROM DimProduct  dp JOIN FactOnlineSales fos ON (dp.ProductKey = fos.ProductKey)
WHERE dp.ProductName like 'Contoso Mouse Lock Bundle E200 White' 

-- 4274
SELECT COUNT(*) FROM DimStore ds JOIN FactOnlineSales fos ON (ds.StoreKey = fos.StoreKey)
WHERE ds.StoreName like 'Contoso North America Online Store' 
-- 4645792

SELECT COUNT(*) FROM DimDate dd JOIN FactOnlineSales fos ON (dd.DateKey = fos.DateKey)
WHERE dd.CalendarYear >= 2007 
-- 12627608

/* Identify what indexes exist for tables used in query 
sp_help 'FactOnlineSales'

exec ProcureSQL.dbo.sp_blitzIndex @DatabaseName ='ContosoRetailDW', @TableName = 'FactOnlineSales', @SchemaName = 'dbo'
exec ProcureSQL.dbo.sp_blitzIndex @DatabaseName ='ContosoRetailDW', @TableName = 'DimProduct', @SchemaName = 'dbo'
exec ProcureSQL.dbo.sp_blitzIndex @DatabaseName ='ContosoRetailDW', @TableName = 'DimDate', @SchemaName = 'dbo'
exec ProcureSQL.dbo.sp_blitzIndex @DatabaseName ='ContosoRetailDW', @TableName = 'DimStore', @SchemaName = 'dbo'
https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit#how-to-install-the-scripts
 
*/

/* Enable set statistics IO, set statistics CPU, and capture execution plan then run the query. */
SET STATISTICS IO, TIME ON
SELECT TOP 20 fos.DateKey, dp.ProductName, 
	SUM(fos.SalesQuantity * fos.SalesAmount) AS TotalSalesAmount 
  FROM ContosoRetailDW.dbo.DimStore ds
  JOIN [ContosoRetailDW].[dbo].[FactOnlineSales] fos ON (ds.StoreKey = fos.StoreKey)
  JOIN ContosoRetailDW.dbo.DimDate dd ON (fos.DateKey = dd.Datekey)
  JOIN ContosoRetailDW.dbo.DimProduct dp ON (fos.ProductKey = dp.ProductKey)
  WHERE dp.ProductName like 'Contoso Mouse Lock Bundle E200 White'
  AND ds.StoreName like 'Contoso North America Online Store'
  AND dd.CalendarYear >= 2007
  GROUP BY fos.DateKey, dp.ProductName
  ORDER BY SUM(fos.SalesQuantity * fos.SalesAmount) desc
SET STATISTICS TIME OFF
SET STATISTICS IO OFF

/* Document your findings so you can start a benchmark. 
(20 rows affected)
Table 'DimStore'. Scan count 1, logical reads 24, physical reads 1, page server reads 0, read-ahead reads 23, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimProduct'. Scan count 1, logical reads 2, physical reads 2, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'FactOnlineSales'. Scan count 3, logical reads 47,310, physical reads 1, page server reads 0, read-ahead reads 46491, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimDate'. Scan count 0, logical reads 68, physical reads 7, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 1359 ms,  elapsed time = 1898 ms.
   
*/

/* Tweak indexes for lowest selectivity first. This would be filters that have the least amount of rows. */

--DROP INDEX idx_ProcureSQL2 ON dbo.FactOnlineSales
CREATE NONCLUSTERED INDEX idx_ProcureSQL2 ON dbo.FactOnlineSales (
ProductKey
) 
/* Rerun Query and compare stats and see how the execution plan changed */
SET STATISTICS IO, TIME ON
SELECT TOP 20 fos.DateKey, dp.ProductName, 
	SUM(fos.SalesQuantity * fos.SalesAmount) AS TotalSalesAmount 
  FROM ContosoRetailDW.dbo.DimStore ds
  JOIN [ContosoRetailDW].[dbo].[FactOnlineSales] fos ON (ds.StoreKey = fos.StoreKey)
  JOIN ContosoRetailDW.dbo.DimDate dd ON (fos.DateKey = dd.Datekey)
  JOIN ContosoRetailDW.dbo.DimProduct dp ON (fos.ProductKey = dp.ProductKey)
  WHERE dp.ProductName like 'Contoso Mouse Lock Bundle E200 White'
  AND ds.StoreName like 'Contoso North America Online Store'
  AND dd.CalendarYear >= 2007
  GROUP BY fos.DateKey, dp.ProductName
  ORDER BY SUM(fos.SalesQuantity * fos.SalesAmount) desc
SET STATISTICS TIME OFF
SET STATISTICS IO OFF

/*(20 rows affected)
Table 'DimStore'. Scan count 1, logical reads 24, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimProduct'. Scan count 3, logical reads 370, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'FactOnlineSales'. Scan count 1, logical reads 13,109, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimDate'. Scan count 0, logical reads 86, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 87 ms.

*/

/* Remember we pulled which columns were selected? */
DROP INDEX idx_ProcureSQL2 ON dbo.FactOnlineSales
CREATE NONCLUSTERED INDEX idx_ProcureSQL2 ON dbo.FactOnlineSales (
ProductKey
) INCLUDE (SalesQuantity, SalesAmount, DateKey, StoreKey)

/* Execute again and see differences */
SET STATISTICS IO, TIME ON
SELECT TOP 20 fos.DateKey, dp.ProductName, 
	SUM(fos.SalesQuantity * fos.SalesAmount) AS TotalSalesAmount 
  FROM ContosoRetailDW.dbo.DimStore ds
  JOIN [ContosoRetailDW].[dbo].[FactOnlineSales] fos ON (ds.StoreKey = fos.StoreKey)
  JOIN ContosoRetailDW.dbo.DimDate dd ON (fos.DateKey = dd.Datekey)
  JOIN ContosoRetailDW.dbo.DimProduct dp ON (fos.ProductKey = dp.ProductKey)
  WHERE dp.ProductName like 'Contoso Mouse Lock Bundle E200 White'
  AND ds.StoreName like 'Contoso North America Online Store'
  AND dd.CalendarYear >= 2007
  GROUP BY fos.DateKey, dp.ProductName
  ORDER BY SUM(fos.SalesQuantity * fos.SalesAmount) desc
SET STATISTICS TIME OFF
SET STATISTICS IO OFF


/* -- The good index --
(20 rows affected)
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'FactOnlineSales'. Scan count 1, logical reads 24, physical reads 2, page server reads 0, read-ahead reads 28, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimProduct'. Scan count 1, logical reads 2, physical reads 2, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimStore'. Scan count 1, logical reads 24, physical reads 1, page server reads 0, read-ahead reads 23, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimDate'. Scan count 1, logical reads 113, physical reads 1, page server reads 0, read-ahead reads 112, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 66 ms.
*/


/* Repeat last two steps as needed */
USE [ContosoRetailDW]
GO
--DROP INDEX [idx_ProcureSQL] ON [dbo].[DimProduct]
CREATE NONCLUSTERED INDEX [idx_ProcureSQL]
ON [dbo].[DimProduct] ([ProductName])

/* (20 rows affected)
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'FactOnlineSales'. Scan count 1, logical reads 24, physical reads 2, page server reads 0, read-ahead reads 21, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimProduct'. Scan count 1, logical reads 2, physical reads 2, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimStore'. Scan count 1, logical reads 24, physical reads 1, page server reads 0, read-ahead reads 23, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimDate'. Scan count 1, logical reads 113, physical reads 1, page server reads 0, read-ahead reads 112, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 83 ms.
   */

-- DROP INDEX idx_ProcureSQL ON dbo.DimDate
CREATE INDEX idx_ProcureSQL
ON dbo.DimDate (CalendarYear)
/*
(20 rows affected)
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'FactOnlineSales'. Scan count 1, logical reads 24, physical reads 2, page server reads 0, read-ahead reads 28, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimProduct'. Scan count 1, logical reads 2, physical reads 2, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimStore'. Scan count 1, logical reads 24, physical reads 1, page server reads 0, read-ahead reads 23, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'DimDate'. Scan count 1, logical reads 7, physical reads 1, page server reads 0, read-ahead reads 5, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 77 ms.

*/