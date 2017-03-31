<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Breadcrumbs MobilePageBreadcrumbs">
    <ul class="BreadMenu">
        <li class="BreadItem">
             <a href="/" class="BreadLink  url" title="Go to Artemisbet Homepage"> 
              <span >Homepage</span> 
            </a>
        </li>
        <li class="BreadItem BreadCurrent">
            <a  class="BreadLink  url" title="Artemisbet Mobile Page ">
                 <span>Artemis Mobile  </span> 
             </a>
        </li>
    </ul>
</div>
<div class="mobileContent">
<div class="MobileTitle"> 
    <h1 class="MobilePageHeader PageTitle"> Artemis Mobile - Go mobile with Artemis!</h1> 
    <a href="//<%= this.GetMetadata(".MobileLink") %>" class="Button MobileSubtitleLink">Mobile Version</a>
</div>

<div class="MobilePageTitle">
       <p class="MobilePageTopParagraph"><a class="MobileParLink" href="//<%= this.GetMetadata(".MobileLink") %>"><%= this.GetMetadata(".MobileLink") %></a> is not only your portal to the very best in mobile sports betting and casino gaming. You can also deposit and withdraw using a selection of our most popular payment methods, check on your active bonuses, claim your casino Cash Rewards, visit the Help section or get in touch with our 24/7 customer support team.</p>
</div>
<div class="MobilePagesBox">
  <div class="MobilePagesContent">
      <ul class="MobilePagesList">
            <li class="MobilePageExample"> <div class="MPExBox"><%= this.GetMetadata(".picture1") %></div> </li>
            <li class="MobilePageExample"> <div class="MPExBox"><%= this.GetMetadata(".picture2") %></div> </li>
            <li class="MobilePageExample"> <div class="MPExBox"><%= this.GetMetadata(".picture3") %></div> </li>
            <li class="MobilePageExample"> <div class="MPExBox"><%= this.GetMetadata(".picture4") %></div> </li>
            <li class="MobilePageExample"> <div class="MPExBox"><%= this.GetMetadata(".picture5") %></div> </li>
            <li class="MobilePageExample"> <div class="MPExBox"><%= this.GetMetadata(".picture6") %></div> </li>
            <li class="MobilePageExample"> <div class="MPExBox"><%= this.GetMetadata(".picture7") %></div> </li>
            <li class="MobilePageExample"> <div class="MPExBox"><%= this.GetMetadata(".picture8") %></div> </li>
            <li class="MobilePageExample"> <div class="MPExBox"><%= this.GetMetadata(".picture9") %></div> </li>
            <li class="MobilePageExample"> <div class="MPExBox"><%= this.GetMetadata(".picture10") %></div> </li>
       </ul>
  </div>
</div>
 <ul class="MobileDescription Container">
    <li class="MobileItem">
    <h2 class="MobileSubtitle">Mobile Casino</h2>
    <p class="MobileItemParagraph">Our mobile casino covers a large selection of the games our players know and love from the website. And just like the website games, our mobile games spans across all the casino categories and top brands. Touch 'n win!</p>
    </li>
       <li class="MobileItem">
            <a class="Button MobileRoundLink GotoMobileLink" href="//<%= this.GetMetadata(".MobileLink") %>">
                <span class="ButtonIcon MobileRoundBTNIcon responsive">&nbsp;</span>
                <span class="ButtonText">Go <br /> Mobile</span>
            </a>
       </li>
     <li class="MobileItem">
            <h2 class="MobileSubtitle">Mobile Sports</h2>
            <p class="MobileItemParagraph">ArtemisBet 's award winning Sportsbook works just as great on your mobile device. Whether you prefer pre-match betting or Live betting, you have the exact same vast selection of markets and betting types at your fingertips, literally speaking.</p>
    </li>
 </ul>
</div>
<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('MobilePage');
jQuery('.inner').removeClass('PageBox').addClass('MobileContent');
$('.GoMobile.LogoGoM').remove();
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

