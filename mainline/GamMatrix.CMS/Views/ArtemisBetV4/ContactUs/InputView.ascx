<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<% using (Html.BeginRouteForm("ContactUs", new { @action = "Send" }, FormMethod.Post, new { @id = "formContactUs" , @class= "formContactUs"}))
   { %>

  
<% if (!Profile.IsAuthenticated)
   { %>
<div class="v-detail">
    <div class="v-title">
        <%=this.GetMetadata(".Visitor_Title")%>
    </div>
    <%------------------------------------------
    Your email
 -------------------------------------------%>
    <ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <labelpart><%=this.GetMetadata(".Email_Label")%></labelpart>
        <controlpart>
        <%: Html.TextBox("email", "" , new
            {
                @maxlength = 50,
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Email_Empty")).Email(this.GetMetadata(".Email_Invalid"))
            })%>
        <%: Html.TextBox("w_email", "",  new
            {
                @class=" warteBox ", 
                @showvalue=this.GetMetadata(".Email_Label")
            })%>
 
</controlpart>
    </ui:InputField>

    <%------------------------------------------
    Your name
 -------------------------------------------%>
    <ui:InputField ID="fldName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <labelpart><%=this.GetMetadata(".Name_Label")%></labelpart>
        <controlpart>
        <%: Html.TextBox("name", "", new
            {
                @maxlength = 50,
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Name_Empty"))
            })%>
        <%: Html.TextBox("w_name", "", new
            {
                @class=" warteBox ",
                @showvalue= this.GetMetadata(".Name_Label")
            })%>
 
</controlpart>
    </ui:InputField>
</div>
<% } %>

<div class="v-detail">


    <div class="v-title">
        <%=this.GetMetadata(".Subject_Title")%>
    </div>
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
        <%: Html.TextBox("w_subject", "", new
            {
                @class=" warteBox ",
               @showvalue=this.GetMetadata(".Subject_Label").SafeHtmlEncode()
            })%>
</controlpart>
    </ui:InputField>
</div>
<div class="v-detail">
    <div class="v-title">
        <%=this.GetMetadata(".Content_Title")%>
    </div>
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

        <%: Html.TextArea("w_content", "", new
            {
                @class=" warteBox ",
                @showvalue=this.GetMetadata(".Content_Label") 
            })%>
</controlpart>
    </ui:InputField>

    <%------------------------------------------
    Captcha
 -------------------------------------------%>
    <% Html.RenderPartial("/Components/Captcha", this.ViewData); %>
</div>


    <%: Html.Button(this.GetMetadata(".Button_Submit"), new { @id = "btnSendContactUsEmail", @type = "submit" })%>


<% } %>

<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formContactUs').initializeForm();
        $(".warteBox").each(function (i) {
            $(this).val($(this).attr("showvalue"));
            var oldid = $(this).attr("id").substring(2, $(this).attr("id").length);
            $("#" + oldid).hide();
            $(this).click(function () {
                $(this).val('');
            });
            $(this).focusout(function () {
                if ($(this).val() != '' && $(this).val() != $(this).attr("showvalue")) {
                    $(this).hide();
                    $("#" + oldid).val($(this).val()).show().focus();
                } else {
                    $(this).val($(this).attr("showvalue"));
                    $(this).show();
                    $("#" + oldid).hide();
                }
            });
        });
        $('#btnSendContactUsEmail').click(function (e) {
            $(".warteBox").each(function (i) {
                $(this).hide();
                var oldid = $(this).attr("id").substring(2, $(this).attr("id").length);
                $("#" + oldid).show();
            });
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
