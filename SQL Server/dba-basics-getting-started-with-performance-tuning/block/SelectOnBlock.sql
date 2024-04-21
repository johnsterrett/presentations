USE [ContosoRetailDW]
GO

SELECT TOP 100 [StoreKey], [ProductKey], [PromotionKey],[SalesOrderNumber], [SalesOrderLineNumber], [TotalCost]
  FROM [ContosoRetailDW].[dbo].[FactOnlineSales]
  WHERE DateKey = '2007-01-01 00:00:00.000'


