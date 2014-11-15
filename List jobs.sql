select 	j.originating_server, j.name, j.enabled, j.description,
	s.step_id, s.step_name, s.command
from msdb.dbo.sysjobs j
	inner join msdb.dbo.sysjobsteps s
	on j.job_id  = s.job_id
