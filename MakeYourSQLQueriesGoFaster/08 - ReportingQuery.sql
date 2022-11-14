USE [master]
GO
ALTER DATABASE [AdventureWorks2012] SET COMPATIBILITY_LEVEL = 130
GO

USE [AdventureWorks2012]
GO
/* Reporting Query */
/* 
DROP PROCEDURE dbo.UsersGoCrazy
DROP PROCEDURE dbo.UsersGoCrazy_Better
DROP PROCEDURE dbo.UsersGoCrazy_Bad
*/
CREATE PROCEDURE dbo.UsersGoCrazy
( 
@CustomerId INT = NULL,
@CustomerLastName NVARCHAR(50) = NULL,
@OrderDate DATETIME = NULL,
@ShipDate DATETIME = NULL,
@status  INT = NULL,
@ProductID INT = NULL
-- It keeps going, and going, and going.... 
)

AS
BEGIN 
	SET NOCOUNT ON;

	SELECT sode.SalesOrderID, sohe.CustomerID, sohe.OrderDate, sohe.DueDate, sohe.ShipDate --...
	FROM Sales.SalesOrderDetailEnlarged sode
	JOIN Sales.SalesOrderHeaderEnlarged sohe ON sode.SalesOrderID = sohe.SalesOrderID
	LEFT JOIN Sales.Customer c ON c.CustomerID = sohe.CustomerID
	LEFT JOIN Person.Person p ON p.BusinessEntityID = c.PersonID
	WHERE 1=1
	AND (p.LastName like @CustomerLastName or @CustomerLastName is NULL )
	AND sohe.CustomerID = COALESCE(@CustomerID, sohe.CustomerID)
	AND OrderDate = COALESCE(@OrderDate, OrderDate)
	AND (ShipDate = @ShipDate OR @ShipDate IS NULL or ShipDate is NULL) -- Nullable column
	AND [status] = COALESCE(@status, [status])
	AND ProductID = COALESCE(@ProductID, ProductID) 
END
GO

DBCC FREEPROCCACHE
SET STATISTICS IO, TIME ON

EXEC dbo.UsersGoCrazy @CustomerLastName ='Smith'
EXEC dbo.UsersGoCrazy @ShipDate = '2006-03-31', @CustomerID = 11624 

/* A little Better. Dynamic SQL is your friend! */
CREATE PROCEDURE dbo.UsersGoCrazy_Better
( 
@CustomerId INT = NULL,
@CustomerLastName NVARCHAR(50) = NULL,
@OrderDate DATETIME = NULL,
@ShipDate DATETIME = NULL,
@status  INT = NULL,
@ProductID INT = NULL
-- It keeps going, and going, and going.... 
)

AS
BEGIN 
	SET NOCOUNT ON;

DECLARE @select NVARCHAR(MAX) = N'/* UsersGoWild */ 
SELECT sode.SalesOrderID, sohe.CustomerID, sohe.OrderDate, sohe.DueDate, sohe.ShipDate '

DECLARE @from NVARCHAR(MAX) = N' FROM Sales.SalesOrderDetailEnlarged sode
	JOIN Sales.SalesOrderHeaderEnlarged sohe ON sode.SalesOrderID = sohe.SalesOrderID '
/* Only join extra tables if needed for filter */
IF @CustomerLastName IS NOT NULL
SET @from = @from + N' LEFT JOIN Sales.Customer c ON c.CustomerID = sohe.CustomerID
	 JOIN Person.Person p ON p.BusinessEntityID = c.PersonID '

DECLARE @filter NVARCHAR(MAX) = N' WHERE 1 = 1 '

IF @CustomerLastName IS NOT NULL
SET @filter = @filter + N' AND p.LastName like @CustomerLastName '

IF @CustomerID IS NOT NULL 
SET @filter += ' AND sohe.CustomerID = @CustomerID '

IF @OrderDate IS NOT NULL
SET @filter += ' AND OrderDate = @OrderDate, '

IF @ShipDate IS NOT NULL
SET @filter += ' AND (ShipDate = @ShipDate) '

IF @status IS NOT NULL 
SET @filter += '  AND [status] = @status '

IF @ProductID IS NOT NULL
SET @filter += ' AND ProductID = @ProductID '

DECLARE @SQL NVARCHAR(MAX) = @select + @from + @filter
PRINT @SQL

exec sp_executesql @SQL, N'@CustomerId INT, @CustomerLastName NVARCHAR(50), @OrderDate DATETIME, @ShipDate DATETIME, @status  INT,@ProductID INT',
@CustomerId,
@CustomerLastName,
@OrderDate,
@ShipDate,
@status,
@ProductID

END
GO

EXEC dbo.UsersGoCrazy_Better @CustomerLastName ='Smith'
EXEC dbo.UsersGoCrazy_Better @ShipDate = '2006-03-31', @CustomerID = 11624 



/* A worse query.  Please don't do this with Dynamic SQL 
Loose the benefit of paramertization 
Open yourself to SQL Injection aka drop bobby tables

*/
CREATE PROCEDURE dbo.UsersGoCrazy_Bad
( 
@CustomerId INT = NULL,
@CustomerLastName NVARCHAR(50) = NULL,
@OrderDate DATETIME = NULL,
@ShipDate DATETIME = NULL,
@status  INT = NULL,
@ProductID INT = NULL
-- It keeps going, and going, and going.... 
)

AS
BEGIN 
	SET NOCOUNT ON;

DECLARE @select NVARCHAR(MAX) = N'/* UsersGoWild */ 
SELECT sode.SalesOrderID, sohe.CustomerID, sohe.OrderDate, sohe.DueDate, sohe.ShipDate '

DECLARE @from NVARCHAR(MAX) = N' FROM Sales.SalesOrderDetailEnlarged sode
	JOIN Sales.SalesOrderHeaderEnlarged sohe ON sode.SalesOrderID = sohe.SalesOrderID '
/* Only join extra tables if needed for filter */
IF @CustomerLastName IS NOT NULL
SET @from = @from + N' LEFT JOIN Sales.Customer c ON c.CustomerID = sohe.CustomerID
	 JOIN Person.Person p ON p.BusinessEntityID = c.PersonID '

DECLARE @filter NVARCHAR(MAX) = N' WHERE 1 = 1 '

IF @CustomerLastName IS NOT NULL
SET @filter = @filter + N' AND p.LastName like ''' + @CustomerLastName + ''''

IF @CustomerID IS NOT NULL 
SET @filter += ' AND sohe.CustomerID = ' + CAST(@CustomerID AS NVARCHAR(20))

IF @OrderDate IS NOT NULL
SET @filter += ' AND OrderDate = ''' + CONVERT(CHAR(8), @OrderDate, 112 ) + ''''

IF @ShipDate IS NOT NULL
SET @filter += ' AND ShipDate = ''' + CONVERT(CHAR(8), @ShipDate, 112) + ''''

IF @status IS NOT NULL 
SET @filter += '  AND [status] = ''' + CAST(@status AS NVARCHAR(5)) +''''

IF @ProductID IS NOT NULL
SET @filter += ' AND ProductID = ' + CAST(@ProductID AS NVARCHAR(10))

DECLARE @SQL NVARCHAR(MAX) = @select + @from + @filter
PRINT @SQL

/* wide open for sql injection */
EXEC (@SQL)


END
GO

EXEC dbo.UsersGoCrazy_Bad @CustomerLastName ='Smith'
EXEC dbo.UsersGoCrazy_Bad @ShipDate = '2006-03-31', @CustomerID = 11624 

SET STATISTICS IO, TIME OFF