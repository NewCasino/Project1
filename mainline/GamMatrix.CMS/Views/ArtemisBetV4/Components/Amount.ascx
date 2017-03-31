<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">

    private string AmountType()
    {
        int countryId = Profile.UserCountryID != 0 ? Profile.UserCountryID : Profile.IpCountryID;
        string amountType = "0";
        string lang = HttpContext.Current.GetLanguage().ToLower();
        if (lang != "en")
        {
            string pathTempalte = "/Metadata/Settings/Deposit.AmountType{0}_Countries";
            for (int i = 0; i < 6; i++)
            {
                string path = string.Format(pathTempalte, i.ToString());
                string data = this.GetMetadata(path).Trim().DefaultIfNullOrEmpty("0");
                int[] datas = String2Int(data.Split(','));
                if (datas.Contains(countryId))
                {
                    amountType = i.ToString();
                }
            }
            if (countryId == 45 && lang == "fr")
            {
                amountType = "3";
            }
            if (countryId == 129 && lang == "de")
            {
                amountType = "1";
            }
            if (countryId == 129 && lang == "fr")
            {
                amountType = "3";
            }
        }
        return amountType;
    }
    private int[] String2Int(string[] sData)
    {
        int[] mData = new int[sData.Length];

        for (int i = 0; i < sData.Length; i++)
        {
            int num = 0;
            int.TryParse(sData[i], out num);
            mData[i] = num;
        }
        return mData;
    }
</script>
<%: Html.TextBox("amountbox", "0", 
    new { 
        @class = "txtMoneyAmount", 
        @id = "txtAmount", 
        @dir = "ltr", 
        @onchange="onAmountChange()",
        @onblur = "onAmountBlur()", 
        @onfocus = "onAmountFocus()", 
        @validator = CM.Web.UI.ClientValidators.Create().Custom("validateAmount") 
    })
%>
<%: Html.Hidden("amount", "0", new { 
        @id = "txtAmountVal"
})%>
<script type="text/javascript">
    var AmountType = <%=AmountType() %>;
    function GetRealAmount(num) {
        switch (AmountType) { 
            case 1: 
                num = num.toString().replace(/\$|\./g, '').replace(/\,/g, '.');
                break;
            case 2:
                num = num.toString().replace(/\$|\'/g, '');
                break;
            case 3:
                num = num.toString().replace(/\$|\ /g, '').replace(/\,/g, '.');
                break;
            case 4:
                num = num.toString().replace(/\$|\,/g, '').replace(/\//g, '.');
                break;
            case 5:
                num = num.toString().replace(/\$|\ /g, '').replace(/\-/g, '.');
                break;
            case 6:
                num = num.toString().replace(/\$|\ /g, '');
                break;
            default:
                num = num.toString().replace(/\$|\,/g, '');
                break;
        } 
        if (num.toString().length > 15) {
            if (isNaN(num)) num = '0';
            sign = (num == (num = Math.abs(num)));
            num = Math.floor(num * 100 + 0.50000000001);
            cents = num % 100;
            num = Math.floor(num / 100).toString();
            if (num.toString().length > 12) { 
                num = num.toString().substring(num.toString().length-12,num.toString().length); 
            }
            if (cents < 10) cents = '0' + cents;
            num =  num + "." + cents;
        }
        return num;
    }
    // <%-- Format the input amount to comma seperated amount --%>
    function formatAmounts(num, prefix, nextfix, haspre) {
        num = GetRealAmount(num); 
        num = num.toString().replace(/\$/g, '');
        switch(prefix){
            case ",":
                num = num.toString().replace(/\,/g,'') ;
                break;
            case " ":
                num = num.toString().replace(/\ /g,'') ;
                break;
            case ".":
                num = num.toString().replace(/\-/g,'') ;
                break;
            case "'":
                num = num.toString().replace(/\'/g,'') ;
                break; 
            default:
                break;
        }
        switch(nextfix){
            case ",":
                num = num.toString().replace(/\,/g,'.') ;
                break;
            case " ":
                num = num.toString().replace(/\ /g,'.') ;
                break;
            case "-":
                num = num.toString().replace(/\-/g,'.') ;
                break;
            case "/":
                num = num.toString().replace(/\//g,'.') ;
                break; 
            default:
                break;
        } 
        if (isNaN(num)) num = '0';
        sign = (num == (num = Math.abs(num)));
        num = Math.floor(num * 100 + 0.50000000001);
        cents = num % 100;
        num = Math.floor(num / 100).toString();
        
        if (num.toString().length > 12) { 
            num = num.toString().substring(num.toString().length-12,num.toString().length); 
        }

        if (cents < 10) cents = '0' + cents;
        if(haspre == true){
            for (var i = 0; i < Math.floor((num.length - (1 + i)) / 3) ; i++)
            {
                num = num.substring(0, num.length - (4 * i + 3)) + prefix + num.substring(num.length - (4 * i + 3));
            }
        } 
        return num + nextfix + cents;
    }
    function formatAmount(num, haspre) {
        num = num.toString().replace(/[^(\d|\.|\,|\'|\ |\-)]/g,"");
        switch (AmountType) {
            case 0:
                //1,234.56
                return formatAmounts(num,",",".",haspre);
                break;
            case 1:
                //1.234,56
                return formatAmounts(num,".",",",haspre);
                break;
            case 2:
                //1'234.56
                return formatAmounts(num,"'",".",haspre);
                break;
            case 3:
                //1 234,56
                return formatAmounts(num," ",",",haspre);
                break;
            case 4:
                //1,234/56
                return formatAmounts(num,",","/",haspre);
                break;
            case 5:
                //1 234-56
                return formatAmounts(num," ","-",haspre);
                break;
            case 6:
                //1 234.56
                return formatAmounts(num," ",".",haspre);
                break;
            default:
                return formatAmounts(num,",",".",haspre);
                break;
        } 
    } 
    function formatAmountOnlyNum(num){
        num = num.toString().replace(/[^(\d)]/g,"");
        return num;
    }
    function getCursortPosition (ctrl) { 
        var CaretPos = 0; 
        // IE Support 
        if (document.selection) { 
            ctrl.focus (); 
            var Sel = document.selection.createRange (); 
            Sel.moveStart ('character', -ctrl.value.length); 
            CaretPos = Sel.text.length; 
        } 
            // Firefox support 
        else if (ctrl.selectionStart || ctrl.selectionStart == '0') 
            CaretPos = ctrl.selectionStart; 
        return (CaretPos); 
    }
 
    function setCaretPosition(id, pos){ 
        var inpObj = document.getElementById(id);
        if(navigator.userAgent.indexOf("MSIE") > -1){
            var range = document.selection.createRange();
            var textRange = inpObj.createTextRange();
            textRange.moveStart('character',pos);
            textRange.collapse();
            textRange.select();
        }else{
            inpObj.setSelectionRange(pos,pos);
        }
    }
    var noticeMsg = '<%= this.GetMetadata(".AmountCharacter_Warning"+AmountType()).DefaultIfNullOrEmpty(this.GetMetadata(".AmountCharacter_Warning")).SafeJavascriptStringEncode() %>';
    function onAmountChange(){
        var num = $('#txtAmount').val();
        //console.log(formatAmount(num, false).toString()  + " "+ num.toString() + " "+formatAmountOnlyNum(num).toString());
        if( formatAmount(num, false) != num && formatAmountOnlyNum(num) != num ){
            $("#fldAmountCharacterMsg").remove();
            $("<label for='txtAmountMsg' generated='true' class='error AmountCharacterMsg' elementid='fldAmountCharacter' id='fldAmountCharacterMsg'>"+noticeMsg+"</label>").appendTo($("#txtAmount").parents("table.inputfield_Table").find(".controls"));
            setTimeout(function(){
                $("#fldAmountCharacterMsg").fadeOut().remove();
            },5000);
        }else{
            $("#fldAmountCharacterMsg").remove();
        } 
        $('#txtAmount').val(formatAmount(num, false)); 
        $("input[name='amount']").val($('#txtAmount').data('fillvalue') );
    }
    function onAmountBlur() { 
        if ($('#txtAmount').val() == '' || $('#txtAmount').val() == 0 ) { 
            $('#txtAmount').val(formatAmount(0, false));
            $('#txtAmount').data('fillvalue',0);
        } else {  
            var num = $('#txtAmount').val(); 
            $('#txtAmount').val(formatAmount($('#txtAmount').val(),true));
        } 
        if($('#txtAmount').data('fillvalue') == GetRealAmount($('#txtAmount').val()) ){ 
            $("input[name='amount']").val($('#txtAmount').data('fillvalue') );
        }else{
            $('#txtAmount').data('fillvalue', GetRealAmount($('#txtAmount').val()));
            $("input[name='amount']").val($('#txtAmount').data('fillvalue') );
        }
        $("document").trigger("Amount_Blur");
    };
    function onAmountFocus() {    
        $('#txtAmount').data('fillvalue', GetRealAmount($('#txtAmount').val())); 
        if($('#txtAmount').data('fillvalue') != 0){
            $('#txtAmount').val(formatAmount($('#txtAmount').val(), false));
        }else{
            $('#txtAmount').val(formatAmount(0, false).substring(1, 4));
            setCaretPosition("txtAmount",0);
        } 
        $("input[name='amount']").val($('#txtAmount').data('fillvalue') );
    }
    onAmountBlur();
</script>
