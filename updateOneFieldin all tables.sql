SELECT sysobjects.name,'update '+sysobjects.name +' set BankAcctNum=''4012888818888'''+CHAR(10)+CHAR(13) +'go'+CHAR(10)+CHAR(13)



as TableName, syscolumns.name AS ColumnName, sysobjects.type,
 			type_name(xusertype) as Type,
			convert(int, length) as Length,
			case when isnullable = 0 then 'No' else 'Yes' end as NullYN					
FROM sysobjects INNER JOIN syscolumns ON sysobjects.id = syscolumns.id
Where syscolumns.name like'%BankAcctNum%'
and sysobjects.type='u'
And  user_name(uid) = N'dbo'