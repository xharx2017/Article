
Alter PROCEDURE UXReportOfBadDebt
	/* 
	  ���ݻ��˱��鲾�����ݼ��㻵�˴�����Ϣ��
	  �������
	  1�������������뿪ʼ���ڲ120��ʱ�������������뿪ʼ���ڲ��������Ϣ
	  2�������������뿪ʼ���ڲ��120��ʱ,������������뻵�����ڲ������
	   2.1�����������120����������-120���㷣Ϣ
	   2.2�����������120�첻������,��Ϣ4��
	  ��Ϣ=���˽��*Ӧ����Ϣ��
	  Ӧ����Ϣ��=��Ϣ*12/365/1000�������Ϣ*����
		��Ϣ����=bos��������Ϣ�������趨
	  �����ʽ��
	  �������ı�ͷ������Ҫ�����˱��鲾�����������ݣ�ǰ����Ҫ��ҵ��Ա���ƣ�������Ҫ��ʾ������������Ϣ�����

	*/
	@ds datetime, 
	@de datetime
	with encryption
AS
BEGIN
	SET NOCOUNT ON;
	declare @IRate decimal(23,8);
	select top 1 @IRate =(FDecimal1*0.012)/365.00000000 from x_Interest order by fid desc  --��Ϣ
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
