select l.Id,l.FieldName,v2.EntityName 
from tblSmCustomField l
left join dbo.tblSmCustomFieldEntity v2
on l.Id=v2.FieldId
order by v2.EntityName ,l.FieldName