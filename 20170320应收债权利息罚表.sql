
Alter PROCEDURE UXReportOfMaturedClaims
	/* 
	  根据到期债权列表的数据计算利息罚
	  计算规则：
	  1、公司将固定以每年为一个周期，统计罚一次未到款利息。
	  2、出库日期（到期债权列表中的单据日期）与截止日期相差天数≤120天的不做奖罚
	  3、出库日期与截止日期相差的天数＞120天的并＜485天将天数减去120天，再以月息4厘计算罚息
	  4、出库日期与截止日期相差的天数≥485天的，最高以365天计罚息,月息4厘
	  罚息=未收款金额*应罚利息率
	  应罚利息率=月息*12/365/1000换算成日息*天数
    罚息利率=bos单据中利息罚政策设定
	  报表格式：
	  报表单独显示，所做出的表头除了需要《到期债权列表》的所有内容，最后加要一个利息罚金额

	*/
	@ds datetime, 
	@de datetime
  with encryption
AS
BEGIN
	SET NOCOUNT ON;
	declare @IRate decimal(23,8);
  select top 1 @IRate =(FDecimal1*0.012)/365.00000000 from x_Interest order by fid desc;  --日息
    Select FCustomerNumber,FCustomerName,FNumber,FDepartmentName,FEmployeeName,
        FDate,FFincDate,FVchName + '-' + convert(varchar,FVchNumber) FVch,FExplanation,FAmount,FRemainAmount,
		FRPDate,FSuperDays,
		case when FSuperDays<=120 then 0 when FSuperDays<485 then (FSuperDays-120)*@IRate*FRemainAmount else 365*@IRate*FRemainAmount end bonus
    from (
      select c.FRp,c.FType,c.FNumber,c.FDate,c.FFincDate,e.FDate FRPDate,c.FIsInit,
      c.FBillID,c.FInvoiceID,c.FRPBillID,c.FBegID,c.FPre,
      e.FAmountFor,e.FAmount,c.FK3Import,
      e.FRemainAmount,e.FRemainAmountFor,
      datediff(dd,e.FDate,@de) FSuperDays,
      d.FName FCurrencyName, 
      i.FName FCustomerName,
      i.FNumber FCustomerNumber, 
      c.FExplanation,c.FContractNo,isnull(v.FNumber,'') FVchNumber,v.FName FVchName,
      isnull(ii.FNumber,'') FDepartmentNumber,
      isnull(ii.FName,'') FDepartmentName, 
      isnull(iii.FNumber,'') FEmployeeNumber,
      isnull(iii.FName,'') FEmployeeName, 
      c.FCustomer,c.FItemClassID,c.FDepartment,c.FEmployee,c.FCurrencyID 
      from t_rp_contact c 
      left  join (select a.FVoucherID,a.FNumber,b.FName FName from t_voucher  a join t_vouchergroup b on a.FGroupID=b.FGroupID) v on c.FVoucherID=v.FVoucherID
      INNER JOIN t_currency d on c.FCurrencyID=d.FCurrencyID 
      INNER JOIN t_item i on c.FCustomer=i.FItemID 
      left JOIN t_item ii on c.FDepartment=ii.FItemID
      left JOIN t_item iii on c.Femployee=iii.FItemID
      INNER JOIN t_RP_Plan_Ar e on c.FID=e.FOrgID 
      where c.FRP=1         and c.FInvoiceType not in(3,4) 
         and c.FItemClassID=1
      and c.FCurrencyID=1
      and c.FType in(1,3,11,13) 
      and c.FDate>=@ds
      and c.FDate<=@de
      and c.FRemainAmountFor<>0 
      and e.FRemainAmountFor<>0 
      and (c.FStatus & 1)=1        and e.FDate<=@de
    ) Dest 
    order by FCustomerNumber,FDate
END
GO
