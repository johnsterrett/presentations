USE [AdventureWorks2012]
GO
DBCC FREEPROCCACHE
SET STATISTICS IO ON
/* 
IF NOT EXISTS (SELECT 1 FROM sys.indexes where name like 'idx_SalesOrderDetail_ModifiedDate')
	CREATE NONCLUSTERED INDEX [idx_SalesOrderDetail_ModifiedDate]
	ON [Sales].[SalesOrderDetail] ([ModifiedDate])
IF NOT EXISTS (SELECT 1 FROM sys.indexes where name like 'idx_SalesOrderDetailEnlarged_ModifiedDate')
	CREATE NONCLUSTERED INDEX [idx_SalesOrderDetailEnlarged_ModifiedDate]
	ON [Sales].[SalesOrderDetailEnlarged] ([ModifiedDate])
*/

/**************************************************************************************/
SELECT LastName, FirstName, MiddleName
FROM [Person].[Person]
WHERE LastName LIKE '%SMITH%'

SELECT LastName, FirstName, MiddleName
FROM [Person].[Person]
WHERE LastName LIKE 'SMI%'

/**************************************************************************************/

SELECT LastName, FirstName, MiddleName  --NVARCHAR(50)
FROM [Person].[Person]
WHERE SUBSTRING(LastName, 1,1) =N'S'

SELECT LastName, FirstName, MiddleName
FROM [Person].[Person]
WHERE LastName LIKE N'S%'

/**************************************************************************************/

GO
SELECT GETDATE()
SELECT CONVERT(VARCHAR(10), GETDATE(), 101) 


SELECT COUNT(*) --ModifiedDate -- DATETIME
FROM Sales.SalesOrderDetailEnlarged c
WHERE CAST(CONVERT(VARCHAR(10), ModifiedDate, 101) AS DATETIME) = '7/27/2008'

SELECT COUNT(*) -- DATETIME
FROM Sales.SalesOrderDetailEnlarged c
WHERE CAST(ModifiedDate AS DATE) = '7/27/2008'

/**************************************************************************************/

SELECT COUNT(*)  --DATETIME
FROM Sales.SalesOrderDetailEnlarged s
WHERE ModifiedDate >= '7/27/2008' AND ModifiedDate < '7/28/2008'


--same result?
SELECT COUNT(*)
FROM Sales.SalesOrderDetailEnlarged s
WHERE ModifiedDate BETWEEN '7/27/2008' AND '2008-07-28 00:00:00.000'

/**************************************************************************************/

SELECT COUNT(*)  --DATETIME
FROM Sales.SalesOrderDetailEnlarged s
WHERE YEAR(ModifiedDate) = '2008'

SELECT COUNT(*)
FROM Sales.SalesOrderDetailEnlarged s
WHERE ModifiedDate >= '1/1/2008' AND ModifiedDate < '1/1/2009'

/**************************************************************************************/

SELECT COUNT(*) --DATETIME
FROM Sales.SalesOrderDetail s
WHERE DATEADD(YEAR, 6, ModifiedDate) < '7/02/2011'

SELECT COUNT(*)
FROM Sales.SalesOrderDetail s
WHERE ModifiedDate < DATEADD(YEAR, -6, '7/02/2011')

----------------------------------------------------------------------------------------
SELECT SalesOrderId -- INT
FROM Sales.SalesOrderHeaderEnlarged
WHERE COALESCE(SalesOrderId, 43662) = 43662

SELECT SalesOrderId
FROM Sales.SalesOrderHeaderEnlarged
WHERE ISNULL(SalesOrderId, 43662) = 43662

SELECT SalesOrderId 
FROM Sales.SalesOrderHeaderEnlarged
WHERE SalesOrderId IS NULL OR SalesOrderId  = 43662


----------------------------------------------------------------------------------------
/* Look at PlanCache_ImplicitConversions */
SELECT AddressLine1  --NVARCHAR(60)
FROM Person.[Address]
WHERE AddressLine1 = CAST('1, place Beaubernard' AS VARCHAR(60))
GO
---------------------------------------------------------------
SELECT AccountNumber --VARCHAR(10)
FROM Sales.Customer
WHERE AccountNumber = CAST(N'AW00000164' AS NVARCHAR(10))
GO

SELECT AccountNumber --VARCHAR(10)
FROM Sales.Customer
WHERE AccountNumber = CAST('AW00000164' AS VARCHAR(10))
GO