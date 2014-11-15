declare @var varchar(255)
set @var = 123

--Left Zero Fill
	select replicate('0',6-len(isnull(@var,'')))+isnull(@var,'')

--Right Zero Fill
	select isnull(@var,'')+replicate('0',6-len(isnull(@var,'')))
