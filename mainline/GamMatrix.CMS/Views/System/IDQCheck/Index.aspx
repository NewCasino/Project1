<%@ Page Language="C#" MasterPageFile="~/Views/System/TopBar.master" Inherits="CM.Web.ViewPageEx<dynamic>"%>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.ui/jquery-ui-timepicker-addon.min.js") %>" ></script>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/LogViewer/Index.css") %>" />
    <style type="text/css">
        #IDQCheck-viewer-form-wrapper{padding: 10px;}
        .IDQCheck-description, input, button{margin: 10px 0;}
        .IDQCheck-result{color: red; margin-top: 20px;}
    </style>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="IDQCheck-viewer-form-wrapper">
    <div class="IDQCheck-description">please upload your excel or csv file and click the "IDQ Check" button to check the IDQ for all user in the file you uploaded.</div>
<form method="post" id="formIDQCheck" action="/IDQCheck.ashx"  enctype="multipart/form-data">
<input type="file" id="fileUpload" name="fileUpload" value="Upload File" />
<div class="buttons-wrap">
    <button id="btnIDQCheck">IDQ Check</button>
</div>
</form>
<div class="IDQCheck-result"></div>
<script type="text/javascript">
    $(function () {
        jQuery.extend({
            handleError: function (s, xhr, status, e) {
                if (s.error) {
                    s.error.call(s.context || s, xhr, status, e);
                }
                if (s.global) {
                    (s.context ? jQuery(s.context) : jQuery.event).trigger("ajaxError", [xhr, s, e]);
                }
            },
            httpData: function (xhr, type, s) {
                var ct = xhr.getResponseHeader("content-type"),
        xml = type == "xml" || !type && ct && ct.indexOf("xml") >= 0,
        data = xml ? xhr.responseXML : xhr.responseText;
                if (xml && data.documentElement.tagName == "parsererror")
                    throw "parsererror";
                if (s && s.dataFilter)
                    data = s.dataFilter(data, type);
                if (typeof data === "string") {
                    if (type.toLowerCase() == "script")
                        jQuery.globalEval(data);
                    if (type.toLowerCase() == "json")
                    {
                        if (data.indexOf("<pre") >= 0)
                        {
                            var m = data.match(new RegExp('<pre.*>.*</pre>'))[0];
                            m = m.substring(m.indexOf(">") + 1);
                            data = m.substring(0, m.indexOf("<"));
                        }
                        else if (data.indexOf('<body') >= 0)
                        {
                            var m = data.match(new RegExp('<body.*>.*</body>'))[0];
                            m = m.substring(m.indexOf(">") + 1);
                            data = m.substring(0, m.indexOf("<"));
                        }
                        data = window["eval"]("(" + data + ")");
                    }
                        
                }
                return data;
            }
        });

        $('#btnIDQCheck').click(function () {
            $('.IDQCheck-result').html('');
            var options = {
                //iframe: false,
                dataType: "JSON",
                type: "POST",
                success: function (data) {
                    if (data.success) {
                        $('.IDQCheck-result').html(data.message.replace(/&lt;/g,'<').replace(/&gt;/g, '>'));
                    } else {
                        $('.IDQCheck-result').html(data.message.replace(/&lt;/g, '<').replace(/&gt;/g, '>'));
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('.IDQCheck-result').html(errorThrown.message);
                }
            };
            $('#formIDQCheck').ajaxForm(options);
            //$('#formIDQCheck').submit();
        });
    });
    
</script>
</div>
</asp:Content>
