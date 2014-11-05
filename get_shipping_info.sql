   -- get shiiping info fron warehouse
                 SELECT wh.BOLNum,REPLACE (convert(varchar,wh.ShipDate,101),'/',''),wh.CarrierName,
                        wh.CarrierSCAC,wh.CarrierPRO,wd.totWeight,wd.totHandleQty
                 FROM tblWMBOLHeader  wh
                 INNER JOIN (SELECT  BOLRef,TransId, SUM(HandleQty) totHandleQty,SUM(ExtWeight) totWeight
                             FROM dbo.tblWMBOLDetail 
                             WHERE  TransID='00002140'
                             GROUP BY BOLRef,TransId) wd ON wh.BOLRef=wd.BOLRef
                 INNER JOIN (SELECT MIN(bolnum) BOLnum
                             FROM tblArHistDetail d 
                             WHERE ISNULL(BOLNum,'')<>'' AND TransID='00002140' AND PostRun= '20140511152051') a ON  wh.BOLNum=a.BOLnum
                             
                             
                             
                       select   REPLACE (convert(varchar,h.InvcDate,101),'/','') s , h.PODate 
                       from tblArHistHeader h where  TransID='00002140' AND PostRun= '20140511152051' 
                             