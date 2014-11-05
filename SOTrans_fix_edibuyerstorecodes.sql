SELECT cf_EdiBuyerCode, cf_EdiShipToCode,CustPONum,* FROM trav_tblSoTransHeader_view where CustId='7441' and
cf_EdiShipToCode <> cf_EdiBuyerCode

update h SET cf=dbo.fncUpdateCustomField(cf, 'EdiShiptoCode', v.cf_EdiBuyerCode) 
---SELECT v.*
FROM tblSoTransHeader h 
INNER JOIN trav_tblSoTransHeader_view v ON h.transid=v.transid
WHERE v.cf_EdiShipToCode <> v.cf_EdiBuyerCode AND v.CustID='7441'