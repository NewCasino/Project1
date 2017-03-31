<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<script language="javascript" type="text/javascript">
//<![CDATA[
    var __Registration_Legal_Age = 18;

    $(document).ready(function () {
        $('#formRegister').initializeForm();
        

        $('#btnRegisterUser').click(function (e) {
            e.preventDefault();

            if (!$('#formRegister').valid())
                return;

            $(this).toggleLoadingSpin(true);

            var options = {
                iframe: false,
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $('#btnRegisterUser').toggleLoadingSpin(false);
                    $('div.register-input-view').html(html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnRegisterUser').toggleLoadingSpin(false);
                    //alert(errorThrown);
                }
            };
            $('#formRegister').ajaxForm(options);
            $('#formRegister').submit();
        });
    });
//]]>
</script>