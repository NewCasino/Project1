<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Web.Hosting" %>

<script type="text/C#" runat="server">
  public string GetFeedsType(string distinctName)
  {
      using (BLToolkit.Data.DbManager dbManager = new BLToolkit.Data.DbManager())
      {
          CM.db.Accessor.SiteAccessor da = BLToolkit.DataAccess.DataAccessor.CreateInstance<CM.db.Accessor.SiteAccessor>(dbManager);
          var site = da.GetByDistinctName(distinctName);
          if (site != null)
          {
              int feedsType = da.GetFeedType(site.DomainID);
              return ((FeedsType)feedsType).ToString();
          }
          else
          {
              return CasinoEngine.FeedsType.CE1Feeds.ToString();
          }
          

          /*string relativePath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/ce_feeds_type.setting", distinctName));
          string filePath = HostingEnvironment.MapPath(relativePath);
          return ObjectHelper.BinaryDeserialize<FeedsType>(filePath, cached).ToString();*/
      }
  }

  private bool IsCMSSystemAdminUser
  {
      get
      {
          return Profile.IsInRole("CMS System Admin");
      }
  } 
</script>
<style type="text/css">
  .casino-mgt-operations {
      display: block;
      overflow: auto;
      width: 100%;
  }
  .casino-mgt-operations ul {
      font-style: normal;
      margin: 0;
      padding: 0;
  }
  .casino-mgt-operations li {
      float: left;
      list-style-type: none;
      margin-left: 5px;
      overflow: auto;
  }
  .casino-mgt-operations a {
      background-repeat: no-repeat;
      color: #666666;
      font-style: normal;
      padding-left: 18px;
      text-decoration: none;
  }
  .casino-mgt-operations a:hover {
      text-decoration: underline;
  }
  .casino-mgt-operations .refresh {
      background: rgba(0, 0, 0, 0) url("//cdn.everymatrix.com/AdminConsole/img/tools_sprites.png") no-repeat scroll 0 0;
  }
  .casino-mgt-operations .save {
      background: rgba(0, 0, 0, 0) url("//cdn.everymatrix.com/AdminConsole/img/tools_sprites.png") no-repeat scroll 0 -200px;
  }
  .casino-mgt-operations .history {
      background: rgba(0, 0, 0, 0) url("//cdn.everymatrix.com/AdminConsole/img/tools_sprites.png") no-repeat scroll 0 -60px;
  }
  .domainlist{list-style-type: none; margin: 0px; padding: 0px;margin:10px auto;}
  .domainlist li{margin:5px auto;}
</style>

<div id="casinogame-configuration-links" class="casino-mgt-operations">
  <ul>
    <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
    <li>|</li>
    <li> <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                        @action = "Dialog",
                        @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                        @relativePath = "/.config/ce_feeds_type.setting".DefaultEncrypt(),
                        @searchPattner = "",
                        } ).SafeHtmlEncode()  %>"
                target="_blank" class="history">Change history...</a> </li>
  </ul>
</div>
<hr class="seperator" />

<% using (Html.BeginRouteForm("CasinoGameMgt"
       , new { @action = "SaveFeedsType", @distinctName = this.Model.DistinctName.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formSaveFeedsType" }))
   { %>
   <h3>CasionEngine Feeds</h3>
   
   <table>
      <tr>
          <td>
              <input type="radio" name="feedsType" value="<%=CasinoEngine.FeedsType.CE1Feeds.ToString()%>" id="btnCE1Feeds" />
              <label for="btnCE1Feeds">CE1 Feeds</label>
          </td>
      </tr>
      <tr>
          <td>
              <input type="radio" name="feedsType" value="<%=CasinoEngine.FeedsType.CE2CompatibleFeeds.ToString()%>" id="btnCE2CompatibleFeeds" />
              <label for="btnCE2CompatibleFeeds">CE2 Compatible Feeds</label>
          </td>
      </tr>
      <tr>
          <td>
              <input type="radio" name="feedsType" value="<%=CasinoEngine.FeedsType.CE2JsonFeeds.ToString()%>" id="btnCE2JsonFeeds" />
              <label for="btnCE2JsonFeeds">CE2 Json Feeds</label>
          </td>
      </tr>
  </table>

<div class="buttons-wrap">
  <ui:Button runat="server" ID="btnCasinoDomainChanges" type="sumbit"> Save </ui:Button>
</div>
<script type="text/javascript">
$(function() {
    var feedsType = '<%=GetFeedsType(this.Model.DistinctName)%>';
    console.log(feedsType);
    switch (feedsType)
    {
        case "<%=CasinoEngine.FeedsType.CE2CompatibleFeeds.ToString()%>":
            $('#btnCE1Feeds').attr('checked', false);
            $('#btnCE2CompatibleFeeds').attr('checked', true);
            $('#btnCE2JsonFeeds').attr('checked', false);
            break;

        case "<%=CasinoEngine.FeedsType.CE2JsonFeeds.ToString()%>":
            $('#btnCE1Feeds').attr('checked', false);
            $('#btnCE2CompatibleFeeds').attr('checked', false);
            $('#btnCE2JsonFeeds').attr('checked', true);
            break;

        case "<%=CasinoEngine.FeedsType.CE1Feeds.ToString()%>":
        default:
            $('#btnCE1Feeds').attr('checked', true);
            $('#btnCE2CompatibleFeeds').attr('checked', false);
            $('#btnCE2JsonFeeds').attr('checked', false);
            break;
    }

  <%if (!IsCMSSystemAdminUser)
  {%>
    $("#btnCE1Feeds").attr("disabled", "disabled");
    $("#btnCE2CompatibleFeeds").attr("disabled", "disabled");
    $("#btnCE2CompatibleFeeds").attr("disabled", "disabled");
  <%} %>

      $('#btnCasinoDomainChanges').click(function (e) {
            e.preventDefault();

            if (self.startLoad) self.startLoad();
            var options = {
                type: 'POST',
                dataType: 'json',
                success: function (json) {
                    if (self.stopLoad) self.stopLoad();
                    if (!json.success) { alert(json.error); return; } else alert('save successfully!');
                }
            };
            $('#formSaveFeedsType').ajaxForm(options);
            $('#formSaveFeedsType').submit();
        });
});
</script>
<% } %>
