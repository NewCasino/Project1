<%@ Page Language="C#" PageTemplate="/Poker/PokerMaster.master" Inherits="CM.Web.ViewPageEx<List<Poker.Tournament>>"
    Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>"
    MetaDescription="<%$ Metadata:value(.Description)%>" %>

<asp:content contentplaceholderid="cphHead" runat="Server"> </asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">
  <div id="poker-wrapper <%=Profile.IpCountryID%>">
    <div class="mainPanel">
      <%Html.RenderPartial("/Components/ImageSlider", this.ViewData.Merge(new { ShowIconButton = false, MetadataPath = "/Poker/SliderItems" })); %>
      <div class="halfPanel Bonus">
        <div class="pokertitle"> <%=this.GetMetadata(".Text_POKER_Bonuses")%> </div>
        <%=this.GetMetadata(".BonusBanner1")%> <%=this.GetMetadata(".BonusBanner2")%> <%=this.GetMetadata(".BonusBanner3")%> </div>
      <div class="halfPanel Tournaments">
        <div class="pokertitle"> <%=this.GetMetadata(".Text_Poker_tournaments")%> </div>
        <div class="PokerTournaments"><ul class="List">
        <%
            
         List<Poker.Tournament> tournaments = Poker.CakePokerProxy.GetTournaments().Where(t => t.Type == Poker.TournamentType.Current).OrderBy(u => u.StartTime ).Take(8).ToList();
         for (int i = 0; i < 8; i++)
         {
             try
             {
                 string time = "";
                 if (Convert.ToDateTime(tournaments[i].StartTime.ToString()) <= DateTime.Now)
                 {
                     time = this.GetMetadata(".Poker_Tournaments_Started_Text");
                 }
                 else
                 {
                     int hour = Convert.ToDateTime(tournaments[i].StartTime.ToString()).Subtract(DateTime.Now).Hours;
                     int minute = Convert.ToDateTime(tournaments[i].StartTime.ToString()).Subtract(DateTime.Now).Minutes;
                     if (hour == 0)
                     {
                         time = minute.ToString() +" "+ this.GetMetadata(".Poker_Tournaments_min_Text");
                     }
                     else
                     {
                         time = Convert.ToDateTime(Convert.ToDateTime(tournaments[i].StartTime.ToString()).Subtract(DateTime.Now).ToString()).ToShortTimeString().ToString();
                     }
                 }
            %>
      <%=string.Format(@"<li class=""Item {0}""><a href=""javascript:void(0)"" class=""ListLink"" title=""{1}""><span class=""Time"">{2}</span><span class=""Name"">{3}</span></a></li>
", i % 2 == 0 ? "Even" : "Odd"
                                , tournaments[i].Name.DefaultIfNullOrEmpty("").SafeHtmlEncode(),
                                                 time,
                                           tournaments[i].Name)
            %>
      <%}
             catch
             { %>
      <%=string.Format(@"<li class=""Item {0}""><a href=""javascript:void(0)"" class=""ListLink"" title=""{1}""><span class=""Time"">{2}</span><span class=""Name"">{3}</span></a></li>
", i % 2 == 0 ? "Even" : "Odd", "&nbsp;", "&nbsp;", "&nbsp;")%>
      <%
             }
         }%>
        </ul>
        </div>
        <div class="PokerMoreTournaments"><%=this.GetMetadata(".Text_Seealltournaments")%></div>
      </div>
    </div>
    <div class="rightPanel">
      <div id="poker-banner1"> <%=this.GetMetadata(".Banner1")%></div>
      <div id="poker-cakePokerDownload"> <a href="
<%=this.GetMetadata(".Download_Url").SafeHtmlEncode()%>"> <%=this.GetMetadata(".Download_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a> </div>
      <div id="poker-banner2"> <%=this.GetMetadata(".Banner2")%></div>
      <div id="poker-onlineNum">
        <div class="pokertitle"><%=this.GetMetadata(".Text_PlayersOnline")%></div> 
        <div class="pokerCount">
	  <%=Poker.CakePokerProxy.GetOverview().OnlinePlayerNumber.ToString("N0")%></div></div>
    </div>
    <div class="w2c"></div>
  </div>
</asp:content>
