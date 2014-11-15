select c.id,o.*,c.text from   syscomments c
inner join sysobjects o
on c.id=o.id
where [TEXT] like '%GlJrnl%'
select distinct name from   syscomments c
inner join sysobjects o
on c.id=o.id
where [TEXT] like '%ArCCHistFailTempAppr%'


sp_helptext trav_BuildPostGlEntries_proc