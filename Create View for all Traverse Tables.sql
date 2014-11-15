set nocount on

SELECT --sysobjects.name as TableName, syscolumns.name AS ColumnName,
'create view '+ sysobjects.name + char(13)+' as '+char(13)+'select * from [JHSQL\Traverse].JH1.dbo.' + sysobjects.name + char(13) + 'go'
FROM sysobjects INNER JOIN syscolumns ON sysobjects.id = syscolumns.id
Where substring(sysobjects.name,1,3) = 'tbl' And  user_name(uid) = N'dbo'
