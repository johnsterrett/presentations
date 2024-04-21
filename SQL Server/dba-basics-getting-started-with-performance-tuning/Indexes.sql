USE [ContosoRetailDW]
GO

/****** Object:  Index [idx_ProcureSQL]    Script Date: 11/9/2021 7:34:38 PM ******/
DROP INDEX [idx_ProcureSQL] ON [dbo].[DimDate]
GO

/****** Object:  Index [idx_ProcureSQL]    Script Date: 11/9/2021 7:33:48 PM ******/
DROP INDEX [idx_ProcureSQL] ON [dbo].[DimProduct]
GO


/****** Object:  Index [idx_FactOnlineSales_ProductName]    Script Date: 11/9/2021 7:35:28 PM ******/
DROP INDEX [idx_FactOnlineSales_ProductName] ON [dbo].[FactOnlineSales]
GO





USE [ContosoRetailDW]
GO

/****** Object:  Index [idx_FactOnlineSales_ProductName]    Script Date: 11/9/2021 7:35:28 PM ******/
CREATE NONCLUSTERED INDEX [idx_FactOnlineSales_ProductName] ON [dbo].[FactOnlineSales]
(
	[ProductKey] ASC
)
INCLUDE([SalesQuantity],[SalesAmount],[DateKey],[StoreKey]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO
/****** Object:  Index [idx_ProcureSQL]    Script Date: 11/9/2021 7:34:38 PM ******/
CREATE NONCLUSTERED INDEX [idx_ProcureSQL] ON [dbo].[DimDate]
(
	[CalendarYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [idx_ProcureSQL]    Script Date: 11/9/2021 7:33:48 PM ******/
CREATE NONCLUSTERED INDEX [idx_ProcureSQL] ON [dbo].[DimProduct]
(
	[ProductName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

