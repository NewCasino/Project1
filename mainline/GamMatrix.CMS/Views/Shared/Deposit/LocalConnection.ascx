<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

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
              local: "_<%=_local_connection_key %>_receiver",
              remote: "_<%=_local_connection_key %>_sender"
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
        <param name="flashvars" value="local=_<%=_local_connection_key %>_receiver&amp;remote=_<%=_local_connection_key %>_sender" />

        <embed  type="application/x-shockwave-flash" 
                width="1px" 
                height="1px"
                allowScriptAccess="always" 
                allowNetworking="all" 
                seamlesstabbing="false" 
                wmode = "direct" 
                menu = "false" 
                pluginspage="https://get.adobe.com/cn/flashplayer/" 
                flashvars = "local=_<%=_local_connection_key %>_receiver&amp;remote=_<%=_local_connection_key %>_sender" 
                src="https://cdn.everymatrix.com/_js/local_helper.swf" >
        </embed>

    </object>
<%} %>
</div>
<script type="text/javascript">
    // callbacks
    function __localHelperSwfLoaded(success, connID, msg) {
        //Initliazrion :  success
        if (success) {
            var _success = success;
        }
    }

    function __messageReceived(conn, _url, _method) {
        if (onLocalMessageReceived(_url, _method)) {
            return '1';
        }

        return '0';
    }

    function onLocalMessageReceived(_url, _method) {
        if (_method && _method != '') {
            try {
                window.setTimeout(function () { eval(_method); }, 1000);
                return true;
            } catch (e) { }
        }
        if (_url && _url != '') {
            window.setTimeout(function () { self.location = _url; }, 1000);
            return true;
        }

        return false;
    }
</script>