<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="GmCore" %>

<script type="text/C#" runat="server">
    private bool Succeed { get; set; }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        Succeed = true;
        return;

        if (this.ViewData["Sid"] == null)
        {
            Succeed = false;
            return;
        }

        var sid = this.ViewData["Sid"].ToString();
        if (string.IsNullOrWhiteSpace(sid))
        {
            Succeed = false;
            return;
        }

        PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
        if (prepareTransRequest == null)
            throw new ArgumentOutOfRangeException("sid");

        ProcessTransRequest processTransRequest = cmTransParameter.ReadObject<ProcessTransRequest>(sid, "ProcessTransRequest");
        if (processTransRequest != null)
        {
            processTransRequest.InputValue1 = cmTransParameter.Unmask(sid, "InputValue1", processTransRequest.InputValue1);
            processTransRequest.InputValue2 = cmTransParameter.Unmask(sid, "InputValue2", processTransRequest.InputValue2);
            processTransRequest.SecretKey = cmTransParameter.Unmask(sid, "SecurityKey", processTransRequest.SecretKey);
        }
        ProcessAsyncTransRequest processAsyncTransRequest = cmTransParameter.ReadObject<ProcessAsyncTransRequest>(sid, "ProcessAsyncTransRequest");
        if (processAsyncTransRequest != null)
        {
            processAsyncTransRequest.SecretKey = cmTransParameter.Unmask(sid, "SecurityKey", processAsyncTransRequest.SecretKey);
        }
        GetTransInfoRequest getTransInfoRequest = null;
        string lastError = cmTransParameter.ReadObject<string>(sid, "LastError");


        try
        {
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                {
                    SID = sid,
                    NoDetails = true,
                });
            }
            this.ViewData["getTransInfoRequest"] = getTransInfoRequest;
            this.ViewData["prepareTransRequest"] = prepareTransRequest;
            this.ViewData["processTransRequest"] = processTransRequest;
            this.ViewData["processAsyncTransRequest"] = processAsyncTransRequest;

            PreTransStatus preTransStatus = getTransInfoRequest.TransData.Status;
            TransStatus transStatus = getTransInfoRequest.TransData.TransStatus;

            cmTransParameter.DeleteSecurityKey(sid);

            if (transStatus == TransStatus.Success)
            {
                Succeed = true;
            }
        }
        catch
        {
            Succeed = false;
        }
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">

<script language="javascript" type="text/javascript">
    try {
        if (window.parent != window.self) {
            <% if (Succeed)
               { %>
            parent.window.$(parent.document).trigger('QUICK_DEPOSIT_SUCESSED');
            <% }
               else
               { %>
            parent.window.$(parent.document).trigger('QUICK_DEPOSIT_FAILED');
            <% } %>
        }
    } catch (ex) { }
</script>
</asp:content>

