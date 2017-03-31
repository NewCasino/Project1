<%@ Page Title="File Diff" Language="C#" Inherits="CM.Web.ViewPageEx<ArrayList>"%>
<%@ Import Namespace="GamMatrix.Infrastructure.DifferenceEngine" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Diff Tool</title>
<style type="text/css">
html, body { margin:0px; padding:0px; font-family:Courier New; font-size:12px; }
span { white-space:pre-wrap; }
.line { width:100%; border-bottom: dotted 1px #DDDDDD }
.line0 .source { background-color:#F7F5EE; }
.line1 .source { background-color:#ECE9D8; }
.line0 .dest { background-color:#FFFFFF; }
.line1 .dest { background-color:#D8ECE9; }
.line .source { width:46%; display:inline-block; }
.line .dest { width:46%; display:inline-block; }
.deletesource .source span { text-decoration:line-through; color:#666666; background-color:Yellow; }
.replace .source span { text-decoration:line-through; color:#333333; background-color:Yellow; }
.replace .dest span { background-color:#99FF66; }
.adddestination .dest span { background-color:#99FF66; }

.num { width:30px; font-size:12px; padding:0px; display:inline-block; text-align:right; }
</style>
</head>
<body>


<% 
    DiffList_TextFile sLF = this.ViewData["sLF"] as DiffList_TextFile;
    DiffList_TextFile dLF = this.ViewData["dLF"] as DiffList_TextFile;
    int index = 0;
    ArrayList diffLines = this.Model;
    foreach (DiffResultSpan drs in diffLines)
    {
        for (int i = 0; i < drs.Length; i++)
        {
            string srcLine = (drs.SourceIndex >= 0) ? ((TextLine)sLF.GetByIndex(drs.SourceIndex + i)).Line : null;
            string destLine = (drs.DestIndex >= 0) ? ((TextLine)dLF.GetByIndex(drs.DestIndex + i)).Line : null;
            %>
   <div class="line line<%: (index++%2) %> <%: drs.Status.ToString().ToLowerInvariant() %>">
    <div class="num"><%: index %></div>
    <div class="source">
    <span>&nbsp;<%= srcLine.SafeHtmlEncode() %></span>
    </div>
    <div class="dest">
    <span>&nbsp;<%= destLine.SafeHtmlEncode()%></span>
    </div>
   </div>
<%     }
   } %>

</body>
</html>
