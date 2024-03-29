USE [AdventureWorks2012]
GO
set statistics io on
set statistics time on

CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
/* CTEs and Temp Tables */
USE AdventureWorks2012
go
;WITH	cteTotalSales (SalesPersonID, NetSales)
AS	(
	SELECT	e.SalesPersonID, ROUND(SUM(e.SubTotal), 2)
	FROM	Sales.SalesOrderHeaderEnlarged e
	WHERE	e.SalesPersonID IS NOT NULL
	GROUP	BY e.SalesPersonID
	)
select	*
from	cteTotalSales;

go
select	*
from	(
	SELECT	e.SalesPersonID, ROUND(SUM(e.SubTotal), 2) as NetSales
	FROM	Sales.SalesOrderHeaderEnlarged e
	WHERE	e.SalesPersonID IS NOT NULL
	GROUP	BY e.SalesPersonID
	) derivedTable_TotalSales

/*************************************************************************************

 In this query, we are looking for the net sales, order quantity, sales quota, 
 quota differential and average quantity per sale.
   
 We are using three CTEs.  The second and third reference the previous two.  
 The final query looks like a relatively simply join with four objects in the from clause.

*/

CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

;WITH	cteTotalSales (SalesPersonID, NetSales, OrderQty)
AS	(
	SELECT	e.SalesPersonID, ROUND(SUM(e.SubTotal), 2), sum(s.OrderQty) as OrderQty
	FROM	Sales.SalesOrderHeaderEnlarged e
		inner join sales.SalesOrderDetailEnlarged s on s.SalesOrderID = e.salesOrderID
	WHERE	e.SalesPersonID IS NOT NULL
		and s.ModifiedDate >= '2007-01-01'
	GROUP	BY e.SalesPersonID
	),
cteTargetDiff (SalesPersonID, SalesQuota, QuotaDiff, OrderQty)
AS
	(
	SELECT	ts.SalesPersonID,
		CASE
			WHEN sp.SalesQuota IS NULL THEN 0
			ELSE sp.SalesQuota
		END,
		CASE
			WHEN sp.SalesQuota IS NULL THEN ts.NetSales
			ELSE ts.NetSales - sp.SalesQuota
		END,
		ts.OrderQty
	FROM	cteTotalSales AS ts
		INNER JOIN Sales.SalesPerson AS sp ON ts.SalesPersonID = sp.BusinessEntityID
	),
ctePerUnit(avg_qty_per_sale, SalesPersonID)
As
	(
	select	NetSales/OrderQty, SalesPersonID
	from	cteTotalSales
	)
SELECT	sp.FirstName + ' ' + sp.LastName AS FullName	,
	sp.City						,
	ts.NetSales					,
	ts.OrderQty					,
	pu.avg_qty_per_sale				,
	td.SalesQuota					,
	td.QuotaDiff
FROM	Sales.vSalesPerson AS sp
	INNER JOIN cteTotalSales AS ts ON sp.BusinessEntityID = ts.SalesPersonID
	INNER JOIN cteTargetDiff AS td ON sp.BusinessEntityID = td.SalesPersonID
	INNER JOIN ctePerUnit as pu on pu.SalesPersonID = ts.SalesPersonID
ORDER	BY ts.NetSales DESC

CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

/* --------- Using Table Variables ---------------- */
declare	@totalSales table
	(
	SalesPersonID		int	,
	NetSales		money	,
	OrderQty		bigInt
	)

declare	@TargetDiff table
	(
	SalesPersonID		int 	,
	SalesQuota		money	,
	QuotaDiff		money		
	)

declare	@perUnit table
	(
	Qty_Sales		money	,
	SalesPersonID		int
	)



insert	into @totalSales(SalesPersonID, NetSales, OrderQty)
SELECT	e.SalesPersonID, ROUND(SUM(e.SubTotal), 2), sum(s.OrderQty) as OrderQty
FROM	Sales.SalesOrderHeaderEnlarged e
	inner join sales.SalesOrderDetailEnlarged s on s.SalesOrderID = e.salesOrderID
WHERE	e.SalesPersonID IS NOT NULL
	and s.ModifiedDate >= '2007-01-01'
GROUP	BY e.SalesPersonID
	


insert	into @targetDiff(SalesPersonID, SalesQuota, QuotaDiff)
SELECT	ts.SalesPersonID,
	CASE
		WHEN sp.SalesQuota IS NULL THEN 0
		ELSE sp.SalesQuota
	END,
	CASE
		WHEN sp.SalesQuota IS NULL THEN ts.NetSales
		ELSE ts.NetSales - sp.SalesQuota
	END
FROM	@totalSales AS ts
	INNER JOIN Sales.SalesPerson AS sp ON ts.SalesPersonID = sp.BusinessEntityID
	


insert	into @perUnit(Qty_Sales, SalesPersonID)
select	NetSales/OrderQty, SalesPersonID
from	@totalSales
	


SELECT	sp.FirstName + ' ' + sp.LastName AS FullName	,
	sp.City						,
	ts.NetSales					,
	ts.OrderQty					,
	pu.Qty_Sales					,
	td.SalesQuota					,
	td.QuotaDiff
FROM	Sales.vSalesPerson AS sp
	INNER JOIN @totalSales AS ts ON sp.BusinessEntityID = ts.SalesPersonID
	INNER JOIN @targetDiff AS td ON sp.BusinessEntityID = td.SalesPersonID
	inner join @perUnit as pu on pu.SalesPersonID = ts.SalesPersonID
ORDER	BY ts.NetSales DESC


CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

/**** Temp Table Solution ****/

if	object_id('tempdb..#totalSales') is not null
	drop	table #totalSales

create	table #totalSales
	(
	SalesPersonID		int 	,
	NetSales		money	,
	OrderQty		bigint
	)

create	clustered index #ix#totalSales on #totalSales(SalesPersonID)


if	object_id('tempdb..#targetDiff') is not null
	drop	table #targetDiff


create	table #targetDiff
	(
	SalesPersonID		int	,
	SalesQuota		money	,
	QuotaDiff		money
	)

create	clustered index #ix#targetDiff on #targetDiff(SalesPersonID)

if	object_id('tempdb..#perUnit') is not null
	drop	table #perUnit

create	table #perUnit
	(
	Qty_Sales		money	,
	SalesPersonID		int
	)

create	clustered index #ix#perUnit on #perUnit(SalesPersonID)


insert	into #totalSales(SalesPersonID, NetSales, OrderQty)
SELECT	e.SalesPersonID, ROUND(SUM(e.SubTotal), 2), sum(s.OrderQty) as OrderQty
FROM	Sales.SalesOrderHeaderEnlarged e
	inner join sales.SalesOrderDetailEnlarged s on s.SalesOrderID = e.salesOrderID
WHERE	e.SalesPersonID IS NOT NULL
	and s.ModifiedDate >= '2007-01-01'
GROUP	BY e.SalesPersonID
	


insert	into #targetDiff(SalesPersonID, SalesQuota, QuotaDiff)
SELECT	ts.SalesPersonID,
	CASE
		WHEN sp.SalesQuota IS NULL THEN 0
		ELSE sp.SalesQuota
	END,
	CASE
		WHEN sp.SalesQuota IS NULL THEN ts.NetSales
		ELSE ts.NetSales - sp.SalesQuota
	END
FROM	#totalSales AS ts
	INNER JOIN Sales.SalesPerson AS sp ON ts.SalesPersonID = sp.BusinessEntityID
	

insert	into #perUnit(Qty_Sales, SalesPersonID)
select	NetSales/OrderQty, SalesPersonID
from	#totalSales
	


SELECT	sp.FirstName + ' ' + sp.LastName AS FullName	,
	sp.City						,
	ts.NetSales					,
	ts.OrderQty					,
	pu.Qty_Sales					,
	td.SalesQuota					,
	td.QuotaDiff
FROM	Sales.vSalesPerson AS sp
	INNER JOIN #totalSales AS ts ON sp.BusinessEntityID = ts.SalesPersonID
	INNER JOIN #targetDiff AS td ON sp.BusinessEntityID = td.SalesPersonID
	inner join #perUnit as pu on pu.SalesPersonID = ts.SalesPersonID
ORDER	BY ts.NetSales DESC
