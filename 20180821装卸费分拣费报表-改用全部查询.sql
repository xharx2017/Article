/*
  金蝶K/3Cloud的直接SQL账表，只支持select语句，即纯查询。其他诸如Create，Insert，Delete，Update，With table As等等都不支持。
  这坑爹的玩意，让一张简单的报表搞的无比复杂。
  2018-08-21:统计应收货主的装卸费和分拣费；
  2018-08-22:按王静要求，增加统计应支付给工人的装卸费和分拣费；
  2018-09-04:按王静要求，增加显示实际计费的数量数据，即体积数或重量数F_UX_TOTALBASEQTY_D；
*/
select * from
(
select c.FNumber,cl.FName,b.billNo,to_char(b.ywdate,'yyyy-MM-dd') ywdate,
       m.FNumber GoodNumber,ml.FName GoodName,ml.FSPECIFICATION,m.FOLDNUMBER,al.FDataValue,ul.FName Unit,
       b.qty,b.F_UX_TOTALBASEQTY_D,b.zxfprice,b.zxf,b.fjfprice,b.fjf,b.F_UX_WORKERPRICE_D,b.workamount,b.F_UX_FJOUTPRICE,b.F_UX_FJWORKERAMOUNT,
       b.expl,case b.bill when 1 then '其他入库' else '其他出库' end billt
from
(
--查询入库明细数据
 select m.Fownerid custID,m.FBillNo billNo,d.Fmaterialid goodID,d.Fbaseunitid unitID,
        case when m.Fstockdirect='GENERAL' then d.FBaseQty else -d.FBaseQty end qty,
        d.f_Ux_Unloadcosttype_d costID,d.F_UX_TOTALBASEQTY_D,d.f_ux_inprice_d zxfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_inamount_d else -d.f_ux_inamount_d end zxf,
        d.f_ux_fjinprice fjfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_fjowneramount else -d.f_ux_fjowneramount end fjf,
        d.F_UX_WORKERPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_WORKAMOUNT_D else -d.F_UX_WORKAMOUNT_D end workamount, 
        d.F_UX_FJOUTPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJWORKERAMOUNT else -d.F_UX_FJWORKERAMOUNT end F_UX_FJWORKERAMOUNT, 
        d.fnote expl,m.fdate ywdate,1 bill
  from t_stk_miscellaneous m
   left join t_stk_miscellaneousentry d on m.fid=d.fid
   left join t_bd_customer c on m.Fownerid=c.FCustID
  where m.fbilltypeid='5a29071d94fa9f' and m.Fownertypeid='BD_Customer' and d.f_Ux_Unloadcosttype_d !=' '
    and m.FDate>=to_date('#startDate#','YYYY-MM-dd') and m.FDate<=to_date('#endDate#','yyyy-MM-dd')
    and c.FNumber>='#startCustNo#' and c.FNumber<='#endCustNo#' 
 Union ALL
--查询出库明细数据
 select m.Fownerid,m.FBillNo,d.Fmaterialid,d.Fbaseunitid,case when m.Fstockdirect='GENERAL' then d.FBaseQty else -d.FBaseQty end,
        d.f_Ux_Unloadcosttype_d,d.F_UX_TOTALBASEQTY_D,
        d.F_UX_OUTPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_OUTAMOUNT_D else -F_UX_OUTAMOUNT_D end,
        d.F_UX_FJINPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJOWNERAMOUNT else -d.F_UX_FJOWNERAMOUNT end,
        d.F_UX_WORKERPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_WORKAMOUNT_D else -d.F_UX_WORKAMOUNT_D end,
        d.F_UX_FJOUTPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJWORKERAMOUNT else -d.F_UX_FJWORKERAMOUNT end,
        d.fnote,m.fdate,2
  from t_STK_MisDelivery m
   left join t_STK_MisDeliveryentry d on m.fid=d.fid
   left join t_bd_customer c on m.Fownerid=c.FCustID
  where m.fbilltypeid='5a2b78fed127a0' and m.Fownertypeid='BD_Customer' and d.f_Ux_Unloadcosttype_d !=' '
    and m.FDate>=to_date('#startDate#','YYYY-MM-dd') and m.FDate<=to_date('#endDate#','yyyy-MM-dd')
    and c.FNumber>='#startCustNo#' and c.FNumber<='#endCustNo#' 
) b
  left join t_bd_customer c on b.custid=c.Fcustid
  left join t_bd_customer_l cl on c.fcustid=cl.fcustid and cl.flocaleid=2052
  left join t_bd_material m on b.goodid=m.fmaterialid
  left join t_bd_material_l ml on m.fmaterialid=ml.fmaterialid and ml.flocaleid=2052
  left join t_bd_unit u on b.unitid=u.Funitid
  left join t_bd_unit_l ul on u.funitid=ul.funitid and ul.flocaleid=2052
  left join t_bas_assistantdataentry_l al on b.costid=al.fentryid and al.flocaleid=2052
Union All
select c.FNumber,cl.FName||'-合计',N'','',
       N'',N'',N'',N'',N'',N'',
       sum(b.qty),0,0,sum(b.zxf),0,sum(b.fjf),0,sum(b.workamount),0,sum(b.F_UX_FJWORKERAMOUNT),
       N'',''
from 
(
--查询入库明细数据
 select m.Fownerid custID,m.FBillNo billNo,d.Fmaterialid goodID,d.Fbaseunitid unitID,
        case when m.Fstockdirect='GENERAL' then d.FBaseQty else -d.FBaseQty end qty,
        d.f_Ux_Unloadcosttype_d costID,d.F_UX_TOTALBASEQTY_D,d.f_ux_inprice_d zxfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_inamount_d else -d.f_ux_inamount_d end zxf,
        d.f_ux_fjinprice fjfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_fjowneramount else -d.f_ux_fjowneramount end fjf,
        d.F_UX_WORKERPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_WORKAMOUNT_D else -d.F_UX_WORKAMOUNT_D end workamount, 
        d.F_UX_FJOUTPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJWORKERAMOUNT else -d.F_UX_FJWORKERAMOUNT end F_UX_FJWORKERAMOUNT, 
        d.fnote expl,m.fdate ywdate,1 bill
  from t_stk_miscellaneous m
   left join t_stk_miscellaneousentry d on m.fid=d.fid
   left join t_bd_customer c on m.Fownerid=c.FCustID
  where m.fbilltypeid='5a29071d94fa9f' and m.Fownertypeid='BD_Customer' and d.f_Ux_Unloadcosttype_d !=' '
    and m.FDate>=to_date('#startDate#','YYYY-MM-dd') and m.FDate<=to_date('#endDate#','yyyy-MM-dd')
    and c.FNumber>='#startCustNo#' and c.FNumber<='#endCustNo#' 
 Union ALL
--查询出库明细数据
 select m.Fownerid,m.FBillNo,d.Fmaterialid,d.Fbaseunitid,case when m.Fstockdirect='GENERAL' then d.FBaseQty else -d.FBaseQty end,
        d.f_Ux_Unloadcosttype_d,d.F_UX_TOTALBASEQTY_D,
        d.F_UX_OUTPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_OUTAMOUNT_D else -F_UX_OUTAMOUNT_D end,
        d.F_UX_FJINPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJOWNERAMOUNT else -d.F_UX_FJOWNERAMOUNT end,
        d.F_UX_WORKERPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_WORKAMOUNT_D else -d.F_UX_WORKAMOUNT_D end,
        d.F_UX_FJOUTPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJWORKERAMOUNT else -d.F_UX_FJWORKERAMOUNT end,
        d.fnote,m.fdate,2
  from t_STK_MisDelivery m
   left join t_STK_MisDeliveryentry d on m.fid=d.fid
   left join t_bd_customer c on m.Fownerid=c.FCustID
  where m.fbilltypeid='5a2b78fed127a0' and m.Fownertypeid='BD_Customer' and d.f_Ux_Unloadcosttype_d !=' '
    and m.FDate>=to_date('#startDate#','YYYY-MM-dd') and m.FDate<=to_date('#endDate#','yyyy-MM-dd')
    and c.FNumber>='#startCustNo#' and c.FNumber<='#endCustNo#' 
) b 
    left join t_bd_customer c on b.custid=c.Fcustid
    left join t_bd_customer_l cl on c.fcustid=cl.fcustid and cl.flocaleid=2052
   group by c.FNumber,cl.FName
Union all
select N'',N'总计',N'','',
       N'',N'',N'',N'',N'',N'',
       sum(b.qty),0,0,sum(b.zxf),0,sum(b.fjf),0,sum(b.workamount),0,sum(b.F_UX_FJWORKERAMOUNT),
       N'',''
from
(
--查询入库明细数据
 select m.Fownerid custID,m.FBillNo billNo,d.Fmaterialid goodID,d.Fbaseunitid unitID,
        case when m.Fstockdirect='GENERAL' then d.FBaseQty else -d.FBaseQty end qty,
        d.f_Ux_Unloadcosttype_d costID,d.F_UX_TOTALBASEQTY_D,d.f_ux_inprice_d zxfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_inamount_d else -d.f_ux_inamount_d end zxf,
        d.f_ux_fjinprice fjfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_fjowneramount else -d.f_ux_fjowneramount end fjf,
        d.F_UX_WORKERPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_WORKAMOUNT_D else -d.F_UX_WORKAMOUNT_D end workamount, 
        d.F_UX_FJOUTPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJWORKERAMOUNT else -d.F_UX_FJWORKERAMOUNT end F_UX_FJWORKERAMOUNT, 
        d.fnote expl,m.fdate ywdate,1 bill
  from t_stk_miscellaneous m
   left join t_stk_miscellaneousentry d on m.fid=d.fid
   left join t_bd_customer c on m.Fownerid=c.FCustID
  where m.fbilltypeid='5a29071d94fa9f' and m.Fownertypeid='BD_Customer' and d.f_Ux_Unloadcosttype_d !=' '
    and m.FDate>=to_date('#startDate#','YYYY-MM-dd') and m.FDate<=to_date('#endDate#','yyyy-MM-dd')
    and c.FNumber>='#startCustNo#' and c.FNumber<='#endCustNo#' 
 Union ALL
--查询出库明细数据
 select m.Fownerid,m.FBillNo,d.Fmaterialid,d.Fbaseunitid,case when m.Fstockdirect='GENERAL' then d.FBaseQty else -d.FBaseQty end,
        d.f_Ux_Unloadcosttype_d,d.F_UX_TOTALBASEQTY_D,
        d.F_UX_OUTPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_OUTAMOUNT_D else -F_UX_OUTAMOUNT_D end,
        d.F_UX_FJINPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJOWNERAMOUNT else -d.F_UX_FJOWNERAMOUNT end,
        d.F_UX_WORKERPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_WORKAMOUNT_D else -d.F_UX_WORKAMOUNT_D end,
        d.F_UX_FJOUTPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJWORKERAMOUNT else -d.F_UX_FJWORKERAMOUNT end,
        d.fnote,m.fdate,2
  from t_STK_MisDelivery m
   left join t_STK_MisDeliveryentry d on m.fid=d.fid
   left join t_bd_customer c on m.Fownerid=c.FCustID
  where m.fbilltypeid='5a2b78fed127a0' and m.Fownertypeid='BD_Customer' and d.f_Ux_Unloadcosttype_d !=' '
    and m.FDate>=to_date('#startDate#','YYYY-MM-dd') and m.FDate<=to_date('#endDate#','yyyy-MM-dd')
    and c.FNumber>='#startCustNo#' and c.FNumber<='#endCustNo#' 
) b
) c
order by FNumber,ywdate,billno,goodname

--附上用With语法的报表
with 
   b as
(--查询入库明细数据
 select m.Fownerid custID,m.FBillNo billNo,d.Fmaterialid goodID,d.Funitid unitID,
        case when m.Fstockdirect='GENERAL' then d.FQty else -d.FQty end qty,
        d.f_Ux_Unloadcosttype_d costID,d.f_ux_inprice_d zxfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_inamount_d else -d.f_ux_inamount_d end zxf,
        d.f_ux_fjinprice fjfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_fjowneramount else -d.f_ux_fjowneramount end fjf,
        d.fnote expl,m.fdate ywdate,1 bill
  from t_stk_miscellaneous m
   left join t_stk_miscellaneousentry d on m.fid=d.fid
  where m.fbilltypeid='5a29071d94fa9f' and m.Fownertypeid='BD_Customer' and d.f_Ux_Unloadcosttype_d !=' '
    and m.FDate>=to_date('2018-06-01','YYYY-MM-dd') and m.FDate<=to_date('2018-06-30','yyyy-MM-dd') 
 Union ALL
--查询出库明细数据
 select m.Fownerid,m.FBillNo,d.Fmaterialid,d.Funitid,case when m.Fstockdirect='GENERAL' then d.FQty else -d.FQty end,
        d.f_Ux_Unloadcosttype_d,
        d.F_UX_OUTPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_OUTAMOUNT_D else -F_UX_OUTAMOUNT_D end,
        d.F_UX_FJINPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJOWNERAMOUNT else -d.F_UX_FJOWNERAMOUNT end,
        d.fnote,m.fdate,2
  from t_STK_MisDelivery m
   left join t_STK_MisDeliveryentry d on m.fid=d.fid
  where m.fbilltypeid='5a2b78fed127a0' and m.Fownertypeid='BD_Customer' and d.f_Ux_Unloadcosttype_d !=' '
    and m.FDate>=to_date('2018-06-01','YYYY-MM-dd') and m.FDate<=to_date('2018-06-30','yyyy-MM-dd')
),s as
(
select c.FNumber,cl.FName,b.billNo,to_char(b.ywdate,'yyyy-MM-dd') ywdate,
       m.FNumber GoodNumber,ml.FName GoodName,ml.FSPECIFICATION,m.FOLDNUMBER,al.FDataValue,ul.FName Unit,
       b.qty,b.zxfprice,b.zxf,b.fjfprice,b.fjf,b.expl,
       case b.bill when 1 then '其他入库' else '其他出库' end bill
 from b
   left join t_bd_customer c on b.custid=c.Fcustid
   left join t_bd_customer_l cl on c.fcustid=cl.fcustid and cl.flocaleid=2052
   left join t_bd_material m on b.goodid=m.fmaterialid
   left join t_bd_material_l ml on m.fmaterialid=ml.fmaterialid and ml.flocaleid=2052
   left join t_bd_unit u on b.unitid=u.Funitid
   left join t_bd_unit_l ul on u.funitid=ul.funitid and ul.flocaleid=2052
   left join t_bas_assistantdataentry_l al on b.costid=al.fentryid and al.flocaleid=2052
union all  
select c.FNumber,cl.FName||'-合计',N'','',
       N'',N'',N'',N'',N'',N'',
        sum(b.qty),0,sum(b.zxf),0,sum(b.fjf),N'',''
   from b   
    left join t_bd_customer c on b.custid=c.Fcustid
    left join t_bd_customer_l cl on c.fcustid=cl.fcustid and cl.flocaleid=2052
   group by c.FNumber,cl.FName
union all
select N'',N'总计',N'','',
       N'',N'',N'',N'',N'',N'',
       sum(b.qty),0,sum(b.zxf),0,sum(b.fjf),N'',''
   from b)
select * from s order by FNumber,ywdate,billno,goodnumber;
