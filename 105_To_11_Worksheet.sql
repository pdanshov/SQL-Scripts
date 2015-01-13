


-----------------------------------------------------------------------------
--
--								Peter Danshov
--					pdanshv@gmail.com		01.12.2015
--		This script updates values in Traverse custom fields,
--		updates tblArShipTo and tblEdPartnerItemXRef from Trav10.5 Data
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

update [EDI].dbo.tblArShipTo
set cf=dbo.fncUpdateCustomField(cf,'EDIInvoiceYN','True'))
update [EDI].dbo.tblArShipTo
set cf=dbo.fncUpdateCustomField(cf,'EDIASNYN','True'))
update [EDI].dbo.tblArShipTo
set cf=dbo.fncUpdateCustomField(cf,'EDIShipToType','0'))

INSERT INTO [EDI].dbo.tblEdPartnerItemXRef(PartnerID, UIR, EDIUOM, TRAVItemID, TRAVUOM, BuyerCode, VendorCode)
SELECT PartnerId, ItemRef, ItemUomXref, ItemId, ItemUom, ItemRef2, ItemRef FROM [EDI].dbo.tblEdPartnerItemXRef_10_5
WHERE PartnerID='AUTOZN';
/*	update st_t set st_t.PartnerID=st_f.PartnerID, st_t.UIR=st_f.UIR, st_t.EDIUOM=st_f.EDIUOM
	from tblEdPartnerItemXRef st_t
	inner join tblEdPartnerItemXRef_10_5 st_f ON st_t.PartnerID=st_f.PartnerID AND st_f.UIR=st_t.UIR
*/
INSERT INTO [EDI].dbo.tblArShipTo(CustId, ShiptoId, ShiptoName, Addr1, Addr2, City, Region, Country, PostalCode, IntlPrefix, Phone, Fax	Attn, ShipVia, TaxLocID, TerrId, DistCode, Email, Internet, AddressType, Phone1, Phone2, CF, ts)
SELECT CustId, ShiptoId, ShiptoName, Addr1, Addr2, City, Region, Country, PostalCode, IntlPrefix, Phone, Fax	Attn, ShipVia, TaxLocID, TerrId, DistCode, Email, Internet, AddressType, Phone1, Phone2, CF, ts FROM [EDI].dbo.tblArShipTo_10_5
-- WHERE PartnerID='AUTOZN';


/*
0000000	000134	A3 DESIGN	1612 E 14TH STREET	NULL	LOS ANGELES	CA	USA	90021	011	2137461155	NULL	NULL		NULL		NULL			NULL	NULL	NULL	<ArrayOfEntityPropertyOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><EntityPropertyOfString><Name>EDIInvoiceYN</Name><Value>True</Value></EntityPropertyOfString><EntityPropertyOfString><Name>EDIASNYN</Name><Value>True</Value></EntityPropertyOfString><EntityPropertyOfString><Name>EDIShiptoType</Name><Value>0</Value></EntityPropertyOfString></ArrayOfEntityPropertyOfString>	0x000000000EE27E6C

CustId	ShiptoId	ShiptoName	Addr1	Addr2	City	Region	Country	PostalCode	IntlPrefix	Phone	Fax	Attn	ShipVia	TaxLocID	TerrId	DistCode	Email	Internet	AddressType	Phone1	Phone2	ts	EdiShipToCode	EdiShipToName	EdiShipToAbbrev	EdiShipToType	EdiDistroId	EdiConsolId	EdiMaxCartonValue	EdiMaxCartonWeight	EdiDSYN	EDIBillToName	EDIBillToAddr1	EDIBillToAddr2	EDIBilltoCity	EDIBillToRegion	EDIBillToCountry	EDIBillToPostalCode	EdiInvoiceYN	EDIInvoiceYN_TEXT	EDIASNYN_TEXT	EDIASNYN

AUTOZ0	4802	AUTOZONE #4802	1708 N UNIVERSITY		PEMBROKE PINES	FL	USA	33024	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	0x000000000EDEA6BD	4802	PEMBROKE PINES FL	4802	1	NULL	NULL	0.0000000000	0.0000000000	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	1	TRUE	FALSE	NULL
*/
















