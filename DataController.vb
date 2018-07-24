Imports System.Net
Imports System.Web.Http
Imports Kingdee.Data.Global
Imports Kingdee.Data.Stock.In.Speed
Imports Kingdee.Foundation.Secure
Imports Newtonsoft.Json

Namespace Controllers
    Public Class DataController : Inherits ApiController
        ''' <summary>
        ''' 速必达入库单Excel表转储为临时数据
        ''' </summary>
        ''' <param name="_data">待转储的速必达入库单信息</param>
        ''' <returns></returns>
        <HttpPost>
        Public Function Accept(<FromBody> _data As TBaseList) As TMessages
            '比如把_data定义为string，从客户端传递来{"Data":"This is test data from client","Flag":"ERP"}
            '服务器端是不认的
            '必须定义为TestData类，服务器端才能正确识别出来
            '同理，返回值也必须定义为相应的类，服务器返回时才能正确解析为json字串
            '如果返回值定义为As String，Return _data就会报错
            Dim rv As New TMessages
            Dim msg As TMessage
            'Test for receive client Header informations
            Dim context As HttpContextBase = CType(Request.Properties("MS_HttpContext"), HttpContextBase)
            Dim rq As HttpRequestBase = context.Request
            Dim headerValueTest As String = rq.Headers.Get("usr_token")    '测试通过，服务器端能接收到客户端发送的数据
            Dim k3usr As String = rq.Headers.Get("k3usr")                  'K3用户
            Dim k3sid As String = rq.Headers.Get("k3sid")                  'K3用户的登录密码 
            If headerValueTest = String.Empty Then
                '客户端没有传递Token
                'String.IsNullOrEmpty(headerValueTest)
                rv.Result = -1
                msg = New TMessage
                msg.ID = 1
                msg.Message = "客户端未提供认证信息，认证无效"
                rv.Errors.Add(msg)
                rv.Value = ""
            Else
                '客户端传递来Token值，验证token是否有效
                Dim fdc As New TCheck
                Dim cr As Boolean = fdc.CheckClientToken(headerValueTest)
                If Not cr Then
                    '未通过验证
                    rv.Result = 0
                    msg = New TMessage
                    msg.ID = 1
                    msg.Message = "客户端未通过认证"
                    rv.Errors.Add(msg)
                    rv.Value = headerValueTest
                Else
                    '通过验证
                    Dim hasErrorOccured As Boolean = False     '代表未发生错误
                    Dim _detail As TBase
                    Dim _count As Integer = _data.Detail.Count
                    Dim _id As String = _data.ID
                    '如果客户端传来的_data包里，ID为空，则从服务器端生成一个任务ID，用以区分每次导入任务
                    If _id = String.Empty Or _id = "" Then
                        _id = GetMissinID()
                    End If
                    For i As Integer = 0 To _count - 1
                        _detail = _data.Detail(i)
                        msg = New TMessage
                        msg.Value = i + 1
                        Try
                            _detail.Insert(_id)
                            msg.ID = 1
                            msg.Code = "SUCCESS"
                            msg.Message = "Excel行[" & i + 1 & "][" & _detail.BillNo & "]已存入临时库。"
                            rv.Messages.Add(msg)
                        Catch ex As Exception
                            hasErrorOccured = True
                            msg.ID = -1
                            msg.Code = Err.Source
                            msg.Message = "Excel行[" & i + 1 & "][" & _detail.BillNo & "]发生错误:" & ex.Message
                            rv.Errors.Add(msg)
                        End Try
                    Next
                    If hasErrorOccured Then
                        rv.Result = -1
                    Else
                        rv.Result = 1
                    End If
                    rv.Value = _id
                End If
            End If
            Return rv
        End Function
        ''' <summary>
        ''' r如果传递过来的数据包ID值为空，则从服务器端生成一个ID
        ''' </summary>
        ''' <returns></returns>
        Private Function GetMissinID() As String
            Dim fd As New Foundation.Database.TGUID
            Return fd.GUID
        End Function
    End Class
End Namespace