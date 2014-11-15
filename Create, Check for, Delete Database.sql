--Create 
	create database test

--Check for 
	Select Case When Count(1) > 0 Then 'Y' Else 'N' End ExistsYn
	From Sysdatabases where name = 'test'

--Delete
	drop database test
