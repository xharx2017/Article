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
   调整记录
 --**********2017-03-21**************
 --1、修改退货调回的金额为负数
 --2、关于业务员仓库，还需进一步了解

    了解情况：
    商品从一个宣传员那里调拨到另一个宣传员那里，调出宣传员的往来减少；调入宣传员的往来增加。
    与原来的直接调拨单应收区别在于：原来是从公司装车到车辆，即由公司库调拨到车辆库；然后再由车辆库调拨至宣传员（即业务分单）。
    所以原来的只用考虑调拨到宣传员，就增加宣传员应收；调回，就减少宣传员应收。
    这次增加了宣传员之间互相调拨，所以统计时就要考虑这种新情况。
    但是以宣传员命名的仓库与宣传员之间并没有数据上的关联，因此只能依靠名称来进行判定。
    根据调拨单分录上的仓库字段内码查询仓库编码，凡以XCYCK开头的均为宣传员仓库，
    再根据仓库名称的前6位（即宣传员卡号，与宣传员档案的编码一致），关联查询宣传员档案，获得宣传员内码
   [2017-09-26]
   1、付款单（表头：实付金额   单据类型为其他业务付款单 往来单位类型为客户）取成应收
   2、销售出库单由销售员改为按订单推荐人取数据，经查原来就是按订单推荐人提取的，所以此处不用更改
   3、不再限制只提取客户是代理员身份的数据，只要是客户数据全部都要提取
   4、报表里增加宣传员的 客户类别、入职日期、离职日期、合作部门 字段，合作部门来自各个单据的表头字段
 */
 --以下语句提取截止日期前所有相关单据数据
 select s.FDate,s.FBillNo,'直接调拨单业务分单' BillType,F_PAEZ_Base10 HzDeptID,'正常调出' BussnessExp,s.FNOTE,
        s.F_PAEZ_BASE1 XCYCustID,sum(e.F_PAEZ_SALEAMOUNT) Amount,0 FSumsort
   from T_STK_STKTRANSFERIN S
   left join t_STK_STKTransferInEntry E on s.FID=e.FID
   where s.F_PAEZ_Assistant6='5865f8fbe40e01' and s.FBillTypeID='ce8f49055c5c4782b65463a3f863bb4a'
     and s.FDate<=@de and FTRANSFERDIRECT='GENERAL'   --正常调出，增加应收
   group by s.FDate,s.FBillNo,s.FNOTE,F_PAEZ_Base10,s.F_PAEZ_BASE1
 /*
   2017-03-21新增处理宣传员仓库调出情况处理
   凡从宣传员仓库调出，则扣减该宣传员往来
   仍然是根据上节正常调出的代码，分析单据体的调出仓库是否属于宣传员仓库（判定依据：仓库编码前五位为XCYCK）
   如果是宣传员仓库，则进一步提取仓库名称的前六位（即卡号，与宣传员编码一致）
   然后以此查询宣传员内码，写入客户字段
*/
 union ALL
 --2017-03-24,“宣传员仓调出”的，摘要取直接调拨单上的“退货摘要”。由FNOTE改为F_PAEZ_Text1。
 --冲减调出仓宣传员的应收
 select s.FDate,s.FBillNo,'直接调拨单业务分单',F_PAEZ_Base10,'宣传员仓调出',s.F_PAEZ_Text1,
        c.FCustID,-e.F_PAEZ_SALEAMOUNT,0
   from T_STK_STKTRANSFERIN S
   left join t_STK_STKTransferInEntry E on s.FID=e.FID
   left join t_BD_stock k on k.FStockID=e.FSRCStockID and left(k.FNumber,5)='XCYCK'
   left join t_BD_stock_L kl on k.FStockID=kl.FStockID and kl.FLOCALEID=2052
   left join t_BD_customer c on c.FNumber=left(kl.FName,6)
   where s.F_PAEZ_Assistant6='5865f8fbe40e01' and s.FBillTypeID='ce8f49055c5c4782b65463a3f863bb4a'
     and s.FDate<=@de and FTRANSFERDIRECT='GENERAL'   --由宣传员仓库调出，扣减该宣传员的应收
	 and c.FCustID is not NULL
--2017-03-21更新结束
 union all
 --2017-10-09：肖丽菲 调拨方向为退货的取负数，所以将sum(e.F_PAEZ_SALEAMOUNT)修改为-sum(e.F_PAEZ_SALEAMOUNT)。
 select s.FDate,s.FBillNo,'直接调拨单业务分单',F_PAEZ_Base10,'退货调回',s.FNOTE,
        s.F_PAEZ_BASE1,-sum(e.F_PAEZ_SALEAMOUNT),0
   from T_STK_STKTRANSFERIN S
   left join t_STK_STKTransferInEntry E on s.FID=e.FID
   where s.F_PAEZ_Assistant6='5865f8fbe40e01' and s.FBillTypeID='ce8f49055c5c4782b65463a3f863bb4a'
     and s.FDate<=@de and FTRANSFERDIRECT='RETURN'   --退货调回，冲减应收
   group by s.FDate,s.FBillNo,s.FNOTE,F_PAEZ_Base10,s.F_PAEZ_BASE1
 union all
 select FDate,FBillNo,'其他应收单',F_PAEZ_Base1,'',F_PAEZ_Text,
        FCONTACTUNIT,FAMOUNT,0
   from T_AR_OtherRecAble where FCONTACTUNITTYPE='BD_Customer'
    and FDate<=@de
 union all
 select FDate,FBillNo,'期初应收单',F_PAEZ_BASE16,'',F_PAEZ_REMARKS,
       FCUSTOMERID,FALLAMOUNTFOR,0
  from t_AR_receivable where FIsInit=1
 union all
 select FDate,FBillNo,'销售出库单',F_PAEZ_BASE12,'',F_PAEZ_REMARKS1,
        F_PAEZ_BASE,-F_PAEZ_Amount21,0
   from t_SAL_OutStock where FDate<=@de
--2017-09-26
--肖丽菲：付款单（表头：实付金额   单据类型为其他业务付款单 往来单位类型为客户）取成应收
 union ALL
 select FDate,FBillNo,'付款单',F_PAEZ_Base2,'',F_PAEZ_Remarks,
        FCONTACTUNIT, FREALPAYAMOUNTFOR,0
   from T_AP_PAYBILL where FDate<=@de
    and FBILLTYPEID='fad46ca477d44b30b3fa7043c4604876'
    and FCONTACTUNITTYPE='BD_Customer'
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
 select FDate,FBillNo,'其他应付单',F_PAEZ_BASE3,'',F_PAEZ_REMARKS,
        FCONTACTUNIT,-FTOTALAMOUNT,0
   from T_AP_OTHERPAYABLE where FCONTACTUNITTYPE='BD_Customer' and FDate<=@de
 union all
 select FDate,FBillNo,'收款单',F_PAEZ_Base15,'收前期欠款',F_PAEZ_REMARKS,
        F_PAEZ_BASE,-FREALRECAMOUNT,0
   from t_AR_ReceiveBill
   where FCONTACTUNITTYPE='BD_Customer' and (FBillTypeID='58732b35ff146e' or F_PAEZ_ASSISTANT='57edc4ca21df45') --兼容以前使用收款类型字段时的单据
     and FDate<=@de
 union all
 select FDate,FBillNo,'收款单',F_PAEZ_Base15,'信用消费还款',F_PAEZ_REMARKS,
        F_PAEZ_BASE,-FREALRECAMOUNT,0
   from t_AR_ReceiveBill
   where FCONTACTUNITTYPE='BD_Customer' and (FBillTypeID='58732c4eff1c24' or F_PAEZ_ASSISTANT='57edc4d721df47') --兼容以前使用收款类型字段时的单据
     and FDate<=@de
 union all
 --2017-04-07 樊云佳提出：销售退货单和收款退款单取数都取成正数，由-FREALREFUNDAMOUNT改为FREALREFUNDAMOUNT
 --2017-09-28:肖丽菲 收款退款单要取正值，所以原-FREALREFUNDAMOUNT改为FREALREFUNDAMOUNT
 select FDate,FBillNo,'收款退款单',F_PAEZ_BASE16,'往来账退款',F_PAEZ_REMARKS,
        F_PAEZ_BASE2,FREALREFUNDAMOUNT,0
   from T_AR_REFUNDBILL
   where FCONTACTUNITTYPE='BD_Customer' and (FBillTypeID='58736968d9fc52' or F_PAEZ_ASSISTANT='5850bf419a4840')
     and FDate<=@de
 union all
 --2017-04-07 樊云佳提出：销售退货单和收款退款单取数都取成正数，所以由-sum(f.FAmount)改为sum(f.FAmount)
 --2017-10-09：肖丽菲 销售退货单  订单推荐人  取表头合计F_PAEZ_AMOUNT23  取成负数，不能按表体取金额合计数
 select FDate,FBillNo,'销售退货单',F_PAEZ_BASE15,'',F_PAEZ_REMARKS2,
        F_PAEZ_BASE1,-F_PAEZ_AMOUNT23,0
   from T_SAL_RETURNSTOCK
/*
   --2017-10-09：注释本段按表体取金额合计的语句
   left join t_SAL_ReturnStockEntry_F F on r.FID=f.FID
   where R.FDate<=@de
   group by R.FDate,R.FBillNo,R.F_PAEZ_REMARKS2,F_PAEZ_BASE15,R.F_PAEZ_BASE1
*/),e as
(
 --本期发生
 select *,1 IsInit from d where FDate>=@ds and FDate<=@de
 union all
 --期初
 select @ds,'','期初余额','','','',XCYCustID,sum(Amount), -1,0 from d where FDate<@ds group by XCYCustID
 --期末余额
 union all
 select @de,'','期末余额','','','',XCYCustID,sum(Amount),1,2 from d where FDate<=@de group by XCYCustID
)

select e.FDate 日期,e.FBillNo 单据编号,e.BillType 单据类型,e.BussnessExp 业务描述,isnull(hd.FName,'') 合作部门,
       e.FNote 摘要,
       isnull(dl.FName,'') 销售部门,
       isnull(ol.FName,'') 销售组,
       isnull(sl.FName,'') 销售员,
       isnull(al.FDataValue,'') 业绩计入乡镇,
       c.FNumber 宣传员编码,cl.FName 宣传员,ct1.FDataValue 客户类型,
       isnull(CONVERT(varchar,c.F_PAEZ_Date1,111),'') 入职日期,
       isnull(CONVERT(varchar,c.F_PAEZ_Date2,111),'') 离职日期,
       e.Amount 金额
  from t_BD_customer c
  left join e on e.XCYCustID=c.FCustID  --宣传员往来数据表
  left join t_BD_customer_L cl on c.FCustID=cl.FCustID and cl.FLOCALEID=2052  --客户表
  left join T_BD_DEPARTMENT_L dl on dl.FDeptID=c.FSALDEPTID and dl.FLocaleID=2052  --部门表，销售部门
  left join T_BD_DEPARTMENT_L hd on hd.FDeptID=e.HzDeptID and hd.FLocaleID=2052    --单据上的合作部门
  left join T_BD_OPERATORGROUPENTRY_L ol on ol.FENTRYID=c.FSALGROUPID and ol.FLocaleID=2052 --销售组表
  left join T_BD_OPERATORENTRY ywy on ywy.FEntryID=c.FSeller    --销售员表
  left join T_BD_STAFF_L sl on sl.FStaffID=ywy.FStaffID and sl.FLocaleID=2052  --员工表
  left join T_BAS_ASSISTANTDATAEntry_L al on al.FEntryID=c.F_PAEZ_ASSISTANT8 and al.FLocaleID=2052 --辅助资料表，乡镇
  left join t_Bas_assistantdataentry_l ct1 on ct1.FEntryID=c.FCUSTTYPEID and ct1.FLocaleID=2052    --辅助资料表，客户类型
  where (e.FDate is not NULL and e.FBillNo is not NULL) --c.FCustTypeID='57f4d1c8bd3a05' --2017-09-26:肖丽菲，显示所有客户，不仅仅限于宣传员
    and c.FNumber>=@CardFrom and c.FNumber<=@CardTo
  order by c.FNumber,e.FSumsort,e.IsInit,e.FDate,e.BillType,e.FBillNo
END
GO
