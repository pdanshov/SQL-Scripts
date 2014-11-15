
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
--
--							Peter Danshov
--					pdanshv@gmail.com	11.14.14
--		This script adds an interactive view to the sys view table,
--		lists all columns in specified tables, adds records to SysTables
--		and SysColumns.
--
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

sp_helptext csi_EdFaInteractiveView_view
sp_helptext trav_EdPoHistDetail_rpt_CSI -- In EDI Company, Views -> Script View As... -> Alter To -> New Query

SELECT * FROM (select * from [edi].[dbo].trav_EdPoHistDetail_rpt_CSI ) ds

select * from sys.dbo.tblSysViews
where Id='EdFaInteractiveView'

insert into sys.dbo.tblSysViews
(Id, ReplaceId, Description, FilterId, DataSource, Available, Defaults, Enums, Formats) --Escape SQL single quotes: '' -or- 'string1' + CHAR(39) + 'string2'
values ('EdPoHistInteractiveView',null,'PO History Interactive View','','SELECT * FROM (select * from [{COMP}].dbo.trav_EdPoHistDetail_rpt_CSI) ds','PostRun,Partner ID,Customer PO Number,Import Batch ID,PO Date,Purpose Code,Type Code,Start Ship Date,Cancel Ship Date,Department ID,Ship To Code,Ship To Name,Ship To Addr1,Ship To Addr2,Ship To City,Ship To Region,Ship To Country,Ship To Postal Code,Terms Net Days,Terms Net Due Date,Customer ID,PostRun,Partner ID,Customer PO Number,Entry Number,Import Batch ID,PO Line Number,Store Number,Qty Ordered,Units Sell,Unit Price,Retail Price,Item Buyer Code,Item Vendor Code,Item UPC,Item Description,Color Description,Size Description,Item ID,SO Trans ID,Units Sell PO,Item SKU','PostRun,Partner ID,Customer PO Number,Import Batch ID,PO Date,Purpose Code,Type Code,Start Ship Date,Cancel Ship Date,Department ID,Ship To Code,Ship To Name,Ship To Addr1,Ship To Addr2,Ship To City,Ship To Region,Ship To Country,Ship To Postal Code,Terms Net Days,Terms Net Due Date,Customer ID,PostRun,Partner ID,Customer PO Number,Entry Number,Import Batch ID,PO Line Number,Store Number,Qty Ordered,Units Sell,Unit Price,Retail Price,Item Buyer Code,Item Vendor Code,Item UPC,Item Description,Color Description,Size Description,Item ID,SO Trans ID,Units Sell PO,Item SKU',null,null)

update sys.dbo.tblSysViews
SET Available='PostRun,Partner ID,Customer PO Number,Import Batch ID,PO Date,Purpose Code,Type Code,Start Ship Date,Cancel Ship Date,Department ID,Ship To Code,Ship To Name,Ship To Addr1,Ship To Addr2,Ship To City,Ship To Region,Ship To Country,Ship To Postal Code,Terms Net Days,Terms Net Due Date,Customer ID,PostRun,Partner ID,Customer PO Number,Entry Number,Import Batch ID,PO Line Number,Store Number,Qty Ordered,Units Sell,Unit Price,Retail Price,Item Buyer Code,Item Vendor Code,Item UPC,Item Description,Color Description,Size Description,Item ID,SO Trans ID,Units Sell PO,Item SKU', Defaults='PostRun,Partner ID,Customer PO Number,Import Batch ID,PO Date,Purpose Code,Type Code,Start Ship Date,Cancel Ship Date,Department ID,Ship To Code,Ship To Name,Ship To Addr1,Ship To Addr2,Ship To City,Ship To Region,Ship To Country,Ship To Postal Code,Terms Net Days,Terms Net Due Date,Customer ID,PostRun,Partner ID,Customer PO Number,Entry Number,Import Batch ID,PO Line Number,Store Number,Qty Ordered,Units Sell,Unit Price,Retail Price,Item Buyer Code,Item Vendor Code,Item UPC,Item Description,Color Description,Size Description,Item ID,SO Trans ID,Units Sell PO,Item SKU'
--SET Available='PostRun,PartnerID,CustPoNum,ImportBatchId,PoDate,PurposeCode,TypeCode,StartShipDate,CancelShipDate,DepartmentID,ShipToCode,ShipToName,ShipToAddr1,ShipToAddr2,ShipToCity,ShipToRegion,ShipToCountry,ShipToPostalCode,TermsNetDays,TermsNetDueDate,Custid,PostRun,PartnerId,CustPoNum,EntryNum,ImportBatchId,PoLineNum,StoreNum,QtyOrd,UnitsSell,UnitPrice,RetailPrice,ItemBuyerCode,ItemVendorCode,ItemUpc,ItemDecr,ColorDescr,SizeDescr,itemID,SoTransid,UnitsSellPO,ItemSKU,PartnerID,PartnerName', Defaults='PostRun,PartnerID,CustPoNum,ImportBatchId,PoDate,PurposeCode,TypeCode,StartShipDate,CancelShipDate,DepartmentID,ShipToCode,ShipToName,ShipToAddr1,ShipToAddr2,ShipToCity,ShipToRegion,ShipToCountry,ShipToPostalCode,TermsNetDays,TermsNetDueDate,Custid,PostRun,PartnerId,CustPoNum,EntryNum,ImportBatchId,PoLineNum,StoreNum,QtyOrd,UnitsSell,UnitPrice,RetailPrice,ItemBuyerCode,ItemVendorCode,ItemUpc,ItemDecr,ColorDescr,SizeDescr,itemID,SoTransid,UnitsSellPO,ItemSKU,PartnerID,PartnerName'
WHERE Id='EdPoHistInteractiveView';

--select column_name from information_schema.columns where table_name='EDI.dbo.tblEdPoHistHeader'
--desc tblEdPoHistHeader
sp_help  tblEdPartner

-----PostRun,PartnerID,CustPoNum,ImportBatchId,PoDate,PurposeCode,TypeCode,StartShipDate,CancelShipDate,DepartmentID,ShipToCode,ShipToName,ShipToAddr1,ShipToAddr2,ShipToCity,ShipToRegion,ShipToCountry,ShipToPostalCode,TermsNetDays,TermsNetDueDate,Custid,PostRun,PartnerId,CustPoNum,EntryNum,ImportBatchId,PoLineNum,StoreNum,QtyOrd,UnitsSell,UnitPrice,RetailPrice,ItemBuyerCode,ItemVendorCode,ItemUpc,ItemDecr,ColorDescr,SizeDescr,itemID,SoTransid,UnitsSellPO,ItemSKU

PostRun
PartnerID
CustPoNum
ImportBatchId
PoDate
PurposeCode
TypeCode
StartShipDate
CancelShipDate
--ContactName
--ContactPhone
--BuyerName
--BuyerPhone
DepartmentID
--MerchandiseTypeCode
ShipToCode
ShipToName
ShipToAddr1
ShipToAddr2
ShipToCity
ShipToRegion
ShipToCountry
ShipToPostalCode
--BillToCode
--BillToName
--BillToAddr1
--BillToAddr2
--BillToCity
--BillToRegion
--BillToCountry
--BillToPostalCode
--TermsBasisDateCode
--TermsDescr
--TermsDiscDaysDue
--TermsDiscPct
--TermsDiscDueDate
TermsNetDays
TermsNetDueDate
--TermsTypeCode
--Duns
--BackOrderAllowedYN
--ShipAsapYN
--ShipToStoreYN
--UDF1
--UDF2
--UDF3
--UDF4
--UDF5
--IsNew
--ErrorCode
--ReqAcknlYN
--PoStatus
--sMessage
--ProdGroup
Custid

PostRun
PartnerId
CustPoNum
EntryNum
ImportBatchId
PoLineNum
StoreNum
QtyOrd
UnitsSell
UnitPrice
RetailPrice
--QtyPack
--UnitsPack
--ItemUir
ItemBuyerCode
ItemVendorCode
ItemUpc
ItemDecr
ColorDescr
SizeDescr
--UDF1
--UDF2
--UDF3
--UDF4
--UDF5
--IsNew
--ErrorCode
itemID
SoTransid
UnitsSellPO
--ManufTypeCode
--SoUOMConversionFactor
--ItemEAN
--ItemGTIN
ItemSKU
--ItemUDF1
--ItemUDF2
--ItemUDF3

PartnerID
PartnerName
DfltCustID
StartDate
ContactName
ContactPhone
ContactFax
ContactEmail
ContactWebSite
ISAControlNum
GSControlNum
STControlNum
ActiveYn
ts
--Partner Id,Partner Name,Doc Id,Document,Doc Key,Sender Id,Receiver Id,Date Sent,Time Sent,ISA Control Num,GS Control Num,ST Control Num,FA ISA Control Num,FA GS Control Num,FA ST Control Num,Return Code,FA Date,FA Time,ImportBatchId
--Partner Id,Partner Name,Document,Doc Key,Sender Id,Receiver Id,Date Sent,ISA Control Num,GS Control Num,ST Control Num,Return Code,FA Date

select * from sys.dbo.tblSysViews
where Id='EdPoHistInteractiveView'

select * from sys.dbo.tblSysTables
where ApplicationId='ED'

declare @id
select @id=(MAX(TableId)+1) from sys.dbo.tblSysTables
insert into (TableId, Flags, Location, Name, ApplicationId, Description, Scale, DepOrder, ValidateCriteria, Notes, ts)
select @id, 0, 'NNN', 'tblEdPoHistHeader', 'ED', 'POHistHeader Id'
select @id
go

declare @id
select @id=(MAX(TableId)+1) from sys.dbo.tblSysTables;
insert into (TableId, Flags, Location, Name, ApplicationId, Description, Scale, DepOrder, ValidateCriteria, Notes, ts)
select @id, 0, 'NNN', 'tblEdPoHistDetail', 'ED', 'POHistDetail Id'
select @id
go

select * from edi.dbo.tblEdPoHistHeader
select * from edi.dbo.tblEdPoHistDetail




