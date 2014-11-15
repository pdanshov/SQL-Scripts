create proc sp_tblDescr (@tblName as varchar(255))
as 
set Nocount on

SELECT sysobjects.name as TableName, syscolumns.name AS ColumnName,
 			type_name(xusertype) as Type,
			convert(int, length) as Length,
			case when isnullable = 0 then 'No' else 'Yes' end as NullYN					
FROM sysobjects INNER JOIN syscolumns ON sysobjects.id = syscolumns.id
Where sysobjects.name = @tblName And  user_name(uid) = N'dbo'
go