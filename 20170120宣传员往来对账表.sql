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
   2017��1��20�գ� ���� ���� ��
   ��������Ա�������˱�
   �߼���
   1��Ӧ�գ�ֱ�ӵ����������������ͣ�ҵ��ֵ����������ܽ�� ��ͷ��ע  ���۲���  ������ ����Ա ҵ����������
	 2��Ӧ�գ�����Ӧ�յ���������λ=�ͻ�����ͷ��ʵ�ս��   ��ͷ��ע���۲���  ������ ����Ա ҵ����������
	 3��Ӧ�գ��ڳ�Ӧ�յ�����ͷ��ʵ�ս��   ��ͷ ��ע ���۲���  ������ ����Ա ҵ����������
	 4���տ���۳��ⵥ����ͷ�ϼƣ�����Ϊȡ���������۽��ϼƣ�   ��ͷ��ע���۲���  ������ ����Ա ҵ����������
	 5���տ����Ӧ��������ͷ��ʵ�����  ��ͷ��ע���۲���  ������ ����Ա ҵ����������
	 6���տ�տ���������ͣ�ǰ��Ƿ��������ѣ�����ͷʵ�ս��   ��ͷ��ע���۲���  ������ ����Ա ҵ����������
	 7���տ�տ��˿���������ͣ��������˿����ͷʵ�˽��   ��ͷ��ע���۲���  ������ ����Ա ҵ����������
	 8���տ�����˻����������Ƽ���   ��ͷ��ע���۲���  ������ ����Ա ҵ����������

 */
 --���������ȡ��ֹ����ǰ������ص�������
 select s.FDate,s.FBillNo,'ֱ�ӵ�����ҵ��ֵ�' BillType,'��������' BussnessExp,s.FNOTE,
        s.F_PAEZ_BASE1 XCYCustID,sum(e.F_PAEZ_SALEAMOUNT) Amount,0 FSumsort
   from T_STK_STKTRANSFERIN S
   left join t_STK_STKTransferInEntry E on s.FID=e.FID
   where s.F_PAEZ_Assistant6='5865f8fbe40e01' and s.FBillTypeID='ce8f49055c5c4782b65463a3f863bb4a'
     and s.FDate<=@de and FTRANSFERDIRECT='GENERAL'   --��������������Ӧ��
   group by s.FDate,s.FBillNo,s.FNOTE,s.F_PAEZ_BASE1
 union all
 select s.FDate,s.FBillNo,'ֱ�ӵ�����ҵ��ֵ�' BillType,'�˻�����' BussnessExp,s.FNOTE,
        s.F_PAEZ_BASE1 XCYCustID,sum(e.F_PAEZ_SALEAMOUNT) Amount,0 FSumsort
   from T_STK_STKTRANSFERIN S
   left join t_STK_STKTransferInEntry E on s.FID=e.FID
   where s.F_PAEZ_Assistant6='5865f8fbe40e01' and s.FBillTypeID='ce8f49055c5c4782b65463a3f863bb4a'
     and s.FDate<=@de and FTRANSFERDIRECT='RETURN'   --�˻����أ����Ӧ��
   group by s.FDate,s.FBillNo,s.FNOTE,s.F_PAEZ_BASE1
 union all
 select FDate,FBillNo,'����Ӧ�յ�','',F_PAEZ_Text,
        FCONTACTUNIT,FAMOUNT,0
   from T_AR_OtherRecAble where FCONTACTUNITTYPE='BD_Customer'
    and FDate<=@de
 union all
 select FDate,FBillNo,'�ڳ�Ӧ�յ�','',F_PAEZ_REMARKS,
       FCUSTOMERID,FALLAMOUNTFOR,0
  from t_AR_receivable where FIsInit=1
 union all
 select FDate,FBillNo,'���۳��ⵥ','',F_PAEZ_REMARKS1,
        F_PAEZ_BASE,-F_PAEZ_Amount21,0
   from t_SAL_OutStock where FDate<=@de
/*
 2017-03-10����ȡ���۳��ⵥ��������ϼƣ��޸�Ϊȡ��ͷ�Զ����ֶΡ���ͷ�ϼơ�
 ���������������
 select R.FDate,R.FBillNo,'���۳��ⵥ','',R.F_PAEZ_REMARKS1,
        R.F_PAEZ_BASE,-sum(F.FAmount),0
   from t_SAL_OutStock R
   left join t_SAL_OutStockEntry_F F on R.FID=F.FID
   where R.FDate<=@de
   group by R.FDate,R.FBillNo,R.F_PAEZ_REMARKS1,R.F_PAEZ_BASE
*/   
 union all
 select FDate,FBillNo,'����Ӧ����','',F_PAEZ_REMARKS,
        FCONTACTUNIT,-FTOTALAMOUNT,0
   from T_AP_OTHERPAYABLE where FCONTACTUNITTYPE='BD_Customer' and FDate<=@de
 union all
 select FDate,FBillNo,'�տ','��ǰ��Ƿ��',F_PAEZ_REMARKS,
        F_PAEZ_BASE,-FREALRECAMOUNT,0
   from t_AR_ReceiveBill
   where FCONTACTUNITTYPE='BD_Customer' and (FBillTypeID='58732b35ff146e' or F_PAEZ_ASSISTANT='57edc4ca21df45') --������ǰʹ���տ������ֶ�ʱ�ĵ���
     and FDate<=@de
 union all
 select FDate,FBillNo,'�տ','�������ѻ���',F_PAEZ_REMARKS,
        F_PAEZ_BASE,-FREALRECAMOUNT,0
   from t_AR_ReceiveBill
   where FCONTACTUNITTYPE='BD_Customer' and (FBillTypeID='58732c4eff1c24' or F_PAEZ_ASSISTANT='57edc4d721df47') --������ǰʹ���տ������ֶ�ʱ�ĵ���
     and FDate<=@de
 union all
 select FDate,FBillNo,'�տ��˿','�������˿�',F_PAEZ_REMARKS,
        F_PAEZ_BASE2,-FREALREFUNDAMOUNT,0
   from T_AR_REFUNDBILL
   where FCONTACTUNITTYPE='BD_Customer' and (FBillTypeID='58736968d9fc52' or F_PAEZ_ASSISTANT='5850bf419a4840')
     and FDate<=@de
 union all
 select R.FDate,R.FBillNo,'�����˻���','',R.F_PAEZ_REMARKS2,
        R.F_PAEZ_BASE1,-sum(f.FAmount),0
   from T_SAL_RETURNSTOCK R
   left join t_SAL_ReturnStockEntry_F F on r.FID=f.FID
   where R.FDate<=@de
   group by R.FDate,R.FBillNo,R.F_PAEZ_REMARKS2,R.F_PAEZ_BASE1
),e as
(
 --���ڷ���
 select *,1 IsInit from d where FDate>=@ds and FDate<=@de
 union all
 --�ڳ�
 select @ds,'','�ڳ����','','',XCYCustID,sum(Amount), -1,0 from d where FDate<@ds group by XCYCustID
 --��ĩ���
 union all
 select @de,'','��ĩ���','','',XCYCustID,sum(Amount),1,2 from d where FDate<=@de group by XCYCustID
)

select e.FDate,e.FBillNo,e.BillType,e.BussnessExp,e.FNote,
       dl.FName Dept,ol.FName SaleGroup,sl.FName Saler,al.FDataValue Town,
       c.FNumber,cl.FName,e.Amount
  from t_BD_customer c
  left join e on e.XCYCustID=c.FCustID  --����Ա�������ݱ�
  left join t_BD_customer_L cl on c.FCustID=cl.FCustID and cl.FLOCALEID=2052  --�ͻ���
  left join T_BD_DEPARTMENT_L dl on dl.FDeptID=c.FSALDEPTID and dl.FLocaleID=2052  --���ű�
  left join T_BD_OPERATORGROUPENTRY_L ol on ol.FENTRYID=c.FSALGROUPID and ol.FLocaleID=2052 --�������
  left join T_BD_OPERATORENTRY ywy on ywy.FEntryID=c.FSeller    --����Ա��
  left join T_BD_STAFF_L sl on sl.FStaffID=ywy.FStaffID and sl.FLocaleID=2052  --Ա����
  left join T_BAS_ASSISTANTDATAEntry_L al on al.FEntryID=c.F_PAEZ_ASSISTANT8 and al.FLocaleID=2052 --�������ϱ�
  where c.FCustTypeID='57f4d1c8bd3a05' and (e.FDate is not NULL and e.FBillNo is not NULL)
    and c.FNumber>=@CardFrom and c.FNumber<=@CardTo
  order by c.FNumber,e.FSumsort,e.IsInit,e.FDate,e.BillType,e.FBillNo
END
GO