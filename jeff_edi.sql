delete from tblEdPoHeader
delete from tblEdPoDetail
delete from tblEdPoHistHeader
delete from tblEdPoHistDetail
SELECT * FROM tblEdPoHeader
select * from tblEdPoDetail
select * from tblEdPartner
delete from tblEdPoDetail where PartnerID='WALMAR' and [ID]>223
select CustPONum,* from tblArHistHeader where CustId='54482' and PostRun>='14'
select CustPONum,* from tblArHistHeader where CustId='10145' and PostRun>='14'
select CustPONum,* from tblArHistHeader where CustId='300445' and PostRun>='14'

select * from tblArHistHeader where CustPONum='66125567'
select * from tblarhistdetail where transid='1249321'
select * from tblArCust where CustId='54482'
select * from tblArShipTo where CustId='300445' order by city
EXEC qryEdValidatePo
EXEC qryEdCreateSoExec
select * from tblEdPoErrorlog
truncate table tbledpoerrorlog
update tblEdPoHeader set CustPoNum='10370328t1' where CustPoNum='10370328'
update tblEdPoDetail set CustPoNum='10370328t1' where CustPoNum='10370328'
ROLLBACK