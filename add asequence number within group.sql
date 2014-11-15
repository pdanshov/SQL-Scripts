
-- add asequence number to the file (within group )  

update dbo.tblArOpenInvoice set Dup=''

UPDATE A 
SET Dup= Cnt
FROM dbo.tblArOpenInvoice A 
	INNER JOIN ( SELECT T1.Counter, Cnt = Count(*)
		     FROM dbo.tblArOpenInvoice T1
		     	INNER JOIN dbo.tblArOpenInvoice T2 
			ON T1.CustId+T1.InvcNum = T2.CustId+T2.InvcNum 
				and T1.RecType = T1.RecType
				and T1.Amt = T2.Amt
				AND T1.Counter >= T2.Counter
		     GROUP BY T1.Counter
		   ) B 
	ON A.Counter = B.Counter
where RecType = 1



select Counter,CustId,InvcNum,Dup,TransDate,Amt
from dbo.tblArOpenInvoice
where RecType=1 
	and CustId+InvcNum in (select CustId+InvcNum from dbo.tblArOpenInvoice where Dup=2)
	--and CustId='M5000'
order by CustId, InvcNum, Dup


