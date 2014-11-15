select so.name,sc.name,
	sc.name + ' = ltrim(rtrim(upper(isnull(' + sc.name+','''')))),',
	'update dbo.'+ so.name+' set '+ sc.name +'='+ '''''' + ' where  '+sc.name+' is null'
from syscolumns sc
	inner join sysobjects so
	on sc.id = so.id
--where substring(so.name,1,3)='xls'
where so.name='tblGold0324'
order by sc.colid


