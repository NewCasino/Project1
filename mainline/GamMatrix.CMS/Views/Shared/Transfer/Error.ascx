<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<center>
<br />
<%: Html.ErrorMessage(
    (this.ViewData["ErrorMessage"] as string).DefaultIfNullOrEmpty(
            this.Request["ErrorMessage"].DefaultIfNullOrEmpty( this.GetMetadata(".Message") ) 
                    )
    ) %>
</center>

