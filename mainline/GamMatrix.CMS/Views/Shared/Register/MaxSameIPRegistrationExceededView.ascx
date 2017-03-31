<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<br />
<br />
<br />
<%: Html.ErrorMessage( this.GetMetadata(".Blocked_Message").Replace("[IP]", Request.GetRealUserAddress()).Replace("[COUNT]", Settings.Registration.SameIPLimitPerDay.ToString()) ) %>
<br />
<br />