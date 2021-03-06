USE [I31]
GO
/****** Object:  StoredProcedure [dbo].[rptEdPoHistSum_sp]    Script Date: 10/30/2014 15:47:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[rptEdPoHistSum_sp]        
@PartnerIDFrom varchar(50),        
@PartnerIDThru varchar(50),        
@CustPoNumFrom varchar(50),        
@CustPoNumThru varchar(50),        
@BatchIDFrom varchar(50),        
@BatchIDThru varchar(50)        
as        
        
set nocount on        
        
select h.PartnerID, p.PartnerName, h.CustPoNum, h.TypeCode, h.DepartmentID,         
case when h.PoDate='' then null else cast(h.PoDate as datetime) end PoDate,      
case when h.StartShipDate='' then null else cast(h.StartShipDate as datetime) end StartShipDate,       
case when h.CancelShipDate='' then null else cast(h.CancelShipDate as datetime) end CancelShipDate,        
cast (sum(cast(QtyOrd as float) * cast(UnitPrice as float)) as float) TotalWholeSales,        
cast (sum(cast(QtyOrd as float) *cast (d.RetailPrice as float)) as float) TotalRetail        
/* Added 10.30.14 - Peter */
, h.ShipToName, h.ShipToAddr1, h.ShipToAddr2, h.ShipToCity, h.ShipToRegion, h.ShipToPostalCode
/* -    -    -     -    - */
from dbo.tblEdPoHistHeader h        
left join dbo.tblEdPoHistDetail d on h.ImportBatchId = d.ImportBatchId       
and h.PartnerId = d.PartnerID and h.CustPoNum = d.CustPoNum        
left join dbo.tblEdPartner p on h.PartnerID = p.PartnerID        
where h.PartnerId between @PartnerIdfrom and @PartnerIDThru        
AND h.CustPoNum between @CustPoNumFrom and @CustPoNumThru        
        
group by h.PartnerID, p.PartnerName, h.CustPoNum, h.TypeCode, h.DepartmentID,         
h.PoDate,h.StartShipDate, h.CancelShipDate
/* Added 10.30.14 - Peter */
, h.ShipToName, h.ShipToAddr1, h.ShipToAddr2, h.ShipToCity, h.ShipToRegion, h.ShipToPostalCode
/* -    -    -     -    - */