set nocount on
select 'exec sp_RefreshView  ' + name 
from dbo.sysobjects 
where xtype='V'
order by name

