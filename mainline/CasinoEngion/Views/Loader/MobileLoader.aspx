<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage" %>

<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">


</script>

<html xmlns="http://www.w3.org/1999/xhtml" lang="EN">
<head>
    <title></title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="pragma" content="no-cache" />
    <meta http-equiv="cache-control" content="no-store, must-revalidate" />
    <meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
    <style type="text/css">
        html, body {
            width: 100%;
            height: 100%;
            padding: 0px;
            margin: 0px;
            background: #E9E9E9;
        }

        #ifmGame {
            width: 100%;
            height: 100%;
            border: 0px;
        }
    </style>
    <script language="javascript" type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
    <script type="text/javascript">

        $(document).ready(function () {

            var vendorSide = false;
            $('#ifmGame').load(function () {

                vendorSide = !vendorSide;
                if (!vendorSide) {
                    window.location.href = '<%=ViewData["Lobby"]%>';
                }
            });
            setFrameSource();
        });

        //setTimeout(show, 10000);
        //show();

        function setFrameSource() {
            //var url = 'https://m.rgsgames.com/games/index.html?softwareid=200-1186-001&language=en&nscode=BOYL&skincode=BY01&E024_domainid=1113&currencycode=FPY&uniqueid=e23256375ce8403b87b5a3b04f033548&countrycode=UA&minbet=1.0&denomamount=1.0';
            //var url = 'http://mobile9.gameassists.co.uk/MobileWebGames/game/mgs/4_19_2?lobbyName=BoylesGIBcom&languageCode=en&casinoID=1861&loginType=VanguardSessionToken&bankingURL=http%3A%2F%2Fmobile9.gameassists.co.uk%2Fmobileweblobby%3F&gameName=bridesmaids&clientID=40300&moduleID=10424&clientTypeID=40&xmanEndPoints=https%3A%2F%2Fqplay9.gameassists.co.uk%2FXMan%2Fx.x&gameTitle=bridesmaids&lobbyURL=&helpURL=&isPracticePlay=true&isRGI=true&authToken=';
            //var url = 'https://boylegames-assets.realisticgames.co.uk/boylegamesem/phones/ver1.6/android/SGUD/en/demo.html#game';
            var url = '<%= this.ViewData["LaunchUrl"] %>';
            $('#ifmGame').prop('src', url);
        }

    </script>
    
    <script type="text/javascript">
        



    </script>


</head>
<body>
    
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" ></iframe>

</body>
</html>
