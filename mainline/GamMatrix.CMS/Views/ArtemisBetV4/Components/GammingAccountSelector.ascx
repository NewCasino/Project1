<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="Finance" %>
<script language="C#" type="text/C#" runat="server">
    private string HiddenFieldName { get { return (this.ViewData["HiddenFieldName"] as string).DefaultIfNullOrEmpty(Guid.NewGuid().ToString("N")); } }

    private string m_TableID;
    private string TableID 
    {
        get
        {
            if (!string.IsNullOrWhiteSpace(m_TableID))
                return m_TableID;
            m_TableID = this.ViewData["TableID"] as string;
            if( string.IsNullOrWhiteSpace(m_TableID) )
                m_TableID = Guid.NewGuid().ToString("N");
            return m_TableID; 
        }
    }

    private bool HideCurrencyAmount
    {
        get
        {
            if (this.ViewData["HideCurrencyAmount"] == null)
                return false;
            return (bool)this.ViewData["HideCurrencyAmount"];
        }
    }
    private bool _DisplayBonusAmount = true;
    private bool DisplayBonusAmount {
        get {
            if (this.ViewData["DisplayBonusAmount"] != null)
            {
                if (!bool.TryParse(this.ViewData["DisplayBonusAmount"].ToString(), out _DisplayBonusAmount))
                {
                    _DisplayBonusAmount = true; 
                }
            }
            return _DisplayBonusAmount;
        }
    }
    private int UserID
    {
        get
        {
            if (this.ViewData["UserID"] != null)
                return (int)this.ViewData["UserID"];
            return Profile.UserID;
        }
    }
    
    private string ClientOnChangeFunction { get { return this.ViewData["ClientOnChangeFunction"] as string; } }
    private object SelectedValue { get { return this.ViewData["SelectedValue"]; } }

    private bool AutoSelect 
    { 
        get 
        {
            try
            {
                return (bool)this.ViewData["AutoSelect"]; 
            }
            catch
            {
                return false;
            }
        } 
    }
</script>

<% 
    if (Profile.IsAuthenticated)
    {
        using (var table = Html.BeginSelectableTable(this.HiddenFieldName, this.SelectedValue, "AccountID", new { @id = this.TableID }))
        {
            if (!string.IsNullOrWhiteSpace(this.ClientOnChangeFunction))
                table.OnClientSelectionChanged = this.ClientOnChangeFunction;

            if (!this.HideCurrencyAmount)
            {
                table.DefineColumns(
                    new SelectableTableColumn()
                    {
                        DateFieldName = "DisplayName"
                    },
                    new SelectableTableColumn()
                    {
                        DateFieldName = "BalanceCurrency"
                    },
                    new SelectableTableColumn()
                    {
                        DateFieldName = "FormattedAmount"
                    },
                    new SelectableTableColumn()
                    {
                        DateFieldName = "IsBonusCodeInputEnabled",
                        IsVisible = false,
                    },
                    new SelectableTableColumn()
                    {
                        DateFieldName = "IsBonusSelectorEnabled",
                        IsVisible = false,
                    },
                    new SelectableTableColumn()
                    {
                        DateFieldName = "VendorID",
                        IsVisible = false,
                    }
                );
            }
            else
            {
                table.DefineColumns(
                    new SelectableTableColumn()
                    {
                        DateFieldName = "DisplayName"
                    },
                    new SelectableTableColumn()
                    {
                        DateFieldName = "IsBonusCodeInputEnabled",
                        IsVisible = false,
                    },
                    new SelectableTableColumn()
                    {
                        DateFieldName = "IsBonusSelectorEnabled",
                        IsVisible = false,
                    },
                    new SelectableTableColumn()
                    {
                        DateFieldName = "VendorID",
                        IsVisible = false,
                    }
                );
            }
            
            List<GamMatrixAPI.AccountData> list = GamMatrixClient.GetUserGammingAccounts( this.UserID, false);
            /*
            string listLog = string.Empty;
            foreach (var accountData in list)
            {
                listLog += accountData.Record.VendorID + ", ";
            }

            Logger.Information("DepositPrepare", "AccountList - From Core, UserID={0}, Accounts={1}", UserID, listLog);
            */
            var accounts = list
                    .Where(a => a.Record.ActiveStatus == GamMatrixAPI.ActiveStatus.Active && a.IsBalanceAvailable)
                    .Select(a => new
                    {
                        AccountID = a.Record.ID.ToString(),
                        VendorID = a.Record.VendorID.ToString(),
                        DisplayName = a.Record.VendorID.GetDisplayName(),
                        BalanceCurrency = a.BalanceCurrency,
                        BalanceAmount = Math.Truncate(a.BalanceAmount * 100.00M) / 100.00M,
                        BonusAmount = a.BonusAmount,
                        FormattedAmount = a.FormatBalanceAmount(DisplayBonusAmount),
                        IsBonusCodeInputEnabled = Settings.IsBonusCodeInputEnabled(a.Record.VendorID),
                        IsBonusSelectorEnabled = Settings.IsBonusSelectorEnabled(a.Record.VendorID),
                    }).ToList();
            /*
            string activeAcountsLog = string.Empty;
            foreach (var accountData in accounts)
            {
                string value = ObjectHelper.GetFieldValue<object>(accountData, "VendorID").ToString();
                activeAcountsLog += value + ", ";
            }

            Logger.Information("DepositPrepare", "Accounts List - Only Active, UserID={0}, Accounts={1}", UserID, activeAcountsLog
            */

            List<object> filteredAcounts = new List<object>();
            // reorder the account
            string [] paths = Metadata.GetChildrenPaths("/Metadata/GammingAccount/");
            for (int i = 0; i < paths.Length; i++)
            {
                string name = global::System.IO.Path.GetFileName(paths[i]);
                var account = accounts.FirstOrDefault(a => a.VendorID == name);
                if (account != null)
                {
                    filteredAcounts.Add(account);
                }
            }

            table.RenderRows(filteredAcounts);
        }
    }
%>

<script type="text/javascript">
    window.setTimeout(function () {
        
        if ($('#<%= this.TableID %>').getSelectableTableValueField() == null) {
            var $rows = $('tr', $('#<%= this.TableID %>'));
            for (var i = 0; i < $rows.length; i++) {
                var key = $($rows[i]).attr('key');

                // <%-- Select the first entry if non-selected --%>
              <%--  <% if( this.AutoSelect ) { %>
                    $('#<%= this.TableID %>').setSelectableTableValue(key);
                    break;
                <% } %>--%>
            }
          <%--  window.setTimeout(function () {
                $('#<%= this.TableID %> tr[class="selected"]').trigger('click');
            }, 1000);--%>
             <% if( this.AutoSelect ) { %>
                    $('#<%= this.TableID %> tr:first').trigger('click');
                <% } %>
        }
    }, 1000);
</script>