select * from
(
select c.FNumber,cl.FName,b.billNo,to_char(b.ywdate,'yyyy-MM-dd') ywdate,
       m.FNumber GoodNumber,ml.FName GoodName,ml.FSPECIFICATION,m.FOLDNUMBER,al.FDataValue,ul.FName Unit,
       b.qty,b.zxfprice,b.zxf,b.fjfprice,b.fjf,b.expl,
       case b.bill when 1 then '其他入库' else '其他出库' end billt
from
(
--查询入库明细数据
 select m.Fownerid custID,m.FBillNo billNo,d.Fmaterialid goodID,d.Fbaseunitid unitID,
        case when m.Fstockdirect='GENERAL' then d.FBaseQty else -d.FBaseQty end qty,
        d.f_Ux_Unloadcosttype_d costID,d.f_ux_inprice_d zxfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_inamount_d else -d.f_ux_inamount_d end zxf,
        d.f_ux_fjinprice fjfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_fjowneramount else -d.f_ux_fjowneramount end fjf,
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
        d.f_Ux_Unloadcosttype_d,
        d.F_UX_OUTPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_OUTAMOUNT_D else -F_UX_OUTAMOUNT_D end,
        d.F_UX_FJINPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJOWNERAMOUNT else -d.F_UX_FJOWNERAMOUNT end,
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
        sum(b.qty),0,sum(b.zxf),0,sum(b.fjf),N'',''
from 
(
--查询入库明细数据
 select m.Fownerid custID,m.FBillNo billNo,d.Fmaterialid goodID,d.Fbaseunitid unitID,
        case when m.Fstockdirect='GENERAL' then d.FBaseQty else -d.FBaseQty end qty,
        d.f_Ux_Unloadcosttype_d costID,d.f_ux_inprice_d zxfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_inamount_d else -d.f_ux_inamount_d end zxf,
        d.f_ux_fjinprice fjfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_fjowneramount else -d.f_ux_fjowneramount end fjf,
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
        d.f_Ux_Unloadcosttype_d,
        d.F_UX_OUTPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_OUTAMOUNT_D else -F_UX_OUTAMOUNT_D end,
        d.F_UX_FJINPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJOWNERAMOUNT else -d.F_UX_FJOWNERAMOUNT end,
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
       sum(b.qty),0,sum(b.zxf),0,sum(b.fjf),N'',''
from
(
--查询入库明细数据
 select m.Fownerid custID,m.FBillNo billNo,d.Fmaterialid goodID,d.Fbaseunitid unitID,
        case when m.Fstockdirect='GENERAL' then d.FBaseQty else -d.FBaseQty end qty,
        d.f_Ux_Unloadcosttype_d costID,d.f_ux_inprice_d zxfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_inamount_d else -d.f_ux_inamount_d end zxf,
        d.f_ux_fjinprice fjfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_fjowneramount else -d.f_ux_fjowneramount end fjf,
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
        d.f_Ux_Unloadcosttype_d,
        d.F_UX_OUTPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_OUTAMOUNT_D else -F_UX_OUTAMOUNT_D end,
        d.F_UX_FJINPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJOWNERAMOUNT else -d.F_UX_FJOWNERAMOUNT end,
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



--修改后，将单据上的单位统一换算为基本库存单位
select c.FNumber,cl.FName,b.billNo,to_char(b.ywdate,'yyyy-MM-dd') ywdate,
       m.FNumber GoodNumber,ml.FName GoodName,ml.FSPECIFICATION,m.FOLDNUMBER,al.FDataValue,ul.FName Unit,
       b.qty,b.zxfprice,b.zxf,b.fjfprice,b.fjf,b.expl,
       case b.bill when 1 then '其他入库' else '其他出库' end billt
 From 
 (--查询入库明细数据
  select m.Fownerid custID,m.FBillNo billNo,d.Fmaterialid goodID,d.Fbaseunitid unitID,
        case when m.Fstockdirect='GENERAL' then d.FbaseQty else -d.FbaseQty end qty,
        d.f_Ux_Unloadcosttype_d costID,d.f_ux_inprice_d zxfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_inamount_d else -d.f_ux_inamount_d end zxf,
        d.f_ux_fjinprice fjfPrice,
        case when m.Fstockdirect='GENERAL' then d.f_ux_fjowneramount else -d.f_ux_fjowneramount end fjf,
        d.fnote expl,m.fdate ywdate,1 bill
  from t_stk_miscellaneous m
   left join t_stk_miscellaneousentry d on m.fid=d.fid
   left join t_bd_customer c on m.Fownerid=c.FCustID
  where m.fbilltypeid='5a29071d94fa9f' and m.Fownertypeid='BD_Customer' and d.f_Ux_Unloadcosttype_d !=' '
    and m.FDate>=to_date('#startDate#','YYYY-MM-dd') and m.FDate<=to_date('#endDate#','yyyy-MM-dd')
    and c.FNumber>='#startCustNo#' and c.FNumber<='#endCustNo#' 
  Union ALL
 --查询出库明细数据
  select m.Fownerid,m.FBillNo,d.Fmaterialid,d.Fbaseunitid,case when m.Fstockdirect='GENERAL' then d.FbaseQty else -d.FbaseQty end,
        d.f_Ux_Unloadcosttype_d,
        d.F_UX_OUTPRICE_D,case when m.Fstockdirect='GENERAL' then d.F_UX_OUTAMOUNT_D else -d.F_UX_OUTAMOUNT_D end,
        d.F_UX_FJINPRICE,case when m.Fstockdirect='GENERAL' then d.F_UX_FJOWNERAMOUNT else -d.F_UX_FJOWNERAMOUNT end,
        d.fnote,m.fdate,2
  from t_STK_MisDelivery m
   left join t_STK_MisDeliveryentry d on m.fid=d.fid
   left join t_bd_customer c on m.Fownerid=c.FCustID
  where m.fbilltypeid='5a2b78fed127a0' and m.Fownertypeid='BD_Customer' and d.f_Ux_Unloadcosttype_d !=' '
    and m.FDate>=to_date('#startDate#','YYYY-MM-dd') and m.FDate<=to_date('#endDate#','yyyy-MM-dd')
    and c.FNumber>='#startCustNo#' and c.FNumber<='#endCustNo#') b
   left join t_bd_customer c               on b.custid=c.Fcustid
   left join t_bd_customer_l cl            on c.fcustid=cl.fcustid         and cl.flocaleid=2052
   left join t_bd_material m               on b.goodid=m.fmaterialid
   left join t_bd_material_l ml            on m.fmaterialid=ml.fmaterialid and ml.flocaleid=2052  
   left join t_bas_assistantdataentry_l al on b.costid=al.fentryid         and al.flocaleid=2052
   left join t_bd_unit u                   on b.UnitID=u.Funitid
   left join t_bd_unit_l ul                on u.funitid=ul.funitid         and ul.flocaleid=2052
  order by c.FNumber,ywdate,b.billNo,m.FNumber
