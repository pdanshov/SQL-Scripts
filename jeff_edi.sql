BEGIN TRANSACTION
delete from tblEdPoHeader
delete from tblEdPoDetail
delete from tblEdPoHistHeader
delete from tblEdPoHistDetail
SELECT * FROM tblEdPoHeader
select * from tblEdPoDetail
select * from tblEdPartner
delete from tblEdPoDetail where PartnerID='WALMAR' and [ID]>223
select CustPONum,* from tblArHistHeader where CustId='54482' and PostRun>='14'
select CustPONum,* from tblArHistHeader where CustId='10145' and PostRun>='14'
select CustPONum,* from tblArHistHeader where CustId='300445' and PostRun>='14'

select * from tblArHistHeader where CustPONum='66125567'
select * from tblarhistdetail where transid='1249321'
select * from tblArCust where CustId='54482'
select * from tblArShipTo where CustId='300445' order by city
EXEC qryEdValidatePo
EXEC qryEdCreateSoExec
select * from tblEdPoErrorlog
truncate table tbledpoerrorlog
update tblEdPoHeader set CustPoNum='10370328t1' where CustPoNum='10370328'
update tblEdPoDetail set CustPoNum='10370328t1' where CustPoNum='10370328'
ROLLBACK

select name + ', ' as [text()] 
from sys.columns 
where object_id = object_id('tblEdPoHeader') 
for xml path('')

SET IDENTITY_INSERT [001].dbo.tblEdPoHeader ON
INSERT INTO [001].dbo.tblEdPoHeader (ID, ImportBatchId, PartnerID, SenderId, CustPoNum, PoDate, PurposeCode, TypeCode, StartShipDate, CancelShipDate, ContactName, ContactPhone, BuyerName, BuyerPhone, DepartmentID, MerchandiseTypeCode, ShipToCode, ShipToName, ShipToAddr1, ShipToAddr2, ShipToCity, ShipToRegion, ShipToCountry, ShipToPostalCode, BillToCode, BillToName, BillToAddr1, BillToAddr2, BillToCity, BillToRegion, BillToCountry, BillToPostalCode, TermsBasisDateCode, TermsDescr, TermsDiscDaysDue, TermsDiscPct, TermsDiscDueDate, TermsNetDays, TermsNetDueDate, TermsTypeCode, Duns, BackOrderAllowedYN, ShipAsapYN, ShipToStoreYN, UDF1, UDF2, UDF3, UDF4, UDF5)
SELECT ID, ImportBatchId, PartnerID, SenderId, CustPoNum, PoDate, PurposeCode, TypeCode, StartShipDate, CancelShipDate, ContactName, ContactPhone, BuyerName, BuyerPhone, DepartmentID, MerchandiseTypeCode, ShipToCode, ShipToName, ShipToAddr1, ShipToAddr2, ShipToCity, ShipToRegion, ShipToCountry, ShipToPostalCode, BillToCode, BillToName, BillToAddr1, BillToAddr2, BillToCity, BillToRegion, BillToCountry, BillToPostalCode, TermsBasisDateCode, TermsDescr, TermsDiscDaysDue, TermsDiscPct, TermsDiscDueDate, TermsNetDays, TermsNetDueDate, TermsTypeCode, Duns, BackOrderAllowedYN, ShipAsapYN, ShipToStoreYN, UDF1, UDF2, UDF3, UDF4, UDF5 FROM [Test].dbo.tblEdPoHeader
SET IDENTITY_INSERT [001].dbo.tblEdPoHeader OFF

select name + ', ' as [text()] 
from sys.columns 
where object_id = object_id('tblEdPoDetail') 
for xml path('')

SET IDENTITY_INSERT [001].dbo.tblEdPoDetail ON
INSERT INTO [001].dbo.tblEdPoDetail (ID, ImportBatchId, PartnerId, SenderId, CustPoNum, EntryNum, PoLineNum, StoreNum, QtyOrd, UnitsSell, UnitPrice, RetailPrice, QtyPack, UnitsPack, ItemUir, ItemBuyerCode, ItemVendorCode, ItemUpc, ItemID, ItemDecr, ColorDescr, SizeDescr, UDF1, UDF2, UDF3, UDF4, UDF5, IsNew, ErrorCode, UnitsSellPO, ManufTypeCode, SoUOMConversionFactor)
SELECT ID, ImportBatchId, PartnerId, SenderId, CustPoNum, EntryNum, PoLineNum, StoreNum, QtyOrd, UnitsSell, UnitPrice, RetailPrice, QtyPack, UnitsPack, ItemUir, ItemBuyerCode, ItemVendorCode, ItemUpc, ItemID, ItemDecr, ColorDescr, SizeDescr, UDF1, UDF2, UDF3, UDF4, UDF5, IsNew, ErrorCode, UnitsSellPO, ManufTypeCode, SoUOMConversionFactor FROM [Test].dbo.tblEdPoDetail
SET IDENTITY_INSERT [001].dbo.tblEdPoDetail OFF

INSERT INTO [001].dbo.tblEdPoHistHeader
SELECT * FROM [Test].dbo.tblEdPoHistHeader

INSERT INTO [001].dbo.tblEdPoHistDetail
SELECT * FROM [Test].dbo.tblEdPoHistDetail

