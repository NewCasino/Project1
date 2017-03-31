<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%=this.GetMetadata(".Html")%>

<script type="text/javascript">
    $('html').addClass('MobilePage');
    $(function () {
        var isMobile = $.browser.mobile; /* update this variable to contain mobile device detection */
        if (isMobile) {
            $('.MBLLItem.MBSite').css('display', 'none');
        } else {
            $('.MBLLLink').each(function (e) {
                var el = $(this);
                el.siblings('.MobileBigQR').slideUp(100);
                el.parents('.MBLLItem').removeClass('ActiveItem');
            });

            $('.MobileBigLinks').delegate('.MBLLLink', 'click', function (e) {
                e.preventDefault();
                var el = $(this);
                if (el.parents('.MBLLItem').hasClass('ActiveItem')) { /* collapse */
                    el.siblings('.MobileBigQR').slideUp(100);
                    el.parents('.MBLLItem').removeClass('ActiveItem');
                } else { /* expand */
                    //$('.MobileBigQR').slideUp( 100, function () {
                    $('.MobileBigQR').slideUp(100);
                    $('.MBLLItem').removeClass('ActiveItem');
                    el.siblings('.MobileBigQR').slideDown(500, function () {
                        el.parents('.MBLLItem').addClass('ActiveItem');
                    });
                    //});
                }
            });

            var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
            for (var i = 0; i < hashes.length; i++) {
                hash = hashes[i].split('=');
                if (hash[0] == 'QR') {
                    if (hash[1] == 'iOS') {
                        $('.MBiOS .MBLLLink').click();
                    } else {
                        $('.MBAndroid .MBLLLink').click();
                    }
                }
            }
        }
    });

</script>
</asp:Content>

