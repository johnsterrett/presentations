USE [AdventureWorks2012]
GO

set statistics io on

-- Implicit Conversion because of like compare with integer
-- Forces full scan to convert all SalesOrderID values to a string for like compare.

exec sp_help '[Sales].[SalesOrderDetail]'

SELECT CarrierTrackingNumber, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, LineTotal
FROM [Sales].[SalesOrderDetail] sod
WHERE [SalesOrderID] like '43659'

SELECT CarrierTrackingNumber, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, LineTotal
FROM [Sales].[SalesOrderDetail] sod
WHERE [SalesOrderID] = 43659

/* Note in the index seek the optimizer converted the filter for you */
SELECT CarrierTrackingNumber, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, LineTotal
FROM [Sales].[SalesOrderDetail] sod
WHERE [SalesOrderID] = '43659'

