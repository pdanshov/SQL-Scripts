select * from tblSmConfig
where appid='ed'
 and rectype= 2048 --(groups)
 
-- insert new group

 declare @idg int
select @idg=(MAX(ConfigRef)+1) from dbo.tblSmConfig

insert into tblSmConfig
(ConfigRef,[RecType]
      ,[AppId]
      ,[ConfigId]
      ,[CTConfigRef]
      ,[OptConfigRef]
      ,[DispSeq]
      ,[Visible]
      ,[RoleConfigYn]
      ,[CaptionId]
      ,[SrchID]
      ,[DefaultValue]
      ,[MaxWidth]
      ,[RequiredYn]
      ,[ValueListId]
      ,[ReqAppId]
      ,[ReadOnlyYn]
      ,[MinValue]
      ,[MaxValue])
      select @idg,
      2048,
      'ED',
      'EdiGeneral',	
      356,	0,	100,	1,	0,	'General',	NULL,	NULL,	0,	1,	NULL,	NULL,
      	0,	NULL,	NULL
select @idg --10051 -- group id for EDiGeneral

 declare @id int
select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
--insert new business rule for EdiScanPack
insert into tblSmConfig
(ConfigRef,[RecType]
      ,[AppId]
      ,[ConfigId]
      ,[CTConfigRef]
      ,[OptConfigRef]
      ,[DispSeq]
      ,[Visible]
      ,[RoleConfigYn]
      ,[CaptionId]
      ,[SrchID]
      ,[DefaultValue]
      ,[MaxWidth]
      ,[RequiredYn]
      ,[ValueListId]
      ,[ReqAppId]
      ,[ReadOnlyYn]
      ,[MinValue]
      ,[MaxValue])
      select @id,
      1024,
      'ED',
      'EdiScanPack',	
      @idg,	0,	100,	1,	0,	'Scan and Pack', NULL, 0, 0, 0, 'lkpTrueFalse', NULL, 0, NULL, NULL 
select @id 

