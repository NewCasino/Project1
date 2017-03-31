<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%
    Html.RenderPartial("/SelfExclusion/CoolOff"); 
%>
<%
    Html.RenderPartial("/SelfExclusion/SelfExclusion"); 
%>

<% Html.RenderPartial("/Components/DatePicker"); %>