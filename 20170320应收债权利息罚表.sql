
Alter PROCEDURE UXReportOfMaturedClaims
	/* 
	  ���ݵ���ծȨ�б�����ݼ�����Ϣ��
	  �������
	  1����˾���̶���ÿ��Ϊһ�����ڣ�ͳ�Ʒ�һ��δ������Ϣ��
	  2���������ڣ�����ծȨ�б��еĵ������ڣ����ֹ�������������120��Ĳ�������
	  3�������������ֹ��������������120��Ĳ���485�콫������ȥ120�죬������Ϣ4����㷣Ϣ
	  4�������������ֹ��������������485��ģ������365��Ʒ�Ϣ,��Ϣ4��
	  ��Ϣ=δ�տ���*Ӧ����Ϣ��
	  Ӧ����Ϣ��=��Ϣ*12/365/1000�������Ϣ*����
    ��Ϣ����=bos��������Ϣ�������趨
	  �����ʽ��
	  ��������ʾ���������ı�ͷ������Ҫ������ծȨ�б����������ݣ�����Ҫһ����Ϣ�����

	*/
	@ds datetime, 
	@de datetime
  with encryption
AS
BEGIN
	SET NOCOUNT ON;
	declare @IRate decimal(23,8);
  select top 1 @IRate =(FDecimal1*0.012)/365.00000000 from x_Interest order by fid desc;  --��Ϣ
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
