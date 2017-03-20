Alter PROCEDURE GDGXCYARRep
	@ds Datetime,
	@de Datetime,
	@CardFrom varchar(255),
	@CardTo   varchar(255)
with encryption
AS
BEGIN
SET NOCOUNT ON;
with d as
(
 /*
   2017年1月20日， 河南 邓州 。
   报表：宣传员往来对账表
   逻辑：
   1、应收：直接调拨单（调拨单类型：业务分单，金额：表体总金额 表头备注  销售部门  销售组 销售员 业绩计入乡镇）
	 2、应收：其他应收单（往来单位=客户，表头：实收金额   表头备注销售部门  销售组 销售员 业绩计入乡镇）
	 3、应收：期初应收单（表头：实收金额   表头 备注 销售部门  销售组 销售员 业绩计入乡镇）
	 4、收款：销售出库单：表头合计（调整为取单据体销售金额合计）   表头备注销售部门  销售组 销售员 业绩计入乡镇
	 5、收款：其他应付单（表头：实付金额  表头备注销售部门  销售组 销售员 业绩计入乡镇）
	 6、收款：收款单（单据类型：前期欠款、信用消费，金额：表头实收金额   表头备注销售部门  销售组 销售员 业绩计入乡镇）
	 7、收款：收款退款单（单据类型：往来账退款，金额：表头实退金额   表头备注销售部门  销售组 销售员 业绩计入乡镇）
	 8、收款：销售退货单：订单推荐人   表头备注销售部门  销售组 销售员 业绩计入乡镇

 */
 --以下语句提取截止日期前所有相关单据数据
 select s.FDate,s.FBillNo,'直接调拨单业务分单' BillType,'正常调出' BussnessExp,s.FNOTE,
        s.F_PAEZ_BASE1 XCYCustID,sum(e.F_PAEZ_SALEAMOUNT) Amount,0 FSumsort
   from T_STK_STKTRANSFERIN S
   left join t_STK_STKTransferInEntry E on s.FID=e.FID
   where s.F_PAEZ_Assistant6='5865f8fbe40e01' and s.FBillTypeID='ce8f49055c5c4782b65463a3f863bb4a'
     and s.FDate<=@de and FTRANSFERDIRECT='GENERAL'   --正常调出，增加应收
   group by s.FDate,s.FBillNo,s.FNOTE,s.F_PAEZ_BASE1
 union all
 select s.FDate,s.FBillNo,'直接调拨单业务分单' BillType,'退货调回' BussnessExp,s.FNOTE,
        s.F_PAEZ_BASE1 XCYCustID,sum(e.F_PAEZ_SALEAMOUNT) Amount,0 FSumsort
   from T_STK_STKTRANSFERIN S
   left join t_STK_STKTransferInEntry E on s.FID=e.FID
   where s.F_PAEZ_Assistant6='5865f8fbe40e01' and s.FBillTypeID='ce8f49055c5c4782b65463a3f863bb4a'
     and s.FDate<=@de and FTRANSFERDIRECT='RETURN'   --退货调回，冲减应收
   group by s.FDate,s.FBillNo,s.FNOTE,s.F_PAEZ_BASE1
 union all
 select FDate,FBillNo,'其他应收单','',F_PAEZ_Text,
        FCONTACTUNIT,FAMOUNT,0
   from T_AR_OtherRecAble where FCONTACTUNITTYPE='BD_Customer'
    and FDate<=@de
 union all
 select FDate,FBillNo,'期初应收单','',F_PAEZ_REMARKS,
       FCUSTOMERID,FALLAMOUNTFOR,0
  from t_AR_receivable where FIsInit=1
 union all
 select FDate,FBillNo,'销售出库单','',F_PAEZ_REMARKS1,
        F_PAEZ_BASE,-F_PAEZ_Amount21,0
   from t_SAL_OutStock where FDate<=@de
/*
 2017-03-10，由取销售出库单单据体金额合计，修改为取表头自定义字段“表头合计”
 所以屏蔽以下语句
 select R.FDate,R.FBillNo,'销售出库单','',R.F_PAEZ_REMARKS1,
        R.F_PAEZ_BASE,-sum(F.FAmount),0
   from t_SAL_OutStock R
   left join t_SAL_OutStockEntry_F F on R.FID=F.FID
   where R.FDate<=@de
   group by R.FDate,R.FBillNo,R.F_PAEZ_REMARKS1,R.F_PAEZ_BASE
*/   
 union all
 select FDate,FBillNo,'其他应付单','',F_PAEZ_REMARKS,
        FCONTACTUNIT,-FTOTALAMOUNT,0
   from T_AP_OTHERPAYABLE where FCONTACTUNITTYPE='BD_Customer' and FDate<=@de
 union all
 select FDate,FBillNo,'收款单','收前期欠款',F_PAEZ_REMARKS,
        F_PAEZ_BASE,-FREALRECAMOUNT,0
   from t_AR_ReceiveBill
   where FCONTACTUNITTYPE='BD_Customer' and (FBillTypeID='58732b35ff146e' or F_PAEZ_ASSISTANT='57edc4ca21df45') --兼容以前使用收款类型字段时的单据
     and FDate<=@de
 union all
 select FDate,FBillNo,'收款单','信用消费还款',F_PAEZ_REMARKS,
        F_PAEZ_BASE,-FREALRECAMOUNT,0
   from t_AR_ReceiveBill
   where FCONTACTUNITTYPE='BD_Customer' and (FBillTypeID='58732c4eff1c24' or F_PAEZ_ASSISTANT='57edc4d721df47') --兼容以前使用收款类型字段时的单据
     and FDate<=@de
 union all
 select FDate,FBillNo,'收款退款单','往来账退款',F_PAEZ_REMARKS,
        F_PAEZ_BASE2,-FREALREFUNDAMOUNT,0
   from T_AR_REFUNDBILL
   where FCONTACTUNITTYPE='BD_Customer' and (FBillTypeID='58736968d9fc52' or F_PAEZ_ASSISTANT='5850bf419a4840')
     and FDate<=@de
 union all
 select R.FDate,R.FBillNo,'销售退货单','',R.F_PAEZ_REMARKS2,
        R.F_PAEZ_BASE1,-sum(f.FAmount),0
   from T_SAL_RETURNSTOCK R
   left join t_SAL_ReturnStockEntry_F F on r.FID=f.FID
   where R.FDate<=@de
   group by R.FDate,R.FBillNo,R.F_PAEZ_REMARKS2,R.F_PAEZ_BASE1
),e as
(
 --本期发生
 select *,1 IsInit from d where FDate>=@ds and FDate<=@de
 union all
 --期初
 select @ds,'','期初余额','','',XCYCustID,sum(Amount), -1,0 from d where FDate<@ds group by XCYCustID
 --期末余额
 union all
 select @de,'','期末余额','','',XCYCustID,sum(Amount),1,2 from d where FDate<=@de group by XCYCustID
)

select e.FDate,e.FBillNo,e.BillType,e.BussnessExp,e.FNote,
       dl.FName Dept,ol.FName SaleGroup,sl.FName Saler,al.FDataValue Town,
       c.FNumber,cl.FName,e.Amount
  from t_BD_customer c
  left join e on e.XCYCustID=c.FCustID  --宣传员往来数据表
  left join t_BD_customer_L cl on c.FCustID=cl.FCustID and cl.FLOCALEID=2052  --客户表
  left join T_BD_DEPARTMENT_L dl on dl.FDeptID=c.FSALDEPTID and dl.FLocaleID=2052  --部门表
  left join T_BD_OPERATORGROUPENTRY_L ol on ol.FENTRYID=c.FSALGROUPID and ol.FLocaleID=2052 --销售组表
  left join T_BD_OPERATORENTRY ywy on ywy.FEntryID=c.FSeller    --销售员表
  left join T_BD_STAFF_L sl on sl.FStaffID=ywy.FStaffID and sl.FLocaleID=2052  --员工表
  left join T_BAS_ASSISTANTDATAEntry_L al on al.FEntryID=c.F_PAEZ_ASSISTANT8 and al.FLocaleID=2052 --辅助资料表
  where c.FCustTypeID='57f4d1c8bd3a05' and (e.FDate is not NULL and e.FBillNo is not NULL)
    and c.FNumber>=@CardFrom and c.FNumber<=@CardTo
  order by c.FNumber,e.FSumsort,e.IsInit,e.FDate,e.BillType,e.FBillNo
END
GO