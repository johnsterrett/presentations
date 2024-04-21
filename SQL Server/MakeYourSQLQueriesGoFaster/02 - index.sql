USE [AdventureWorks2012]
GO

/****** Object:  Index [idx_SalesOrderDE_ProductID_Include1]    Script Date: 5/12/2022 5:03:08 PM ******/
DROP INDEX [idx_SalesOrderDE_ProductID_Include1] ON [Sales].[SalesOrderDetailEnlarged]
GO

/****** Object:  Index [idx_SalesOrderDE_ProductID_Include1]    Script Date: 5/12/2022 5:03:09 PM ******/
CREATE NONCLUSTERED INDEX [idx_SalesOrderDE_ProductID_Include1] ON [Sales].[SalesOrderDetailEnlarged]
(
	[ProductID] ASC
)
INCLUDE([OrderQty]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO


