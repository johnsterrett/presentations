USE [ContosoRetailDW]
GO

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
--SET STATISTICS TIME OFF
--SET STATISTICS IO OFF