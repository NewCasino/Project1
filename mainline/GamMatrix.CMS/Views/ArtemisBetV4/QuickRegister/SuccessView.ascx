<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%: Html.SuccessMessage(this.GetMetadata(Settings.Registration.RequireActivation ? ".Success_Message" : ".Success_Message_NotRequireActivation"), true)%>

<script language="javascript" type="text/javascript">
    $(".DialogTitle").html('<%= this.GetMetadata(".Title") %>');
    $(".DialogInfo").html('<%= this.GetMetadata(".TitleInfo") %>');
    $(".QRType").html('<%= this.GetMetadata(".QRType") %>');
    $(".QROffer").html('<%= this.GetMetadata(".QROffer") %>');
    $('#simplemodal-container', top.document.body).addClass("Step2");
    $("#register-wrapper").addClass("Step2");
    $('.topContentMain').remove();
    $(document).ready(function () {
            $('a.simplemodal-close', top.document.body).click(function(){
                try{ 
                    top.window.location="/"
                } catch(ex){}
            });
        setTimeout(function () { $(document).trigger("REGISTRATION_COMPLETED", ''); }, 5000);
        $.fn.extend({
            toggleLoadingSpinCustom: function (enable) {
                if (enable != true && enable != false)
                    enable = !$(this).hasClass('loading_Spin');
                if (enable) {
                    $(this).addClass('loading_Spin');
                    $('<div id="loading_block_all" style="display:flex;justify-content: center; align-items: center;position:absolute;left:0px;top:0px;width:100%;height:100%;background-color:black;filter: alpha(opacity=8);-moz-opacity:0.8;opacity: 0.8;z-index:99999999;"><div style="width: 48px; height: 48px; margin: 200px auto 0 auto; background: url(\"//cdn.everymatrix.com/Generic/img/loading.gif\") no-repeat scroll 0px 0px transparent; "></div></div>').appendTo(top.document.body);
                }
                else {
                    $(this).removeClass('loading_Spin');
                    setTimeout(function () { $('#loading_block_all',top.document.body).remove(); }, 30);
                    $('#loading_block_all',top.document.body).remove();
                }
                return $(this);
            }
        });
        $("#btnResendEmail").attr("href", "javascript:void(0)").click(function () {
            var $this = $(this);
            $this.toggleLoadingSpinCustom(true);
            var options = {
                url: '<%= this.Url.RouteUrl("Register", new{ @action="ResendVerificationEmail"}).SafeJavascriptStringEncode()%>',
                dataType: "json",
                type: 'GET',
                success: function (json) {
                    $this.toggleLoadingSpinCustom(false);
                    if (json.success) {
                        alert('<%=this.GetMetadata("/Register/_SuccessView_ascx.ResendEmail_Message_Success").SafeJavascriptStringEncode() %>');
                    }
                    else {
                        switch (json.errorCode) {
                            case 0:
                                alert('<%=this.GetMetadata("/Register/_SuccessView_ascx.ResendEmail_Message_Anonymous").SafeJavascriptStringEncode() %>');
                                break;
                            case 1:
                                alert('<%=this.GetMetadata("/Register/_SuccessView_ascx.ResendEmail_Message_Failed").SafeJavascriptStringEncode() %>');
                                break;
                            case 2:
                                alert('<%=string.Format(this.GetMetadata("/Register/_SuccessView_ascx.ResendEmail_Message_Limit"), 5).SafeJavascriptStringEncode() %>');
                                break;
                            default:
                                alert('<%=this.GetMetadata("/Register/_SuccessView_ascx.ResendEmail_Message_Failed").SafeJavascriptStringEncode() %>');
                                break;
                        }
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $this.toggleLoadingSpinCustom(false);
                }
            };

            $.ajax(options);
        });
    });
</script>
<script src="https://zz.connextra.com/dcs/tagController/tag/7d61b44fefd2/regconfirm?" async defer></script>