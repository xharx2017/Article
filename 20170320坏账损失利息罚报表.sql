
Alter PROCEDURE UXReportOfBadDebt
	/* 
	  根据坏账备查簿的数据计算坏账处理利息罚
	  计算规则：
	  1、当单据日期与开始日期差＞120天时，罚坏账日期与开始日期差的天数罚息
	  2、当单据日期与开始日期差≤120天时,算出单据日期与坏账日期差的天数
	   2.1、这个天数＞120，则用天数-120计算罚息
	   2.2、这个天数≤120天不做奖罚,月息4厘
	  罚息=坏账金额*应罚利息率
	  应罚利息率=月息*12/365/1000换算成日息*天数
		罚息利率=bos单据中利息罚政策设定
	  报表格式：
	  所做出的表头除了需要《坏账备查簿》的所有内容，前面需要加业务员名称，后面需要显示罚款天数和利息罚金额

	*/
	@ds datetime, 
	@de datetime
	with encryption
AS
BEGIN
	SET NOCOUNT ON;
	declare @IRate decimal(23,8);
	select top 1 @IRate =(FDecimal1*0.012)/365.00000000 from x_Interest order by fid desc  --日息
    select b.FDate,b.FExplanation,b.FIsInit, b.FAmountFor,b.FAmountFor-b.FRemainAmountFor FBackAmountFor,
        a.FDate FBillDate,a.FType,a.FNumber,e.FName Employee,
        i.FName FCustomerName,c.FName FCurrencyName,@ds FStart,@de FEnd,
		datediff(dd,a.FDate,@ds) BillDaysFromStart,
		case when datediff(dd,a.FDate,@ds)<=120 then 
		  (case when datediff(dd,a.FDate,b.FDate)<=120 then 0 else datediff(dd,a.FDate,b.FDate)-120 end)
		else datediff(dd,@ds,b.FDate) end FaxiDays,
		case when datediff(dd,a.FDate,@ds)<=120 then 
		  (case when datediff(dd,a.FDate,b.FDate)<=120 then 0 else datediff(dd,a.FDate,b.FDate)-120 end)
		else datediff(dd,@ds,b.FDate) end*@irate*b.FRemainAmountFor Bonus
   from t_RP_NewBadDebt b 
     Inner Join t_RP_Contact a On  b.FContactID=a.FID  
     left join t_Emp e on e.FItemID=a.FEmployee
     Inner Join t_Currency c On  b.FCurrencyID=c.FCurrencyID  
     Inner Join t_item i On  b.FCustomer=i.FItemID and b.FBack=0 
   order by e.FName,B.Fcustomer,B.Fdate
END
GO
