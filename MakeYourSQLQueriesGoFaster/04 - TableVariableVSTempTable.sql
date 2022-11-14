USE [master]
GO
ALTER DATABASE [AdventureWorks2012] SET COMPATIBILITY_LEVEL = 130
GO
USE [AdventureWorks2012]
GO

SET STATISTICS IO ON
SET NOCOUNT ON
GO

/* Clear plans and data pages from memory to get cold start */
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

/*************************** Table variable *********************************************/
/* Can you have clustered indexes on table variables? */
DECLARE @Carriers TABLE
(
	CarrierTrackingNumber NVARCHAR(25) PRIMARY KEY CLUSTERED
)
INSERT INTO @Carriers(CarrierTrackingNumber)
SELECT DISTINCT TOP 1000 CarrierTrackingNumber
FROM Sales.SalesOrderDetailEnlarged 
WHERE CarrierTrackingNumber IS NOT NULL

SELECT d.CarrierTrackingNumber 
FROM Sales.SalesOrderDetailEnlarged d
JOIN @Carriers c ON d.CarrierTrackingNumber = c.CarrierTrackingNumber 
WHERE d.ProductID = 776
GO

/************************ Table Variable Option Recompile ******************************/
DECLARE @Carriers TABLE
(
	CarrierTrackingNumber NVARCHAR(25) PRIMARY KEY CLUSTERED
)
INSERT INTO @Carriers(CarrierTrackingNumber)
SELECT DISTINCT TOP 1000 CarrierTrackingNumber
FROM Sales.SalesOrderDetail
WHERE CarrierTrackingNumber IS NOT NULL

SELECT d.CarrierTrackingNumber 
FROM Sales.SalesOrderDetailEnlarged d
JOIN @Carriers c ON d.CarrierTrackingNumber = c.CarrierTrackingNumber 
WHERE d.ProductID = 776
OPTION(RECOMPILE);

/********************Temp Table Example vs Table Variabe *************************************/
IF OBJECT_ID('tempdb..#Carriers') IS NOT NULL
DROP TABLE #Carriers
GO
CREATE TABLE #Carriers(CarrierTrackingNumber NVARCHAR(25) COLLATE SQL_Latin1_General_CP1_CI_AS PRIMARY KEY CLUSTERED )

INSERT INTO #Carriers(CarrierTrackingNumber)
SELECT DISTINCT TOP 1000 CarrierTrackingNumber
FROM Sales.SalesOrderDetail 
WHERE CarrierTrackingNumber IS NOT NULL

SELECT d.CarrierTrackingNumber 
FROM Sales.SalesOrderDetail d
JOIN #Carriers c ON d.CarrierTrackingNumber = c.CarrierTrackingNumber 
WHERE d.ProductID = 776

GO

/* 

Lets see how SQL 2019 Table variable deferred compilation
changes our execution plan and statistics 
*/
USE [master]
GO
ALTER DATABASE [AdventureWorks2012] SET COMPATIBILITY_LEVEL = 150
GO
USE [AdventureWorks2012]
GO

SET STATISTICS IO ON
SET NOCOUNT ON
GO

/* Clear plans and data pages from memory to get cold start */
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

DECLARE @Carriers TABLE
(
	CarrierTrackingNumber NVARCHAR(25) PRIMARY KEY CLUSTERED
)
INSERT INTO @Carriers(CarrierTrackingNumber)
SELECT DISTINCT TOP 1000 CarrierTrackingNumber
FROM Sales.SalesOrderDetail
WHERE CarrierTrackingNumber IS NOT NULL

SELECT d.CarrierTrackingNumber 
FROM Sales.SalesOrderDetail d
JOIN @Carriers c ON d.CarrierTrackingNumber = c.CarrierTrackingNumber 
WHERE d.ProductID = 776
GO
/* Yes, you can turn off deferred Compilation as well */
ALTER DATABASE SCOPED CONFIGURATION SET DEFERRED_COMPILATION_TV = OFF;

ALTER DATABASE SCOPED CONFIGURATION SET DEFERRED_COMPILATION_TV = ON;

/* Can turn off with query hint as well */
/* Clear plans and data pages from memory to get cold start */
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

DECLARE @Carriers TABLE
(
	CarrierTrackingNumber NVARCHAR(25) PRIMARY KEY CLUSTERED
)
INSERT INTO @Carriers(CarrierTrackingNumber)
SELECT DISTINCT TOP 1000 CarrierTrackingNumber
FROM Sales.SalesOrderDetail
WHERE CarrierTrackingNumber IS NOT NULL

SELECT d.CarrierTrackingNumber 
FROM Sales.SalesOrderDetail d
JOIN @Carriers c ON d.CarrierTrackingNumber = c.CarrierTrackingNumber 
WHERE d.ProductID = 776
OPTION (USE HINT('DISABLE_DEFERRED_COMPILATION_TV'));
