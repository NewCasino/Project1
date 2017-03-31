<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Poker.Tournament>>" %>

<div class="PokerTournaments">
  <ul class="List">
    <%
            
            List<Poker.Tournament> tournaments = Poker.CakePokerProxy.GetTournaments().Where(t => t.Type == Poker.TournamentType.Current).OrderBy(u => u.StartTime).Take(5).ToList();
            for (int i = 0; i < 5; i++)
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
                            time = minute.ToString() + " " + this.GetMetadata(".Poker_Tournaments_min_Text");
                        }
                        else
                        {
                            time = Convert.ToDateTime(Convert.ToDateTime(tournaments[i].StartTime.ToString()).Subtract(DateTime.Now).ToString()).ToShortTimeString().ToString();
                        }
                    }
            %>
    <%=string.Format(@"<li class=""Item {0} {4}""><a href=""/Poker/"" class=""ListLink"" title=""{1}""><span class=""Time"">{2}</span><span class=""Name"">{3}</span></a></li>
", i % 2 == 0 ? "Even" : "Odd"
                                , tournaments[i].Name.DefaultIfNullOrEmpty("").SafeHtmlEncode(),
                                                                               time,
                                           tournaments[i].Name,i==4 ?"last":"") 
										   
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
