USE ContosoRetailDW
GO
BEGIN TRANSACTION 
UPDATE TOP (100) [ContosoRetailDW].[dbo].[FactOnlineSales]
SET [DiscountQuantity] += 2
  FROM [ContosoRetailDW].[dbo].[FactOnlineSales]
  WHERE DateKey = '2007-01-01 00:00:00.000'

   WAITFOR DELAY '00:00:00.50' 

  SELECT TOP 10 * FROM  [ContosoRetailDW].[dbo].[FactSales]
  WHERE DateKey = '2007-01-01 00:00:00.000'


  --ROLLBACK
