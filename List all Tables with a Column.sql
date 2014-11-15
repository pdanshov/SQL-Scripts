select --so.name,sc.name 
	'select '''+so.name+''',count(WhseId),WhseId from JH1.dbo.'+so.name+' where WhseId in(''SAK'',''NEI'',''0WP'') group by WhseId union'
from JH1.dbo.syscolumns sc
	inner join JH1.dbo.sysobjects so
	on sc.id = so.id
where sc.name='WhseId' 
	and substring(so.name,1,3)='tbl'
	and so.name not in ('tblApTransOptions','tblMbAssemblyOptions','tblPoTransOptions','tblSoTransOptions')
order by so.name





