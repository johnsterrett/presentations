USE [master]
GO
ALTER DATABASE [AdventureWorks2012] SET COMPATIBILITY_LEVEL = 150
GO

USE [AdventureWorks2012]
GO
/* How things worked before 2019 */
ALTER DATABASE SCOPED CONFIGURATION SET TSQL_SCALAR_UDF_INLINING = OFF;

select @@SPID
/*
CleanUp
DROP FUNCTION GetMaxProductQty_Scalar
DROP FUNCTION GetMaxProductQty_Inline
*/
set statistics io on
set statistics time on
GO


CREATE OR ALTER FUNCTION GetMaxProductQty_Scalar
(
    @ProductId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @maxQty INT

    SELECT @maxQty = MAX(sod.OrderQty)
    FROM Sales.SalesOrderDetailEnlarged sod
    WHERE sod.ProductId = @ProductId

    RETURN (@maxQty)
END

/* Clear all pages from memory
WARNING: Do not do this in production..
This gives us a senario where no pages or plans are in memory. */
CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;


/* TODO: LOAD PROFILER - Show ROW BY ROW Function Calls */
/* Row By Row Processing - Scalar Function */
 SELECT
    ProductId,
    dbo.GetMaxProductQty_Scalar(ProductId) As MaxQty
FROM Production.Product
ORDER BY 2 DESC
OPTION (USE HINT ('DISABLE_TSQL_SCALAR_UDF_INLINING'))

/* Where is function calls? Didn't we also hit SalesOrderDetailEnlarged?

(504 row(s) affected)
Table 'Product'. Scan count 1, logical reads 4, physical reads 1, read-ahead reads 2, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 25109 ms,  elapsed time = 29721 ms.
*/

/* Lets do it again but now turn on UDF Inlining */
ALTER DATABASE SCOPED CONFIGURATION SET TSQL_SCALAR_UDF_INLINING = ON;

/* Can our function be inlineable? 
https://docs.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sql-server-ver15
*/
 select o.name, m.is_inlineable 
 from sys.sql_modules m
 join sys.objects o on m.object_id = o.object_id
 where 1=1
 and o.name like 'GetMaxProductQty_Scalar'

 /* Clear all pages from memory
WARNING: Do not do this in production..
This gives us a senario where no pages or plans are in memory. */
CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SELECT
    ProductId,
    dbo.GetMaxProductQty_Scalar(ProductId) As MaxQty
FROM Production.Product
ORDER BY 2 DESC

/* 
	Notice we are scanning our SalesOrderDetailEnlarged table for every
   single record in Products? Yikes....

   (504 rows affected)
Table 'Worktable'. Scan count 504, logical reads 14,578,424, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'SalesOrderDetailEnlarged'. Scan count 1, logical reads 73,544, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Product'. Scan count 1, logical reads 4, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 17515 ms,  elapsed time = 17762 ms.
*/
GO

CREATE OR ALTER FUNCTION GetMaxProductQty_Inline
(
    @ProductId INT
)
RETURNS TABLE
AS
    RETURN
    (
        SELECT MAX(sode.OrderQty) AS maxqty
        FROM Sales.SalesOrderDetailEnlarged sode
        WHERE sode.ProductId = @ProductId
    )
GO

CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

/*
WHAT is APPLY?
https://technet.microsoft.com/en-us/library/ms175156(v=sql.105).aspx
The APPLY operator allows you to invoke a table-valued function 
for each row returned by an outer table expression of a query. 
The table-valued function acts as the right input and the outer 
table expression acts as the left input. The right input is 
evaluated for each row from the left input and the rows produced 
are combined for the final output. 
*/

SELECT  p.ProductId,
		tvf.MaxQty
FROM Production.Product p
CROSS APPLY dbo.GetMaxProductQty_Inline(p.ProductId) tvf
ORDER BY 2 DESC


/*
(504 row(s) affected)
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'SalesOrderDetailEnlarged'. Scan count 3, logical reads 74170, physical reads 0, read-ahead reads 5, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Product'. Scan count 3, logical reads 40, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 2811 ms,  elapsed time = 1844 ms.

*/



CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

/* In this case, we can just join against the two tables */
SELECT p.ProductId, MAX(sod.OrderQty)
FROM Sales.SalesOrderDetailEnlarged sod
RIGHT JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.ProductID
ORDER BY 2 DESC

/* (504 row(s) affected)
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'SalesOrderDetailEnlarged'. Scan count 3, logical reads 74066, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Product'. Scan count 3, logical reads 40, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

*/
/* Index to improve - If you are using SQL 2016 CU1 or greater
Standard edition includeds compression.
*/
CREATE NONCLUSTERED INDEX idx_SalesOrderDE_ProductID_Include1 
on Sales.SalesOrderDetailEnlarged (ProductID)
INCLUDE (OrderQty) WITH (ONLINE=ON, DATA_COMPRESSION = ROW)

CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SELECT  ProductId,
		MaxQty
FROM Production.Product
CROSS APPLY dbo.GetMaxProductQty_Inline(ProductId) MaxQty
ORDER BY 2 DESC

/* Saved 7x on Reads from SalesOrderDetailEnlarged
(504 row(s) affected)
Table 'Product'. Scan count 3, logical reads 40, physical reads 1, read-ahead reads 14, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'SalesOrderDetailEnlarged'. Scan count 3, logical reads 10324, physical reads 1, read-ahead reads 10415, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
*/


/* Index to improve - Columnstore Index */
CREATE NONCLUSTERED COLUMNSTORE INDEX nccidx_SalesOrderDE on Sales.SalesOrderDetailEnlarged (ProductID, OrderQty)


CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SELECT  ProductId,
		MaxQty
FROM Production.Product
CROSS APPLY dbo.GetMaxProductQty_Inline(ProductId) MaxQty
ORDER BY 2 DESC

/*
(504 row(s) affected)
Table 'SalesOrderDetailEnlarged'. Scan count 2, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 319, lob physical reads 4, lob read-ahead reads 12.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Product'. Scan count 3, logical reads 7, physical reads 1, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row(s) affected)

 SQL Server Execution Times:
   CPU time = 31 ms,  elapsed time = 159 ms.
*/

/* ----------> CLEANUP <----------- */

DROP INDEX IF EXISTS idx_SalesOrderDE_ProductID_Include1 on Sales.SalesOrderDetailEnlarged

/* Index to improve */
DROP INDEX IF EXISTS nccidx_SalesOrderDE on Sales.SalesOrderDetailEnlarged 