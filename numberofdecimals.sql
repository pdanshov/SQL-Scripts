SELECT  transid,pmtamt,*,
LEN(CAST(REVERSE(SUBSTRING(STR(pmtamt, 13, 11), CHARINDEX('.', STR(pmtamt, 13, 11)) + 1, 20)) 
AS decimal))  from tblSoTransPmt
where 
LEN(CAST(REVERSE(SUBSTRING(STR(pmtamt, 13, 11), CHARINDEX('.', STR(pmtamt, 13, 11)) + 1, 20)) 
AS decimal)) >2