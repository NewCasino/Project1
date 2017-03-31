<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%if (Profile.IsAuthenticated)
       { %>
<style>.UserMessage_red,.TopLinks .UserMessage_red{color:#f00;}</style>
<%--
<script src="/js/jquery/jquery-1.7.1.min.js"></script>
<a href="#" class="MessagesPanel" ><%=this.GetMetadata(".Message_Text").SafeHtmlEncode()%></a>
--%>
<script language="javascript" type="application/javascript">
var Interval_UserMessage_Count= false , Interval_UserMessage_Count_Refresh;
var Msg_Count = 0 , Msg_ShakeCount = 0;
var Msg_ReCheckTime = 3000,Msg_ShakeTime = 200 , Msg_AjaxLimitTime = 60;
function shake(ele,cls){ 
	if(Interval_UserMessage_Count != false) return;
	Interval_UserMessage_Count= setInterval(function(){
		Msg_ShakeCount++; 
		if(Msg_ShakeCount%2 !=0 || Msg_Count == 0){
			ele.removeClass(cls);
		} else{
			ele.addClass(cls);
		} 
	},Msg_ShakeTime);
};
function CheckTagStatus(){
	Msg_Count = $.cookie('Messages_Count');
	if(Msg_Count == null || Msg_Count == '') {		
		clearInterval(Interval_UserMessage_Count);
		Interval_UserMessage_Count= false;	
		$.cookie('Messages_Count',0); 
		Msg_Count=0;
		return;		
	}
	if(Msg_Count > 0){
		clearInterval(Interval_UserMessage_Count);
		Interval_UserMessage_Count= false;	
		$(".MessagesPanel").text("<%=this.GetMetadata(".Message_Text").SafeJavascriptStringEncode()%>("+Msg_Count+")").show();
		shake($(".MessagesPanel"),"UserMessage_red");
	}
}
function CheckUserMsg_Count(){ 
	$(".MessagesPanel").text("<%=this.GetMetadata(".Message_Text").SafeJavascriptStringEncode()%>").show();
	var CheckTime = $.cookie('Messages_Time');
	var nowTime = new Date() ; 
	if(CheckTime == null || CheckTime == ''){
		$.cookie('Messages_Time',nowTime);
		return;		
	}
	//console.log("Time PPP:" + TimeDiff(new Date(CheckTime),nowTime));
	if(TimeDiff(new Date(CheckTime),nowTime)>( Msg_AjaxLimitTime + parseInt(Math.random()*10))){
		$.getJSON("/messages/GetMessagesUnReadCount", function(json){
			if(json.success ==  true  ){				
				Msg_Count = json.count;
				$.cookie('Messages_Count' , Msg_Count );	
			}else{
				Msg_Count = 0;
				$.cookie('Messages_Count' , 0 );					
			}
			//console.log("Ajax Get:" +  nowTime );
			$.cookie('Messages_Time',nowTime);
		});
	}
}
function CheckUserMsg_CountSet(){	
	Interval_UserMessage_Count_Refresh = setInterval(function(){
		CheckUserMsg_Count();
		CheckTagStatus();
	},Msg_ReCheckTime);
}
$(document).ready(function(){
	$(".MessagesPanel").hide();
	CheckUserMsg_Count();
	CheckUserMsg_CountSet();
});
function TimeDiff( date1, date2) {
	var part = date2.getTime() - date1.getTime(); 
	return parseInt(part / 1000  );
}
function isDate(obj) {
	return toString.call(obj) === "[object Date]";
}
jQuery.cookie = function(name, value, options) {
    if (typeof value != 'undefined') {
        options = options || {};
        if (value === null) {
            value = '';
            options.expires = -1;
        }
        var expires = '';
        if (options.expires && (typeof options.expires == 'number' || options.expires.toUTCString)) {
            var date;
            if (typeof options.expires == 'number') {
                date = new Date();
                date.setTime(date.getTime() + (options.expires * 24 * 60 * 60 * 1000));
            } else {
                date = options.expires;
            }
            expires = '; expires=' + date.toUTCString(); 
        }
        var path = options.path ? '; path=' + options.path : '';
        var domain = options.domain ? '; domain=' + options.domain : '';
        var secure = options.secure ? '; secure' : '';
        document.cookie = [name, '=', encodeURIComponent(value), expires, path, domain, secure].join('');
    } else { 
        var cookieValue = null;
        if (document.cookie && document.cookie != '') {
            var cookies = document.cookie.split(';');
            for (var i = 0; i < cookies.length; i++) {
                var cookie = jQuery.trim(cookies[i]);
                if (cookie.substring(0, name.length + 1) == (name + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                    break;
                }
            }
        }
        return cookieValue;
    }
};
</script><%
}else{
%>
<script language="javascript" type="application/javascript">
$(document).ready(function(){
	$(".MessagesPanel").hide();
});	
</script>
<%	
}
%>