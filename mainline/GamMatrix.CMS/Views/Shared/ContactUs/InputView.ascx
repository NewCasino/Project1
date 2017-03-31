<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script language="C#" runat="server" type="text/C#">
    internal class TitleComparer : IEqualityComparer<KeyValuePair<string, string>>
    {
        public bool Equals(KeyValuePair<string, string> x, KeyValuePair<string, string> y)
        {
            return string.Compare(x.Value, y.Value, true) == 0;
        }

        public int GetHashCode(KeyValuePair<string, string> obj)
        {
            return obj.Value.GetHashCode();
        }
    }
    private SelectList GetSubjectList()
    {
        Dictionary<string, string> subjectList = new Dictionary<string, string>();
        subjectList.Add("", this.GetMetadata(".Subject_Choose"));
        foreach (string path in Metadata.GetChildrenPaths("/Metadata/ContactUs/Subjects"))
        {
            subjectList.Add(this.GetMetadata(path + ".Value"), this.GetMetadata(path + ".Text"));
        }
        var list = subjectList.AsEnumerable().Where(t => !string.IsNullOrWhiteSpace(t.Value)).Distinct(new TitleComparer());
        string selectedValue = Request["subject"].DefaultIfNullOrEmpty(string.Empty);
        return new SelectList(list, "Key", "Value", selectedValue);
    }
    protected override void OnPreRender(EventArgs e)
    {
        scriptSubject.Visible = string.Equals(this.GetMetadata(".Subject_IsUseSelector").ToString(), "yes", StringComparison.InvariantCultureIgnoreCase);
        fldSubjectSelect.Visible = scriptSubject.Visible;
    }
</script>
<% using (Html.BeginRouteForm("ContactUs", new { @action = "Send" }, FormMethod.Post, new { @id = "formContactUs" }))
   { %>
<br />
<% if (!Profile.IsAuthenticated)
   { %>

<%------------------------------------------
    Your email
 -------------------------------------------%>
<ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></labelpart>
    <controlpart>
        <%: Html.TextBox("email", "", new
            {
                @maxlength = 50,
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Email_Empty")).Email(this.GetMetadata(".Email_Invalid"))
            })%>
	</controlpart>
</ui:InputField>

<%------------------------------------------
    Your name
 -------------------------------------------%>
<ui:InputField ID="fldName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".Name_Label").SafeHtmlEncode()%></labelpart>
    <controlpart>
        <%: Html.TextBox("name", "", new
            {
                @maxlength = 50,
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Name_Empty"))
            })%>
	</controlpart>
</ui:InputField>

<% } %>

<%------------------------------------------
    Subject
 -------------------------------------------%>
<ui:InputField ID="fldSubject" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".Subject_Label").SafeHtmlEncode()%></labelpart>
    <controlpart>
        <%: Html.TextBox("subject", "", new
            {
                @maxlength = 100,
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Subject_Empty"))
            })%>
	</controlpart>
</ui:InputField>

<%------------------------------------------
    Subject2
 -------------------------------------------%>
<ui:InputField ID="fldSubjectSelect" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".Subject_Label").SafeHtmlEncode() %></labelpart>
    <controlpart>
	    <%: Html.DropDownList("subject2"
            , GetSubjectList()
            , new { @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Subject_Empty")) }
            )%>
	</controlpart>
</ui:InputField>

<ui:MinifiedJavascriptControl runat="server" ID="scriptSubject" AppendToPageEnd="true"
    Enabled="false">
    <script type="text/javascript">
        $(function () {
            $("#fldSubject").hide();
            $("#subject2").change(function () { $("#subject").val($(this).val()).keyup() });
        });
    </script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    Content
 -------------------------------------------%>
<ui:InputField ID="fldContent" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".Content_Label").SafeHtmlEncode()%></labelpart>
    <controlpart>
        <%: Html.TextArea("content", "", new
            {
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Content_Empty"))
            })%>
	</controlpart>
</ui:InputField>

<%------------------------------------------
    Captcha
 -------------------------------------------%>
<% Html.RenderPartial("/Components/Captcha", this.ViewData); %>


<center>
    <%: Html.Button(this.GetMetadata(".Button_Submit"), new { @id = "btnSendContactUsEmail", @type = "submit" })%>
</center>

<% } %>

<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formContactUs').initializeForm();
        $('#btnSendContactUsEmail').click(function (e) {

            e.preventDefault();

            if (!$('#formContactUs').valid())
                return;

            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#btnSendContactUsEmail').toggleLoadingSpin(false);
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                    alert('<%= this.GetMetadata(".Success_Message").SafeJavascriptStringEncode() %>');
                    self.location = self.location.toString().replace(/(\#.*)$/, '');
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnSendContactUsEmail').toggleLoadingSpin(false);
                }
            };
            $('#formContactUs').ajaxForm(options);
            $('#formContactUs').submit();
        });

    });
</script>
