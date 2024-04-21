USE [AdventureWorks2012]
GO

/*
Query is adapted from BOL example provided at the link below..
https://docs.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sql-server-ver15
*/
--12 sec --
CREATE INDEX idx_ProcureSQL on [Sales].[SalesOrderDetailEnlarged]  (ProductId)
INCLUDE (LineTotal)

CREATE OR ALTER FUNCTION dbo.ProductCategory(@ProductId INT) 
RETURNS CHAR(10) AS
BEGIN
  DECLARE @Total DECIMAL(18,2);
  DECLARE @category CHAR(10);

  SELECT @Total = SUM(LineTotal) FROM [Sales].[SalesOrderDetailEnlarged] 
  WHERE ProductID = @ProductId;

  IF @Total IS NULL OR @Total = 0
  SET @category = NULL
  ELSE IF @Total < 500000
    SET @category = 'REGULAR';
  ELSE IF @Total < 1000000
    SET @category = 'GOLD';
  ELSE 
    SET @category = 'PLATINUM';

  RETURN @category;
END



/* (202 rows affected)
Table 'SalesOrderDetailEnlarged'. Scan count 706, logical reads 40373, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Product'. Scan count 1, logical reads 15, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 2110 ms,  elapsed time = 2142 ms.
   */
select p.Name, p.ProductNumber, dbo.ProductCategory(p.ProductId) AS Category
from Production.Product p
WHERE dbo.ProductCategory(p.ProductId) = 'PLATINUM'
ORDER BY Name
OPTION (USE HINT ('DISABLE_TSQL_SCALAR_UDF_INLINING'))

select p.Name, p.ProductNumber, dbo.ProductCategory(p.ProductId) AS Category
from Production.Product p
WHERE dbo.ProductCategory(p.ProductId) = 'PLATINUM'
ORDER BY Name

/* fix with doing set based operations */
 ;with cte as (SELECT ProductID, SUM(LineTotal) Total
 FROM [Sales].[SalesOrderDetailEnlarged] 
 GROUP BY ProductID)
 
 select p.Name, p.ProductNumber, 'PLATINUM' AS Category
 from cte
 JOIN Production.Product p on cte.ProductID = p.ProductID
 where Total >= CAST ( 1000000 AS DECIMAL(18,2)) 
 ORDER BY name 
 /*
 (202 rows affected)
Table 'SalesOrderDetailEnlarged'. Scan count 3, logical reads 21255, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Product'. Scan count 0, logical reads 404, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 2390 ms,  elapsed time = 1505 ms.
 */


 /* Cleanup */
DROP INDEX IF EXISTS idx_ProcureSQL on [Sales].[SalesOrderDetailEnlarged]