use [001] select * from tblInItem
where ItemId='3328SMB'

select * from [001].dbo.tblEdPartnerItemXref
where BuyerCode='3328-BL'

insert into [001].dbo.tblEdPartnerItemXref
values ('JCPRET','3328SMB','BX','CA',null,null,null,null,'3328-BL',null,null,null,null)