<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script type="text/javascript">
    window.location = "/Login/?redirect=<%=HttpUtility.UrlEncode(HttpContext.Current.Request.RawUrl)%>";
</script>