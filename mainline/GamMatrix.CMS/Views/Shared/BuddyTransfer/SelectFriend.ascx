<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<script type="text/C#" language="C#" runat="server">
    private Dictionary<string, string> Friends{ get; set; }
    
    private Dictionary< string , string> GetFriends()
    {
        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            GetTransRequest getTransRequest = client.SingleRequest<GetTransRequest>(new GetTransRequest()
            {
                SelectionCriteria = new TransSelectParams()
                {
                    ByTransTypes = true,
                    ParamTransTypes = new List<TransType> { TransType.User2User },

                    ByUserID = true,
                    ParamUserID = Profile.UserID,
                },
                PagedData = new PagedDataOfTransInfoRec()
                {
                    PageSize = 1000,
                    PageNumber = 0,
                }
            });

            if (getTransRequest.PagedData.Records != null)
            {
                var from = getTransRequest.PagedData.Records.Where(r => r.UserID == Profile.UserID)
                    .Select(r => new { Value = r.ContraUserName, Key = r.ContraUserID.ToString() }).Distinct();
                var to = getTransRequest.PagedData.Records.Where(r => r.ContraUserID == Profile.UserID)
                    .Select(r => new { Value = r.UserName, Key = r.UserID.ToString() }).Distinct();
                var friends = from.Union(to).Distinct();

                return friends.ToDictionary(f => f.Key, f => f.Value);
            }
        }
        return new Dictionary<string, string>();        
    }

    protected override void  OnPreRender(EventArgs e)
    {
        Friends = GetFriends();
        
        base.OnPreRender(e);        
    }
</script>

<ui:TabbedContent ID="tabbedFriends" runat="server">
    <Tabs>


        <%---------------------------------------------------------------
            Find a friend
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabFindFriend" Caption="<%$ Metadata:value(.Tab_FindFriend) %>"  Selected="true">
            <form id="formFindFriend" onsubmit="return false" 
                action="<%= this.Url.RouteUrl("BuddyTransfer", new { @action = "FindFriend" }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">

                <%------------------------
                    Username
                -------------------------%> 
                <ui:InputField ID="fldUsername" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".Friend_Username_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox( "username", string.Empty, new 
                        {
                            @maxlength = "50",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".Friend_Username_Empty"))
                        })  %>
                    </ControlPart>
                </ui:InputField>

                <%------------------------
                    Email
                -------------------------%> 
                <ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".Friend_Email_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox( "email", string.Empty, new 
                        {
                            @maxlength = "100",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".Friend_Email_Empty"))
                        })  %>
                    </ControlPart>
                </ui:InputField>

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnFindFriend" })%>
                </center>
            </form>

        </ui:Panel>


        <%---------------------------------------------------------------
            Choose a friend
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabChooseFriend" Caption="<%$ Metadata:value(.Tab_ChooseFriend) %>">

        
        <form id="formChooseFriend" onsubmit="return false" method="post" action="<%= this.Url.RouteUrl("BuddyTransfer", new { @action = "ValidateFriend" }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">

            <%------------------------
                Friend List
            -------------------------%> 
            <ui:InputField ID="fldFriend" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Friend_Select").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>

                <ul id="paycards-selector">
                    <% foreach (var entry in this.Friends)
                       {
                           %>
                    <li>
                        <input type="radio" name="friendUserID" value="<%= entry.Key %>" id="friend_<%= entry.Key %>" />
                        <label for="friend_<%= entry.Key %>">
                            <%= entry.Value.SafeHtmlEncode() %>
                        </label>
                    </li>
                    <% } %>
                </ul>
                <%: Html.Hidden("userID", "", new 
                    { 
                        @id = "hFriendUserID",
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".Friend_Select_Empty")) 
                    }) %>
                </ControlPart>
            </ui:InputField>
            <script language="javascript" type="text/javascript">
                $('#fldFriend input[type="radio"]').click(function () {
                    $('#hFriendUserID').val($(this).val());

                    //<%-- trigger the validation --%>
                    if (InputFields.fields['fldFriend'])
                        InputFields.fields['fldFriend'].validator.element($('#hFriendUserID'));
                });
            </script>            

            <center>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnTransferToExistingFriend" })%>
            </center>

        </form>

        </ui:Panel>


    </Tabs>
</ui:TabbedContent>

<script language="javascript" type="text/javascript">
    function __validateResponseJson(json) {
        if (json.result == 1) {
            showBuddyTransferError('<%= this.GetMetadata(".Friend_UsernameOrEmail_Incorrect").SafeJavascriptStringEncode() %>');
            return false;
        }
        if (json.result == 2) {
            showBuddyTransferError('<%= this.GetMetadata(".Friend_Email_Inactive").SafeJavascriptStringEncode() %>');
            return false;
        }
        if (json.result == 3) {
            showBuddyTransferError('<%= this.GetMetadata(".Friend_Blocked").SafeJavascriptStringEncode() %>');
            return false;
        }
        if (json.result == 4) {
            showBuddyTransferError('<%= this.GetMetadata(".Friend_NotVerified").SafeJavascriptStringEncode() %>');
            return false;
        }
        if (json.result == 5) {
            showBuddyTransferError('<%= this.GetMetadata(".Friend_Invalid").SafeJavascriptStringEncode() %>');
            return false;
        }
        return true;
    }
    $(document).ready(function () {
        $('#formFindFriend').initializeForm();
        $('#formChooseFriend').initializeForm();

        $('#btnFindFriend').click(function (e) {
            e.preventDefault();
            if (!$('#formFindFriend').valid())
                return;

            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#btnFindFriend').toggleLoadingSpin(false);
                    if (!json.success) {
                        $('#btnFindFriend').toggleLoadingSpin(false);
                        showBuddyTransferError(json.error);
                        return;
                    }
                    if (__validateResponseJson(json)) {
                        showBuddyTransferPrepare(json.userid);
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnFindFriend').toggleLoadingSpin(false);
                    showBuddyTransferError(errorThrown);
                }
            };
            $('#formFindFriend').ajaxForm(options);
            $('#formFindFriend').submit();
        });

        $('#btnTransferToExistingFriend').click(function (e) {
            e.preventDefault();
            if (!$('#formChooseFriend').valid())
                return;

            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#btnTransferToExistingFriend').toggleLoadingSpin(false);
                    if (!json.success) {
                        showBuddyTransferError(json.error);
                        return;
                    }

                    if (__validateResponseJson(json)) {
                        showBuddyTransferPrepare(json.userid);
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnTransferToExistingFriend').toggleLoadingSpin(false);
                    showBuddyTransferError(errorThrown);
                }
            };
            $('#formChooseFriend').ajaxForm(options);
            $('#formChooseFriend').submit();
        });

        <%if(Friends.Keys.Count == 0) {%>
        $('.tab[forid="tabChooseFriend"]').hide();
        $('#tabChooseFriend').hide();
        <%}%>
    });
</script>