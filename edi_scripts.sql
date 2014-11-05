-- resend by post run or invoice
qryEdInvcResend


-- runs report of to list problems of Invoices stuck and not generating
qryEdValidateInvc

select * from tblEdPoHistHeader where CustPoNum='9053403549'
select * from tblEdPoHistHeader where CustPoNum='1052669031'
select * from tblEdPoHistHeader where CustPoNum='10426715' -- po exists
select * from tblEdPoHistHeader where CustPoNum='10464394' -- po exists
select * from tblEdPoHistHeader where CustPoNum='10433320' -- po exists