<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%
    bool isEnabled = this.GetMetadata("/Register/_DKVerifyFrame_aspx.EnabledVerifyFrame").DefaultIfNullOrEmpty("No").Equals("yes", StringComparison.InvariantCultureIgnoreCase);
    bool isIDQEnabled = this.GetMetadata("/Register/_DKVerifyFrame_aspx.EnabledIDQCheck").DefaultIfNullOrEmpty("Yes").Equals("yes", StringComparison.InvariantCultureIgnoreCase);
%>
<script language="javascript" type="text/javascript"> 
    var isDKCheck = <%=Settings.IsDKLicense.ToString().ToLower()%> ;
    var isIDQEnabled = <%=isIDQEnabled.ToString().ToLower()%>;
    var __Registration_Legal_Age = 18;
    var isTemporaryAccountEnabled = false; 
    $(document).ready(function () {
        $('#formRegister').initializeForm();
        $(document).bind("COUNTRY_SELECTION_CHANGED", function (e, data) {
            __Registration_Legal_Age = data.LegalAge;
        });
    });
    $(document).bind('REGISTER_FORM_SUBMIT', function (e, data) {
        submitRegister();
    });
    function submitRegister(){
        //console.log("Thanks for your register");
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
            }
        };
        $('#formRegister').ajaxForm(options);
        $('#formRegister').submit();
    }
</script>

<%if (isEnabled)
    { %>
<script language="javascript" type="text/javascript">
    //<![CDATA[ 
    $(document).ready(function () { 
        $('#btnRegisterUser').click(function (e) {
            e.preventDefault();
            if (!$('#formRegister').valid())
                return;
            if ($('#txtPassport').length > 0 && !$('#txtPassport').valid()) {
                return;
            }
            $(this).toggleLoadingSpin(true);  
            try{ebRegister._merginAllFields();}catch(err){}
            if(isTemporaryAccountEnabled){
                if(isDKCheck  && $("#ddlCountry").val()==64 && $("#btnHasDKAccount").attr("checked") !="checked")
                {
                    $("#txtUsername").val($(".CPRDOBDay").text().toString() + $(".CPRDOBMonth").text().toString() + $(".CPRDOBYear").text().toString() + $("#txtCPRNumber").val().toString());
                    $("#txtPassword,#txtRepeatPassword").val("<%=  (DateTime.Now.Ticks.ToString())  %>"+ $(".CPRDOBDay").text().toString() + $(".CPRDOBMonth").text().toString() + $(".CPRDOBYear").text().toString() + $("#txtCPRNumber").val().toString());
                    $("#txtPersonalID").val($(".CPRDOBDay").text().toString() + $(".CPRDOBMonth").text().toString() + $(".CPRDOBYear").text().toString() + $("#txtCPRNumber").val().toString());
                    $("#ddlSecurityQuestion").val($(top.document).find("#ddlSecurityQuestion option").eq(1).val());
                    $("#txtSecurityAnswer").val($("#txtEmail").val());
                    if(isDKCheck  && $("#ddlCountry").val()==64){
                        $('#btnRegisterUser').toggleLoadingSpin(false); 
                        $(document).trigger('COUNTRY_SELECTION_CHANGED_DKPOPUP'); 
                    }
                    return;
                }else{
                    submitRegister(); 
                }
            }else{
                if(isDKCheck  && $("#ddlCountry").val()==64 && $("#btnHasDKAccount").attr("checked") !="checked")
                {
                    if(isIDQEnabled){
                        var address = $("#txtAddress1").val() + $("#txtAddress2").val();
                        if ($('#txtStreetName').length > 0) {
                            address = $('#txtStreetName').val() + ' ' + $('#txtStreetNumber').val();
                        }
                        $.ajax({
                            type: "GET",
                            url: "/Register/DKVerifyJson",
                            data: {
                                cpr: $(".CPRDOBDay").text().toString() + $(".CPRDOBMonth").text().toString() + $(".CPRDOBYear").text().toString() + $("#txtCPRNumber").val().toString(), 
                                address: address,
                                birthDate:$("#ddlYear").val()+"-"+$("#ddlMonth").val()+"-"+$("#ddlDay").val(),
                                userFirstName:$("#txtFirstname").val(),
                                userLastName:$("#txtSurname").val()
                            },
                            dataType: "json",
                            success: function(data){
                                var sdata ;
                                try{
                                    sdata = JSON.parse(data.data);
                                    if(sdata.CprValidationStatus == 1 ){
                                        $("#txtUsername").val($(".CPRDOBDay").text().toString() + $(".CPRDOBMonth").text().toString() + $(".CPRDOBYear").text().toString() + $("#txtCPRNumber").val().toString());
                                        $("#txtPassword,#txtRepeatPassword").val("<%=  (DateTime.Now.Ticks.ToString())  %>"+ $(".CPRDOBDay").text().toString() + $(".CPRDOBMonth").text().toString() + $(".CPRDOBYear").text().toString() + $("#txtCPRNumber").val().toString());
                            //if($("#txtPersonalID").val() == "")
                            $("#txtPersonalID").val($(".CPRDOBDay").text().toString() + $(".CPRDOBMonth").text().toString() + $(".CPRDOBYear").text().toString() + $("#txtCPRNumber").val().toString());
                            $("#ddlSecurityQuestion").val($(top.document).find("#ddlSecurityQuestion option").eq(1).val());
                            $("#txtSecurityAnswer").val($("#txtEmail").val());
                                    
                            if(isDKCheck  && $("#ddlCountry").val()==64){
                                $('#btnRegisterUser').toggleLoadingSpin(false);
                                //if($("#fldUsername input").val()==""){ 
                                $(document).trigger('COUNTRY_SELECTION_CHANGED_DKPOPUP');
                                return;
                                //}
                            }
                            //submitRegister();
                        }else{
                            if(sdata.InvalidInputs.cpr!=null){
                                alert(sdata.InvalidInputs.cpr);
                            }
                            else if(sdata.InvalidInputs.address != null){
                                alert(sdata.InvalidInputs.address);
                            }
                            else if(sdata.InvalidInputs.userFullName != null){
                                alert(sdata.InvalidInputs.userFullName);
                            }
                            else{
                                alert(sdata.InternalError);
                            }
                            $('#btnRegisterUser').toggleLoadingSpin(false);
                        }
                    }else{
                        if(isDKCheck  && $("#ddlCountry").val()==64){
                            $('#btnRegisterUser').toggleLoadingSpin(false); 
                            $(document).trigger('COUNTRY_SELECTION_CHANGED_DKPOPUP');
                            return; 
                        }
                    }    
                }catch(err){
                    //console.log(err);
                    alert(err);
                    $('#btnRegisterUser').toggleLoadingSpin(false);
                }  
            }
        });
    }else{
        submitRegister();
    }
}
        });
    }); 
//]]>
</script>
<%
    }
    else
    {
%>
<script language="javascript" type="text/javascript"> 
    $(document).ready(function () { 
        $('#btnRegisterUser').click(function (e) {
            e.preventDefault();
            if (!$('#formRegister').valid())
                return;
            if ($('#txtPassport').length > 0 && !$('#txtPassport').valid()) {
                return;
            }
            $(this).toggleLoadingSpin(true);  
            try{ebRegister._merginAllFields();}catch(err){}
            if(isDKCheck  && $("#ddlCountry").val()==64 && $("#btnHasDKAccount").attr("checked") !="checked")
            {
                var address = $("#txtAddress1").val();
                if ($('#txtStreetName').length > 0) {
                    address = $('#txtStreetName').val() + ' ' + $('#txtStreetNumber').val();
                }
                $.ajax({
                    type: "GET",
                    url: "/Register/DKVerifyJson",
                    data: {
                        cpr: $("#preCPRNumber").val() + $("#txtCPRNumber").val().toString(), 
                        //$(".CPRDOBDay").text().toString() + $(".CPRDOBMonth").text().toString() + $(".CPRDOBYear").text().toString() + $("#txtCPRNumber").val().toString(), 
                        address: address,
                        // + $("#txtAddress2").val(),
                        birthDate:$("#ddlYear").val()+"-"+$("#ddlMonth").val()+"-"+$("#ddlDay").val(),
                        userFirstName:$("#txtFirstname").val(),
                        userLastName:$("#txtSurname").val()
                    },
                    dataType: "json",
                    success: function(data){
                        var sdata ;
                        try{
                            sdata = JSON.parse(data.data);
                            if(sdata.CprValidationStatus == 1 ){
                                $("#txtPersonalID").val( $("#preCPRNumber").val() + $("#txtCPRNumber").val().toString());
                                if(isDKCheck  && $("#ddlCountry").val()==64){
                                    $('#btnRegisterUser').toggleLoadingSpin(false);
                                    submitRegister(); 
                                    return; 
                                } 
                            }else{
                                if(sdata.InvalidInputs.cpr!=null){
                                    alert(sdata.InvalidInputs.cpr);
                                }
                                else if(sdata.InvalidInputs.address != null){
                                    alert(sdata.InvalidInputs.address);
                                }
                                else if(sdata.InvalidInputs.userFullName != null){
                                    alert(sdata.InvalidInputs.userFullName);
                                }
                                else{
                                    alert(sdata.InternalError);
                                }
                                $('#btnRegisterUser').toggleLoadingSpin(false);
                            }
                        }catch(err){
                            console.log(err); 
                            $('#btnRegisterUser').toggleLoadingSpin(false);
                        }  
                    }
                });
            }else{
                submitRegister();
            }
        });
    });

//]]>
</script>
<%} %> 
