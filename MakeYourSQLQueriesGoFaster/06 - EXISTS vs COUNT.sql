USE [AdventureWorks2012]
GO

SET STATISTICS IO ON

DECLARE @ID BIGINT
SELECT @ID = COUNT(*)
FROM Sales.SalesOrderDetailEnlarged sode
WHERE sode.OrderQty = 1

IF @ID > 0
	PRINT 'Records Exist'

/* How about TOP 1? */
DECLARE @ID BIGINT
SELECT TOP 1 @ID = COUNT(*)
FROM Sales.SalesOrderDetailEnlarged sode
WHERE sode.OrderQty = 1

IF @ID > 0
	PRINT 'Records Exist'




IF EXISTS ( SELECT 1
			FROM Sales.SalesOrderDetailEnlarged sode
			WHERE sode.OrderQty = 1)
BEGIN
	PRINT 'Records Exist'
END

/* How about TOP 1 without count? */
DECLARE @ID BIGINT
SELECT TOP 1 @ID = SalesOrderDetailID
FROM Sales.SalesOrderDetailEnlarged sode
WHERE sode.OrderQty = 1

IF @ID > 0
	PRINT 'Records Exist'