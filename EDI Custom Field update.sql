SELECT cf_EdiBuyerCode, cf_EdiShipToCode,CustPONum,PostRun,* FROM trav_tblArHistHeader_View where CustId='7441' and
cf_EdiShipToCode <> cf_EdiBuyerCode

update tblArHistHeader set cf=dbo.fncUpdateCustomField(cf, 'EdiShiptoCode', '0078742030272') 
where CustPoNum='6353990983' and CustId='7441'

SELECT * FROM tblEdPoHistDetail where CustPoNum='3852548498'
0078742031262

update h SET cf=dbo.fncUpdateCustomField(cf, 'EdiBuyerCode', v.cf_EdiShiptoCode) 
---SELECT v.*
FROM tblArHistHeader h 
INNER JOIN trav_tblArHistHeader_view v ON h.PostRun=v.postrun and h.transid=v.transid
WHERE v.cf_EdiShipToCode <> v.cf_EdiBuyerCode AND v.CustID='7441'



