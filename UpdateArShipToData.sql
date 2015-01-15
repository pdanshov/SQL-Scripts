


-----------------------------------------------------------------------------
--
--								Peter Danshov
--					pdanshv@gmail.com		01.12.2015
--		This script updates tblEdPartnerItemXRef from Trav10.5 Data
--
--
--	 Joe Greenberg:
--		First run the attached script to create the SQL function that allows
--		you to update custom fields. ( fncUpdateCustomField.sql )
--		Here is how you use the function:
--			update st_t set cf=dbo.fncUpdateCustomField(cf, '[FieldTo_Without the 
--			cf_ prefix]',ISNULL(st_f.[FieldtotakedataFrom],'')) 
--			from [ShipToTableTo] st_t
--			inner join [ShipToTableFrom] st_f ON st_t.CustId= st_f.CustId AND 
--			st_f.ShipToId= st_t.ShipToId
--
--		For Text 
--		update st_t set cf=dbo.fncUpdateCustomField(cf, '[EDIShipToName]',ISNULL(st_f.[EDIShipToName],'')) 
--		from tblArShipTo st_t
--		inner join tblArShipTo_10_5 st_f ON st_t.CustId= st_f.CustId AND st_f.ShipToId= st_t.ShipToId
--
--		For Numeric 
--		update st_t set cf=dbo.fncUpdateCustomField(cf, '[EDIMaxCartonValue]',ISNULL(st_f.[ EDIMaxCartonValue],'0')) 
--		from tblArShipTo st_t
--		inner join tblArShipTo_10_5 st_f ON st_t.CustId= st_f.CustId AND st_f.ShipToId= st_t.ShipToId
--
--		For Bit
--   	ADD two new fields to tblArShipTo_10_5: 
--		ALTER TABLE tblArShipTo_10_5
--		ADD 
--		EDIInvoiceYN_TEXT  VARCHAR(10),
--		EDIASNYN_TEXT  VARCHAR(10)
--
--		Update the new fields in the old table
--		UPDATE tblArShipTo_10_5  SET EDIInvoiceYN_TEXT  = CASE WHEN ISNULL(EDIInvoiceYN,0)=0 THEN ‘FALSE’ ELSE ‘TRUE’ END
--		UPDATE tblArShipTo_10_5  SET EDIASNYN_TEXT  = CASE WHEN ISNULL(EDIASNYN,0)=0 THEN ‘FALSE’ ELSE ‘TRUE’ END
--
--		Update Traverse 11 Table
--		update st_t set cf=dbo.fncUpdateCustomField(cf, '[EDIInvoiceYN]',ISNULL(st_f.[ EDIInvoiceYN_TEXT],'FALSE')) 
--		from tblArShipTo st_t
--		inner join tblArShipTo_10_5 st_f ON st_t.CustId= st_f.CustId AND st_f.ShipToId= st_t.ShipToId
--
--
-----------------------------------------------------------------------------

--	 	select * from [EDI].dbo.trav_tblArShipTo_view
--	 	where CustId='AUTOZN'

update [EDI].dbo.tblArShipTo_10_5	
set CustId='AUTOZN'
where CustId='AUTOZ0'

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIShipToCode',ISNULL(st_f.EDIShipToCode,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIBillToName',ISNULL(st_f.EDIBillToName,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIBillToAddress1',ISNULL(st_f.EDIBillToAddr1,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIBillToAddress2',ISNULL(st_f.EDIBillToAddr2,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIBillToCity',ISNULL(st_f.EDIBillToCity,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIBillToRegion',ISNULL(st_f.EDIBillToRegion,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIBillToPostalCode',ISNULL(st_f.EDIBillToPostalCode,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIBillToCountry',ISNULL(st_f.EDIBillToCountry,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIARDCID',ISNULL(st_f.EdiDistroId,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIShipToAbbrev',ISNULL(st_f.EDIShipToAbbrev,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIShipToName',ISNULL(st_f.EDIShipToName,'')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

/*
update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIShipToType',ISNULL(st_f.EDIShipToType,'0')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId
*/

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIInvoiceYN',ISNULL(st_f.EDIInvoiceYN,'TRUE')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIASNYN',ISNULL(st_f.EDIASNYN,'TRUE')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIMaxCartonValue',ISNULL(st_f.EDIMaxCartonValue,'0')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId

update st_t set cf=dbo.fncUpdateCustomField(cf, 'EDIMaxCartonWeight',ISNULL(st_f.EDIMaxCartonWeight,'0')) 
from tblArShipTo st_t
inner join tblArShipTo_10_5 st_f ON st_t.CustId=st_f.CustId AND st_f.ShipToId=st_t.ShipToId












