set nocount on
select 'grant all on  dbo.' + name + ' to public '
from dbo.sysobjects 
where xtype='V' or xtype='U' or xtype='P'
order by name

