
/*
 *	for each custom field you need to make a script .
	This is the example for EDIPOPostRun

	You also have to insert all custom lookups to
	sys..tblSysLookup 
	based on

	select * from sys..tblSysLookup 
	where [ID]  like '%CSI%'
 *
 */


--insert custom fields
select * from tblSmCustomField
select c.Id,c.FieldName,e.EntityName,e.FieldId ,e.Id   from tblSmCustomField c
inner join tblSmCustomFieldEntity e
on c.Id=e.FieldId

--EDIPOPostRun
DECLARE @FieldName varchar(50)
DECLARE @FieldId int
SELECT @FieldName = 'EDIPOPostRun'
SELECT @FieldId = ISNULL(Id,'') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
IF @FieldId <> ''
BEGIN
	DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
	DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
END
	INSERT INTO dbo.tblSmCustomField
		([FieldName],[Definition])
	VALUES
		(@FieldName
		,'<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>20</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>')
SELECT @FieldName = 'EDIPOPostRun'
SELECT @FieldId = ISNULL(Id,'') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	INSERT INTO dbo.tblSmCustomFieldEntity
		(FieldId, Layout, EntityName)
	VALUES
		(@FieldId, null, 'tblARHistHeader')
		
	INSERT INTO dbo.tblSmCustomFieldEntity
		(FieldId, Layout, EntityName)
	VALUES
		(@FieldId, null, 'tblSOTransheader')
go

--rebuild views
exec dbo.trav_DSViewRebuildAll_proc
go


