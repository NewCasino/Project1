<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.BonusData>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="OddsMatrix" %>

<script language="C#" type="text/C#" runat="server">
    private sealed class BonusRowInfo
    {
        public string Key { get; set; }
        public string Title { get; set; }
        public bool Highlighted { get; set; }
        public string CSS { get; set; }
        public bool Visible { get; set; }
    }

    private NetEntFPPClaimRec NetEntFPPClaimRec { get; set; }
    private bool HasCasinoWallet { get; set; }
    private string sportsBonusMessage;
    private string sportsBonusUrl;

    private Dictionary<string, string> _propertyKeys = new Dictionary<string, string>
    {
       { "Bonus_Type", "Type" },
       { "Bonus_Amount", "{0} {1:N2},Currency,Amount" },
       { "Bonus_Granted_Date", "{0:dd/MM/yyyy},Created" },
       { "Bonus_ID", "BonusID" },
       { "Bonus_Name", "Name" },
       { "Bonus_Status", "Status" },
       { "Bonus_Url", "Url" },
       { "Confiscate_All_Funds_On_Expiration", "ConfiscateAllFundsOnExpiration" },
       { "Confiscate_All_Funds_On_Forfeiture", "ConfiscateAllFundsOnForfeiture" },
       { "Expiry_Date", "{0:dd/MM/yyyy},ExpiryDate" },
       { "Remaining_Wagering", "{0} {1:N2},RemainingWagerRequirementCurrency,RemainingWagerRequirementAmount" },
       { "Wager_Requirement", "{0} {1:N2},WagerRequirementCurrency,WagerRequirementAmount" },
       { "Wager_Requirement_Progress", "{0},RemainingWagerRequirementAmount,WagerRequirementAmount" }
    };

    private List<BonusRowInfo> BonusProperties { get; set; }
    public string GetPropValue(object src, string propName, string metadataName)
    {
        var properties = propName.Split(',');

        var type = src.GetType();
        if (properties.Length == 1)
        {
            var propType = type.GetProperty(propName);
            if (propType == null)
                return null;
          
            var propVal = propType.GetValue(src, null);

            if (propVal != null && propVal.GetType() == typeof(bool))
            {
                propVal = (bool)propVal ? this.GetMetadata(".YES") : this.GetMetadata(".NO");
            }

            return propVal != null ? propVal.ToString() : null;
        }
        else
        {
            var format = properties[0];
            var values = new object[properties.Length - 1];

            var isNull = true;

            for (int i = 1; i < properties.Length; i++)
            {
                var propVal = type.GetProperty(properties[i]).GetValue(src, null);

                values[i - 1] = propVal != null ? propVal : null;

                if (isNull && propVal != null)
                {
                    isNull = false;
                }
            }

            if (isNull)
            {
                return null;
            }

            if (metadataName == "Wager_Requirement_Progress")
            {
                var amount = (decimal)values[1];
                amount = amount == 0 ? 1 : amount;

                var val = Math.Round(((1 - (decimal)values[0] / amount) * 100), 0);

                values = new []{ val.ToString() };
            }

            return string.Format(format, values);
        }
    }

    private string GetOMBonusURL()
    {
        string url = this.GetMetadata("/Metadata/Settings.OddsMatrix_BonusPage");
        if (url.IndexOf('?') > 0)
            url += "&";
        else
            url += "?";

        url+= string.Format(CultureInfo.InvariantCulture, "lang={0}"
            , HttpUtility.UrlEncode(OddsMatrixProxy.MapLanguageCode(HttpContext.Current.GetLanguage()))
        );

        url += string.Format(CultureInfo.InvariantCulture, "&currentSession={0}"
            , HttpUtility.UrlEncode(Profile.SessionID)
            );

        return url;
    }

    protected override void OnInit(EventArgs e)
    {
        try
        {
            var account = GamMatrixClient.GetUserGammingAccounts(Profile.UserID).FirstOrDefault(a => a.Record.ActiveStatus == ActiveStatus.Active && a.Record.VendorID == VendorID.NetEnt);
            if( account != null )
            {
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    NetEntGetClaimFPPDetailsRequest request = new NetEntGetClaimFPPDetailsRequest()
                    {
                        AccountID = account.ID,
                    };
                    request = client.SingleRequest<NetEntGetClaimFPPDetailsRequest>(request);

                    NetEntFPPClaimRec = request.ClaimRec;
                }
            }

            HasCasinoWallet = GamMatrixClient.GetUserGammingAccounts(Profile.UserID).Exists(a =>a.Record.ActiveStatus == ActiveStatus.Active && a.Record.VendorID == VendorID.CasinoWallet);

            BonusProperties = new List<BonusRowInfo>();

            var properties = Metadata.GetChildrenPaths("/Metadata/AvailableBonus/Casino");

            foreach (var item in properties)
            {
                BonusRowInfo info = new BonusRowInfo()
                {
                    Key = item.Substring(item.LastIndexOf('/') + 1),
                    Title = Metadata.Get(item + "/.Title"),
                    CSS = Metadata.Get(item + "/.Css"),
                    Highlighted = SafeParseBoolString( Metadata.Get(item + "/.Highlighted"), false),
                    Visible = !CheckIfMetadataisDisabled(item)
                    // SafeParseBoolString( Metadata.Get(item + "/.Visible"), true),
                };
                if (!info.Visible)
                    continue;
                BonusProperties.Add(info);
            }
        }
        catch(Exception ex)
        {
            Logger.Exception(ex);
        }
        base.OnInit(e);
    }

    private bool CheckIfMetadataisDisabled(string physicalPath)
    {
        var result = false;

        try{
            string propertiesXml = System.IO.Path.Combine(System.IO.Path.GetDirectoryName(physicalPath), ".properties.xml");
            XDocument doc = PropertyFileHelper.OpenReadWithoutLock(propertiesXml);

            result = string.Compare(doc.Root.GetElementValue("IsDisabled", "false"), "true", true) == 0;
        }
        catch{

        }

        return result;
    }

    private bool SafeParseBoolString(string text, bool defValue)
    {
        if (string.IsNullOrWhiteSpace(text))
            return defValue;

        text = text.Trim();

        if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return true;

        if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return false;

        return defValue;
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
   
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="available-bonus-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnAvailableBonus">

<ui:Fieldset runat="server" Legend="<%$ Metadata:value(.Casino_Bonus) %>">
<% 
    List<BonusData> bonuses = this.Model;
    
    if (bonuses.Count == 0)
    {
        %>
        <%: Html.InformationMessage( this.GetMetadata(".No_Bonus") ) %>
        <%
    }
    else
    {
        int queuedIndex = 0;
        
        foreach (BonusData bonus in bonuses)
        {%>
    <table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table" data-priority="<%= bonus.Priority %>" data-status="<%=bonus.Name %>" >
        <% foreach (BonusRowInfo item in BonusProperties)
           {%>
        <% if (_propertyKeys.ContainsKey(item.Key)) {
               var value = GetPropValue(bonus, _propertyKeys[item.Key], item.Key);
               if (!string.IsNullOrEmpty(value)){
                   value = value.SafeHtmlEncode();
                   var isHighlighted = item.Highlighted ? "highlighted" : string.Empty;
                   var isProgress = string.Empty;
                   var progressBaCss = string.Empty;
                   if (item.Key == "Wager_Requirement_Progress")
                   {
                       isProgress = "progress";
                       progressBaCss = string.Format("width:{0}%;", value);
                       value = string.Format("<div class='progress-text'>{0} {1}%</div>", this.GetMetadata(".ProgressText"), value);
                   }
                   if (item.Key == "Bonus_Url")
                   {
                       value = string.Format("<a target='_blank' class='GOLink' href='{1}'>{0}</a>", this.GetMetadata(".Bonus_TC"), value.SafeHtmlEncode());
                   }
        %>
            <tr class="<%: isHighlighted %> <%: isProgress %>" style="<%: item.CSS %>">
                <td class="name"><%= item.Title.HtmlEncodeSpecialCharactors() %></td>
                <td class="value"><div style="<%: progressBaCss %>"><%= value %></div></td>
            </tr>
        <% } %>
        <% } %>
        <% } %>

        <%if (bonus.VendorID == VendorID.CasinoWallet && bonus.ConfiscateAllFundsOnForfeiture.HasValue)
          { %>
        <tr>
            <td class="name"></td>
            <td class="value  column_button">
                <% using( Html.BeginRouteForm( "AvailableBonus", new { @action="ForfeitCasinoBonus"},FormMethod.Post, new { @id="formForfeitCasinoBonus" + bonus.ID }) )
                   { %>
                <%: Html.Hidden( "bonusID", bonus.ID) %>
                <%: Html.Button( this.GetMetadata(".Forfeit"), new { @type = "submit", @id="btnForfeitCasinoBonus" + bonus.ID }) %>
                <% } %>
                <script type="text/javascript">
                    $(function () {
                        $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').click( function(e){
                            e.preventDefault();
                            var confiscateAll = <%= bonus.ConfiscateAllFundsOnForfeiture.Value.ToString().ToLowerInvariant() %>;
                            var ret = false;
                            if( confiscateAll )
                                ret = window.confirm( '<%= this.GetMetadata(".Confiscate_All_Warning").SafeJavascriptStringEncode() %>' );
                            else
                                ret = window.confirm( '<%= this.GetMetadata(".Forfeit_Warning").SafeJavascriptStringEncode() %>' );

                            if(ret){
                                $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(true);
                                var options = {
                                    dataType: "json",
                                    type: 'POST',
                                    success: function (json) {
                                        $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(false);
                                        if( !json.success ){
                                            alert(json.error);
                                        }else{
                                            self.location = self.location.toString().replace(/(\#.*)$/, '');
                                        }
                                    },
                                    error: function (xhr, textStatus, errorThrown) {
                                        $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(false);
                                    }
                                };
                                $('#formForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').ajaxForm(options);
                                $('#formForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').submit();
                            }
                        });
                        

                    });
                </script>
            </td>
        </tr>
        <% } %>

        <%-- Forfeit Classic NetEnt Bonus --%>
        <%if (bonus.VendorID == VendorID.NetEnt )
          { %>
        <tr>
            <td class="name"></td>
            <td class="value  column_button">
                <% using (Html.BeginRouteForm("AvailableBonus", new { @action = "ForfeitNetEntBonus" }, FormMethod.Post, new { @id = "formForfeitNetEntBonus" + bonus.ID }))
                   { %>
                <%: Html.Hidden( "bonusID", bonus.ID) %>
                <%: Html.Button(this.GetMetadata(".Forfeit"), new { @type = "submit", @id = "btnForfeitNetEntBonus" + bonus.ID })%>
                <% } %>

                <script type="text/javascript">
                    $(function () {
                        $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').click(function (e) {
                            e.preventDefault();
                            var ret = window.confirm('<%= this.GetMetadata(".Forfeit_Warning").SafeJavascriptStringEncode() %>');

                            if (ret) {
                                $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(true);
                                var options = {
                                    dataType: "json",
                                    type: 'POST',
                                    success: function (json) {
                                        $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(false);
                                        if (!json.success) {
                                            alert(json.error);
                                        } else {
                                            self.location = self.location.toString().replace(/(\#.*)$/, '');
                                        }
                                    },
                                    error: function (xhr, textStatus, errorThrown) {
                                        $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(false);
                                    }
                                };
                                $('#formForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').ajaxForm(options);
                                $('#formForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').submit();
                            }
                        });

                    });
                </script>
            </td>
        </tr>
        <% } %>
        
        <% if (string.Equals(bonus.Status, "Queued", StringComparison.InvariantCultureIgnoreCase)) {
               if (queuedIndex > 0)
               {
               %>
         <tr>
             <td class="value column_button" colspan="2" align="right">
                 <% using (Html.BeginRouteForm("AvailableBonus", new { @action = "TopBonus" }, FormMethod.Post, new { @id = "formTopBonus" + bonus.ID }))
                   { %>
                <%: Html.Hidden( "bonusID", bonus.ID) %>
                <%: Html.Button(this.GetMetadata(".Top"), new { @type = "submit", @id = "btnTopBonus" + bonus.ID })%>
                <% } %>
                 <script type="text/javascript">
                     $(function () {
                         $('#btnTopBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').click(function (e) {
                             e.preventDefault();

                             TopBonus('<%= bonus.ID.SafeJavascriptStringEncode() %>');
                         });
                     });
                </script>
             </td>
         </tr>
        <%      }
               queuedIndex++;
            }%>
    </table>
    <br /><br />
<%      } %>
    <script type="text/javascript">

        function TopBonus(bonusID)
        {
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#btnTopBonus'+bonusID).toggleLoadingSpin(false);
                    if (!json.success) {
                        alert(json.error);
                    } else {
                        self.location = self.location.toString().replace(/(\#.*)$/, '');
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnTopBonus'+bonusID).toggleLoadingSpin(false);
                }
            };

            $('#formTopBonus'+bonusID).ajaxForm(options);
            $('#formTopBonus'+bonusID).submit();
        }
    </script>
<%  } %>


<%------------------------------------
    CasinoWallet - Bonus
 ------------------------------------%>
<%
    var gammingAccounts = GamMatrixClient.GetUserGammingAccounts(Profile.UserID);
    if( gammingAccounts.Exists( a => a.Record.VendorID == VendorID.CasinoWallet ) )
    {
        
        // Apply bonus code
        using( Html.BeginRouteForm( "AvailableBonus", new { @action = "ApplyCasinoBonusCode" }, FormMethod.Post, new { @id = "formApplyCasinoBonusCode" }) )
        {  %>
    <%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>
            <hr />
            <%: Html.H5( this.GetMetadata(".Enter_Bonus_Code") )  %>

            <ui:InputField ID="fldBonusCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Bonus_Code").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox( "bonusCode", string.Empty, new 
                    {
                        @maxlength = "50",
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".Bonus_Code_Empty"))
                    })  %>
                </ControlPart>
            </ui:InputField>


            <%: Html.Button( this.GetMetadata(".Button_Submit"), new { @type = "submit", @id="btnApplyCasinoBonus" }) %>
            <script type="text/javascript">
                $(function () {
                    $('#formApplyCasinoBonusCode').initializeForm();

                    $('#btnApplyCasinoBonus').click(function (e) {
                        e.preventDefault();

                        if (!$('#formApplyCasinoBonusCode').valid())
                            return;
                        $('#btnApplyCasinoBonus').toggleLoadingSpin(true);
                        var options = {
                            dataType: "json",
                            type: 'POST',
                            success: function (json) {
                                $('#btnApplyCasinoBonus').toggleLoadingSpin(false);
                                if (!json.success) {
                                    alert(json.error);
                                    return;
                                }
                                alert('<%= this.GetMetadata(".Bonus_Code_Applied").SafeJavascriptStringEncode() %>');
                                self.location = self.location.toString().replace(/(\#.*)$/, '');
                            },
                            error: function (xhr, textStatus, errorThrown) {
                                $('#btnApplyCasinoBonus').toggleLoadingSpin(false);
                            }
                        };
                        $('#formApplyCasinoBonusCode').ajaxForm(options);
                        $('#formApplyCasinoBonusCode').submit();
                    });
                });
            </script>

<%      } // using end
   } // if end%>


</ui:Fieldset>


<%------------------------------------
    NetEnt - FPP
 ------------------------------------%>
<% if (NetEntFPPClaimRec != null)
   { %>

<br />
<ui:Fieldset ID="Fieldset2" runat="server" Legend="<%$ Metadata:value(.Casino_FPP) %>">
    <%: Html.InformationMessage( string.Format(this.GetMetadata(".Casino_FPP_Notes")
    , NetEntFPPClaimRec.CfgConvertionPoints
    , NetEntFPPClaimRec.CfgConvertionCurrency
    , NetEntFPPClaimRec.CfgConvertionAmount
    ), true) %>
<%
    using (Html.BeginRouteForm("AvailableBonus", new { @action = "ClaimCasinoFPP" }, FormMethod.Post, new { @id = "formClaimCasinoFPP" }))
    { %>
        <ui:InputField ID="InputField1" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".Casino_FPP_Min_Claim_Points").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("fppMinClaimPoints", NetEntFPPClaimRec.CfgConvertionMinClaimPoints.ToString("N0"), new 
                {
                    @maxlength = "50",
                    @readonly = "readonly",
                })  %>
            </ControlPart>
        </ui:InputField>

        <ui:InputField ID="fldCasinoFPPPoints" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".Casino_FPP_Points").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("fppPoints", NetEntFPPClaimRec.Points.ToString("N0"), new 
                {
                    @maxlength = "50",
                    @readonly = "readonly",
                })  %>
            </ControlPart>
        </ui:InputField>

        <ui:InputField ID="fldCasinoExchangeAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".Casino_FPP_Exchange_Amount").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox( "fppExchangeAmount", string.Format("{0} {1:N2}", NetEntFPPClaimRec.RewardCurrency, NetEntFPPClaimRec.RewardAmount), new 
                {
                    @maxlength = "50",
                    @readonly = "readonly",
                })  %>
            </ControlPart>
        </ui:InputField>
        <% if (NetEntFPPClaimRec.Converted > 0)
           {  %>
        <%: Html.Button(this.GetMetadata(".Button_Claim"), new { @type = "submit", @id = "btnClaimCasinoFPP" })%>
        <% } %>
<%  } %>
</ui:Fieldset>
<script type="text/javascript">
    $(function () {
        $('#formClaimCasinoFPP').initializeForm();

        $('#btnClaimCasinoFPP').click(function (e) {
            e.preventDefault();

            $('#btnClaimCasinoFPP').toggleLoadingSpin(true);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#btnClaimCasinoFPP').toggleLoadingSpin(false);
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                    self.location = self.location.toString().replace(/(\#.*)$/, '');
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnClaimCasinoFPP').toggleLoadingSpin(false);
                }
            }; 
            $('#formClaimCasinoFPP').ajaxForm(options);
            $('#formClaimCasinoFPP').submit();
            $(document).trigger("BALANCE_UPDATED");
        });
    });
</script>

<% } %>


<%------------------------------------
    CasinoWallet - FPP
 ------------------------------------%>
 <%if (HasCasinoWallet) { %>
 <ui:Fieldset ID="fldCasinoWalletFpp" runat="server" Legend="<%$ Metadata:value(.CasinoWallet_FPP) %>">
    <%: Html.InformationMessage(this.GetMetadata(".Casino_FPP_Notes"), true, new { id = "casinoWalletFppInformation" })%>

        <ui:InputField ID="InputField2" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".Casino_FPP_Min_Claim_Points").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("fppMinClaimPoints", "", new 
                {
                    @id = "cwFppMinClaimPoints",
                    @maxlength = "50",
                    @readonly = "readonly",
                    @class="textbox",
                })  %>
            </ControlPart>
        </ui:InputField>

        <ui:InputField ID="InputField3" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".Casino_FPP_Points").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("fppPoints", "", new 
                {
                    @id="cwFppPoints",
                    @maxlength = "50",
                    @readonly = "readonly",
                    @class = "textbox",
                })  %>
            </ControlPart>
        </ui:InputField>

        <%: Html.Button(this.GetMetadata(".Button_Claim"), new { @type = "button", @id = "btnClaimCasinoWalletFPP" })%>

</ui:Fieldset>
<script type="text/javascript">
    var _points = 0;
    var _convertionMinClaimPoints = 0;
    var _convertionCurrency, _convertionPoints, _convertionAmount, _convertionType;

    function initFppData() {
        $('#cwFppMinClaimPoints').val('<%=this.GetMetadata(".Loading").SafeJavascriptStringEncode() %>');
        $('#cwFppPoints').val('<%=this.GetMetadata(".Loading").SafeJavascriptStringEncode() %>');

        var url = '<%= this.Url.RouteUrl("CasinoLobby", new { @action = "GetFrequentPlayerPoints" }).SafeJavascriptStringEncode() %>';
        $.getJSON(url, function (json) {
            if (json.success) {
                $("#fldCasinoWalletFpp").show();
                _points = json.points;
                _convertionMinClaimPoints = json.convertionMinClaimPoints;
                _convertionCurrency = json.convertionCurrency;
                _convertionPoints = json.convertionPoints;
                _convertionAmount = json.convertionAmount;
                _convertionType = json.convertionType;

                var informationHtml = $("#casinoWalletFppInformation").find(".message_Text").html();
                informationHtml = informationHtml.replace(/\{0\}/ig, _convertionPoints.toString(10));
                informationHtml = informationHtml.replace(/\{1\}/ig, _convertionCurrency.toString(10));
                informationHtml = informationHtml.replace(/\{2\}/ig, _convertionAmount.toString(10));
                $("#casinoWalletFppInformation").find(".message_Text").html(informationHtml);

                bindFppData();
            }
            else {
                $("#fldCasinoWalletFpp").hide();
                $('#cwFppMinClaimPoints').val(0);
                $('#cwFppPoints').val(0);
            }            
            $(document).trigger("BALANCE_UPDATED");
        });
    }

    function bindFppData() {
        $('#cwFppMinClaimPoints').val(_convertionMinClaimPoints);
        $('#cwFppPoints').val(_points);
        if (_points >= _convertionMinClaimPoints)
            $('#btnClaimCasinoWalletFPP').attr('disabled', false).removeClass('Inactive');
        else
            $('#btnClaimCasinoWalletFPP').attr('disabled', true).addClass('Inactive');
    }

    $(function () { 
        $('#btnClaimCasinoWalletFPP').attr('disabled', false);

        initFppData();

        $('#btnClaimCasinoWalletFPP').click(function (e) {
            e.preventDefault();

            if (_points > 0) {
                if (_points < _convertionMinClaimPoints) {
                    var msg = '<%= this.GetMetadata(".Points_Not_Enough").SafeJavascriptStringEncode() %>';
                    msg = msg.replace(/(\x7B\x30\x7D)/mg, _points.toString(10));
                    msg = msg.replace(/(\x7B\x31\x7D)/mg, _convertionMinClaimPoints.toString(10));
                    alert(msg);
                }
                else {
                    $('#btnClaimCasinoWalletFPP').toggleLoadingSpin(true);

                    $('#cwFppMinClaimPoints').val('<%=this.GetMetadata(".Claiming").SafeJavascriptStringEncode() %>');
                    $('#cwFppPoints').val('<%=this.GetMetadata(".Claiming").SafeJavascriptStringEncode() %>');

                    var url = '<%= this.Url.RouteUrl("CasinoLobby", new { @action = "ClaimFrequentPlayerPoints" }).SafeJavascriptStringEncode() %>';
                    $.getJSON(url, function (json) {
                        $('#btnClaimCasinoWalletFPP').toggleLoadingSpin(false);
                                                
                        if (!json.success) {
                            bindFppData();
                            alert(json.error);
                            return;
                        }
                        _points = json.remainder;
                        _convertionMinClaimPoints = json.convertionMinClaimPoints;
                        _convertionCurrency = json.convertionCurrency;
                        _convertionPoints = json.convertionPoints;
                        _convertionAmount = json.convertionAmount;
                        _convertionType = json.convertionType;

                        bindFppData();

                        var msg = '<%= this.GetMetadata(".Claim_Done").SafeJavascriptStringEncode() %>';
                        msg = msg.replace(/(\x7B\x30\x7D)/mg, json.converted.toString(10));
                        msg = msg.replace(/(\x7B\x31\x7D)/mg, json.rewardCurrency);
                        msg = msg.replace(/(\x7B\x32\x7D)/mg, json.rewardAmount);
                        msg = msg.replace(/(\x7B\x33\x7D)/mg, json.remainder);
                        alert(msg);

                        $(document).trigger("BALANCE_UPDATED");
                    });
                }
            }
        });
    });
</script>

 <%} %>
    <%
        sportsBonusMessage = this.GetMetadata(".Sports_Bonus_Message");
        sportsBonusUrl = GetOMBonusURL();
        if (!string.IsNullOrEmpty(sportsBonusMessage) && !string.IsNullOrEmpty(sportsBonusUrl))
        {
            sportsBonusMessage = string.Format(sportsBonusMessage, sportsBonusUrl);
    %>
    <br />
    <ui:Fieldset ID="fldSportsBonus" runat="server" Legend="<%$ Metadata:value(.Sports_Bonus) %>">
        <%: Html.InformationMessage( sportsBonusMessage, true ) %>
        <hr />
    </ui:Fieldset>
    <%  } %>
</ui:Panel>
</div>
        <script type="text/javascript">
            $(function () {
                console.log('reload bonus');
                setTimeout(function(){
                    $(document).trigger("BALANCE_UPDATED");
                },1000);
            });
    </script>
</asp:Content>

