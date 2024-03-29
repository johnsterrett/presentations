/****** Running Totals ******

ONLY USE ESTIMATE PLANS not ACTUAL will take too long

*/
SELECT 
    
	  [TransactionID],
       [ActualCost]
  FROM [AdventureWorks2012].[Production].[TransactionHistory] th
  WHERE ActualCost > 0
  
/* -- Takes too long for presentation ;-(
  CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
*/
  SELECT t1.[TransactionID], t1.[ActualCost], RunningTotal = SUM(t2.[ActualCost])
FROM [AdventureWorks2012].[Production].[TransactionHistory] AS t1 
JOIN [AdventureWorks2012].[Production].[TransactionHistory] AS t2
  ON t1.[TransactionID] >= t2.[TransactionID]
  WHERE t1.ActualCost > 0
  AND t1.TransactionID < 120000
GROUP BY t1.[TransactionID], t1.[ActualCost]
ORDER BY t1.[TransactionID]

/*
(14575 row(s) affected)
Table 'TransactionHistory'. Scan count 14578, logical reads 998686, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 24828 ms,  elapsed time = 16362 ms.
*/

CHECKPOINT
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

/* 
Running totals before SQL Server 2012.
Yes, your DBA might be wrong about cursors ;-)

*/

CREATE TABLE #tmpTbl
(
  TransactionId INT PRIMARY KEY, 
  ActualCost INT, 
  RunningTotal BIGINT
);

INSERT #tmpTbl(TransactionId, ActualCost) 
  SELECT TransactionId, ActualCost
  FROM [AdventureWorks2012].[Production].[TransactionHistory]
  WHERE ActualCost > 0
  AND TransactionID < 120000 
  ORDER BY TransactionId;

DECLARE @RunningTotal INT, @TransactionId INT, @ActualCost INT;
SET @RunningTotal = 0;

DECLARE c CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
  FOR SELECT TransactionId, ActualCost FROM #tmpTbl ORDER BY TransactionId;

OPEN c;

FETCH c INTO @TransactionId, @ActualCost;

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @RunningTotal = @RunningTotal + @ActualCost;
  UPDATE #tmpTbl SET RunningTotal = @RunningTotal WHERE TransactionId = @TransactionId;
  FETCH c INTO @TransactionId, @ActualCost;
END

CLOSE c; DEALLOCATE c;

SELECT TransactionId, ActualCost, RunningTotal = RunningTotal 
  FROM #tmpTbl 
  ORDER BY TransactionId;

DROP TABLE #tmpTbl;

/* SQL Server 2012+ better way using Windows functions */



SELECT TransactionId, ActualCost, 
  RunningTotal = SUM(ActualCost) OVER (ORDER BY TransactionId)
FROM [AdventureWorks2012].[Production].[TransactionHistory]
 WHERE ActualCost > 0
  AND TransactionID < 120000
ORDER BY TransactionId;

/* 
(14575 row(s) affected)
Table 'Worktable'. Scan count 14576, logical reads 87723, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'TransactionHistory'. Scan count 1, logical reads 142, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 172 ms,  elapsed time = 309 ms.



SELECT TransactionId, ActualCost, 
  RunningTotal = SUM(ActualCost) OVER (ORDER BY TransactionId ROWS UNBOUNDED PRECEDING)
FROM [AdventureWorks2012].[Production].[TransactionHistory]
 WHERE ActualCost > 0
  AND TransactionID < 121626 
ORDER BY TransactionId;
*/
  
 