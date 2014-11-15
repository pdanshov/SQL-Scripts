create proc Utility_GrantAllToPublic
as
set nocount on

Create Table #tmp(Id int IDENTITY (1, 1) ,txt varchar(256))

insert into #tmp(txt) select name from dbo.sysobjects where xtype='V' or xtype='U' or xtype='P' order by name

		declare @i int
		declare @e varchar(255)
		declare @txt varchar(255)
		select @i=min([id]) from #tmp
		while @i <> 0
			begin
				select @txt = txt from #tmp where [id]=@i
				set @e = 'grant all on  dbo.' + @txt + ' to public '
				exec  (@e)
				delete #tmp where [id]=@i
				select @i=min([id]) from #tmp
			end
		drop table #tmp


