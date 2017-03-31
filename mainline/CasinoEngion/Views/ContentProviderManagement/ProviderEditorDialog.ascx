<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<CE.db.ceContentProviderBase>" %>

<script runat="server" type="text/C#">

    private string GetLogoImage()
    {
        if (string.IsNullOrWhiteSpace(this.Model.Logo))
            return "//cdn.everymatrix.com/images/placeholder.png";
        
        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , this.Model.Logo
            );
    }
    
</script>

<form id="formEditProvider" target="ifmSaveProvider" method="post"  enctype="multipart/form-data" action="<%= this.Url.ActionEx("Save").SafeHtmlEncode() %>">

    <%: Html.Hidden("id", this.Model.ID)%>
    
    <div id="table-editor-tabs">
        <ul>
            <li>
                <a href="#tab1">Content Provider</a>
            </li>
        </ul>
        <div id="tab1">
            <%if (DomainManager.CurrentDomainID == Constant.SystemDomainID) { %>

            <%if (CurrentUserSession.IsSystemUser) { %>
            <p>
                <label class="label">ID: </label>
                <%: Html.TextBox("identifying", this.Model.Identifying, new { @id = "txtInputIdentifying", @class = "textbox" })%>
            </p>
            <script type="text/javascript">
                $(function () {
                    var fun = function () {
                        var identifying = $('#txtInputIdentifying').val();
                        var regex = /[^a-zA-Z_\-\d]/gi;
                        identifying = identifying.replace(regex, '-');
                        $('#txtInputIdentifying').val(identifying);
                    };
                    $('#txtInputIdentifying').change(fun).blur(fun).click(fun);

                    $('#txtInputIdentifying').keypress(function (e) {                        
                        if ((e.which >= 48 && e.which <= 57) ||
                            (e.which >= 97 && e.which <= 122) ||
                            (e.which >= 65 && e.which <= 90) ||
                            e.which == 95 || e.which == 45 ||
                            e.which == 8 || e.which == 0) {
                        }
                        else {
                            e.preventDefault();
                        }
                    });
                });
            </script>
            <%} %>
            
            <p>
                <label class="label">Name: </label>
                <%: Html.TextBox("name", this.Model.Name, new { @id = "txtInputName", @class = "textbox" })%>
            </p>
            <%} %>            
            <p>
                <label class="label">Logo: </label>
                <img src="<%=GetLogoImage() %>" style="max-width:114px; max-height:114px; border:0px;">
                <br />
                <input type="file" name="logoFile" style="width:240px" />
            </p>

            <div>
            <% if(DomainManager.AllowEdit()) { %>
            <button type="submit" id="btnSave">Save</button>
            <% } %>
            </div>
        </div>

        
    </div>
</form>

<iframe id="ifmSaveProvider" name="ifmSaveProvider" style="display:none"></iframe>

<script type="text/javascript">
    $(function () {
        $('#table-editor-tabs').tabs();

        $('#btnSave').button({
            icons: {
                primary: "ui-icon-disk"
            }
        });

        self.onSaved = function (success, error) {
            $('#loading').hide();
            if (!success)
                alert(error);
            else {                
                if (window.confirm('The operation has been completed successfully! \n Do you want to refresh the list?'))
                    try { parent.loadProviderList(); } catch (ex) { }
                $.modal.close();
            }
        }
    });
</script>