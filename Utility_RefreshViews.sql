create proc Utility_RefreshViews
as
set nocount on

Create Table #tmp(Id int IDENTITY (1, 1) ,txt varchar(256))

insert into #tmp(txt) select name from dbo.sysobjects where xtype='V'order by name

		declare @i int
		declare @txt varchar(255)
		select @i=min([id]) from #tmp
		while @i <> 0
			begin
				select @txt = txt from #tmp where [id]=@i
				exec  sp_RefreshView  @txt
				delete #tmp where [id]=@i
				select @i=min([id]) from #tmp
			end
		drop table #tmp
