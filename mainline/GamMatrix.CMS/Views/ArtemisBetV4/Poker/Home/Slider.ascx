<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<script runat="server" type="text/C#">
    private string MetadataPath { get { return this.ViewData["MetadataPath"] as string; } }
    private string CurrentActionName { get { return this.ViewData["actionName"] as string; } }
 
string _temp1,subPath1="";
string name,image = "", text = "", title = "" , subPath="";
</script>

<div class="poker-slider" id="Slider1">
  <div class="Canvas">
    <ol class="SliderItems">
      <%
        string[] categoryPaths = Metadata.GetChildrenPaths(this.MetadataPath +"/slider/");
        foreach (string categoryPath in categoryPaths)
        {  
%>
            <%= string.Format(@"<li class=""SItem""> <div class=""SliderContent""> <h2 class=""SliderTitle""><a href=""{1}"" title=""{2}"">{3}</a></h2><p>{4}</p><div class=""ActionZone""><a class=""pokerbutton button"" href=""{5}"" title=""{6}""><strong class=""GoldButtonText"">{7}</strong></a><p class=""GameInfo"">{8}</p></div></div></li>"
,
this.GetMetadata(categoryPath + ".Slider_Css").DefaultIfNullOrEmpty(string.Empty).SafeHtmlEncode(),
this.GetMetadata(categoryPath + ".Slider_Url").DefaultIfNullOrEmpty("javascript:void(0)"),
this.GetMetadata(categoryPath + ".Slider_Title").DefaultIfNullOrEmpty(string.Empty).SafeHtmlEncode(),
this.GetMetadata(categoryPath + ".Slider_Text").DefaultIfNullOrEmpty(string.Empty),
this.GetMetadata(categoryPath + ".Intro_Text").DefaultIfNullOrEmpty(string.Empty),
this.GetMetadata(categoryPath + ".ActionZone_Url").DefaultIfNullOrEmpty("javascript:void(0)"),
this.GetMetadata(categoryPath + ".ActionZone_Title").DefaultIfNullOrEmpty(string.Empty).SafeHtmlEncode(),
this.GetMetadata(categoryPath + ".ActionZone_Txt").DefaultIfNullOrEmpty(string.Empty),
this.GetMetadata(categoryPath + ".GameInfo_Html").DefaultIfNullOrEmpty(string.Empty) ,
!string.IsNullOrEmpty(ContentHelper.ParseFirstImageSrc(this.GetMetadata(categoryPath + ".BackgroundImage"))) ? 
                        "background-image:url('" + ContentHelper.ParseFirstImageSrc(this.GetMetadata(categoryPath + ".BackgroundImage")) + "');"
                        :"background-image:url('" + this.GetMetadata(categoryPath + ".BackgroundImage")+"');"
)%>
      <%}%>
    </ol>
  </div>
  <ul class="Controls">
    <% 
        foreach (string categoryPath in categoryPaths)
        { 
%> 
             <%= string.Format(@"<li class=""CItem ""><a href=""javascript:void(0);"" class=""CLink  pokerbutton"" title=""{0}"">{1}</a> </li>"
,this.GetMetadata(categoryPath + ".Control_Title").DefaultIfNullOrEmpty(string.Empty).SafeHtmlEncode(),
this.GetMetadata(categoryPath + ".Control_Text").DefaultIfNullOrEmpty(string.Empty).SafeHtmlEncode()
)%>
    <%}%> 
  </ul>
</div><ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script language="javascript">
function Slider(SliderId){
var SliderIndex = 0; 
var SliderBox = $("#"+SliderId);
var SliderMainBox = SliderBox.find("ol");
var SliderMainLi = SliderMainBox.find('li');
var SliderControlBox = SliderBox.find("ul");
var SliderControlLi = SliderControlBox.find('li');
var SliderCount = SliderBox.find("ol li").length;
var SliderTimeOutId = "";
function SliderLoad(){
SliderMainLi.eq(0).addClass("Active");
SliderControlLi.eq(0).addClass("Active");
if(SliderCount >1 ){
var ControlClass = "Cont-"+ SliderCount +"cols";
SliderControlBox.addClass(ControlClass);
SliderControlLi.click(function(){
clearTimeout(SliderTimeOutId);
SliderIndex=SliderControlLi.index($(this));
SliderShow('AAA');
});
setTimeout(SliderShow,5000);
}else{
SliderControlBox.hide();
}
}
function SliderShow(SliderNum){
 if(SliderNum!='AAA'){
SliderIndex=SliderIndex+1;
if(SliderIndex>=SliderCount){
SliderIndex=0;
}
}
SliderControlLi.removeClass("Active").eq(SliderIndex).addClass("Active");
SliderMainLi.fadeOut("slow").removeClass("Active").eq(SliderIndex).fadeIn("slow").addClass("Active");
SliderTimeOutId = setTimeout(SliderShow,5000); 
SliderNum="0";
}
SliderLoad();
}
$(document).ready(function(){
Slider("Slider1");
jQuery('.SItem').attr('style','');
});
</script>
</ui:MinifiedJavascriptControl>