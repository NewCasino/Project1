<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server"> </asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
  <div id="deposit-wrapper" class="content-wrapper">
    <%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
    <ui:Panel runat="server" ID="pnDeposit">
      <div id="cancel_step">
        <center>
          <br />
          <%: Html.WarningMessage( this.GetMetadata(".Message") ) %>
        </center>
      </div>
    </ui:Panel>
  </div>
  <% 
    string _local_connection_key = Profile.IsAuthenticated ? Profile.UserID.ToString() : "0"; 
%>
  <div style="position: absolute; left: -9999px; top: -9999px; width:1px; height:1px; overflow:hidden" id="local-helper-place-container">
    <%if (Request.Browser.Type.Equals("IE9", StringComparison.OrdinalIgnoreCase) || Request.Browser.Type.Equals("IE8", StringComparison.OrdinalIgnoreCase) || Request.Browser.Type.Equals("IE7", StringComparison.OrdinalIgnoreCase))
  { %>
    <div id="local-helper-holder"></div>
    <script type="text/javascript">
      function includeLocalHelper() {
          var url = "https://cdn.everymatrix.com/_js/local_helper.swf";
          var params = {
              menu: "false",
              seamlesstabbing: 'false',
              allowScriptAccess: 'always',
              allowNetworking: 'all'
          };
          var attributes = {
              id: "local-helper",
              name: "local-helper"
          };
          var flashvars = {
              local: "_<%=_local_connection_key %>_sender",
              remote: "_<%=_local_connection_key %>_receiver"
          };

          swfobject.embedSWF(url, "local-helper-holder", "1px", "1px", '9.0', null, flashvars, params, attributes);
      }

      $(function () {
          window.setTimeout(function () { includeLocalHelper(); }, 1500);
      });
  </script>
    <%}
  else { %>
    <object width="1px" height="1px" type="application/x-shockwave-flash" id="local-helper" name="local-helper" data="//cdn.everymatrix.com/_js/local_helper.swf">
      <param name="menu" value="false" />
      <param name="seamlesstabbing" value="false" />
      <param name="allowScriptAccess" value="always" />
      <param name="allowNetworking" value="all" />
      <param name="flashvars" value="local=_<%=_local_connection_key %>_sender&amp;remote=_<%=_local_connection_key %>_receiver" />
      <embed  type="application/x-shockwave-flash" 
                width="1px" 
                height="1px"
                allowScriptAccess="always" 
                allowNetworking="all" 
                seamlesstabbing="false" 
                wmode = "direct" 
                menu = "false" 
                pluginspage="https://get.adobe.com/cn/flashplayer/" 
                flashvars = "local=_<%=_local_connection_key %>_sender&amp;remote=_<%=_local_connection_key %>_receiver" 
                src="https://cdn.everymatrix.com/_js/local_helper.swf" > </embed>
    </object>
    <%} %>
  </div>
  <script language="javascript" type="text/javascript">
      try {
          $(".ConfirmationBox.simplemodal-container", parent.document.body).hide();
          if ($(".ConfirmationBox.simplemodal-container", parent.document.body).length > 0 && parent.location.href != this.location.href) {
              parent.location.href = this.location.href;
          }

      } catch (err) { console.log(err); }
    var url = '<%= this.Url.RouteUrl( "Deposit", new { @action = "Cancel" }).SafeJavascriptStringEncode() %>';
    var success = false;

    try { if (self.opener !== null && self.opener != self) { opener.location = url; success = true; } } catch (e) { }

    if (success) {
        closeSelf();
    }

    function closeSelf() {
        top.window.opener = top;
        top.window.open('', '_parent', '');
        top.window.close();
    }

    // callbacks
    function __localHelperSwfLoaded(success, connID, msg) {
        if (success) {
            setTimeout(function () { __sendMessage('onMsgSent', url, ''); }, 0);
        }
    }

    // export functions
    function __sendMessage(callback, _url, _method) {
        try {
            var ret = document.getElementById('local-helper').sendMessage(callback, _url, _method);
            return ret == true;
        }
        catch (e) {
            return false;
        }
    }

    function onMsgSent(ret) {
        if (ret == '1') {
            closeSelf();
        }
    }    
</script> 
</asp:Content>
