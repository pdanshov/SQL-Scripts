set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


ALTER  proc [dbo].[Utility_GrantAllToPublic]
as
set nocount on

Create Table #tmp(Id int IDENTITY (1, 1) ,txt varchar(256), xtype varchar(2))

insert into #tmp(txt,xtype) select name,xtype from dbo.sysobjects where xtype='V' or xtype='U' or xtype='P' or xtype='FN' order by xtype,name

		declare @i int
		declare @e varchar(255)
		declare @txt varchar(255)
		declare @xtype varchar(255)
		select @i=min([id]) from #tmp
		while @i <> 0
			begin
				select @txt = txt, @xtype = xtype from #tmp where [id]=@i
				select @e = case @xtype 
								when 'U' then 'grant DELETE, INSERT, SELECT, UPDATE on  dbo.[' + @txt + '] to public ' --Table
								when 'V' then 'grant DELETE, INSERT, SELECT, UPDATE on  dbo.[' + @txt + '] to public ' --view
								when 'P' then 'grant EXECUTE on  dbo.[' + @txt + '] to public ' --Procedure
								when 'FN' then 'grant EXECUTE on  dbo.[' + @txt + '] to public ' --Function
								else 'grant all on  dbo.[' + @txt + '] to public '
							end
				exec  (@e)
				--print @e
				delete #tmp where [id]=@i
				select @i=min([id]) from #tmp
			end
		drop table #tmp


