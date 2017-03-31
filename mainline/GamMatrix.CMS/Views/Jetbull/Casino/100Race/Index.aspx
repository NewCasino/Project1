<%@ Page Language="C#" PageTemplate="/SinglePageMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <style type="text/css">
        .lb-wrap {
            position:absolute;
            right:0px;
            top:-80px;
            height:400px;
            width:340px;
            border-radius:1em;
            background:#000;
            border:5px solid #000;
            background:rgba(0,0,0,.5);
            font-size:14px;
            overflow:hidden;
            padding:10px;
        }
            .lb-wrap h2 {
                text-align:center;
                font-size:26px;
                margin-bottom:5px;
            }
        .lb-title {
            width:314px;
            display:inline-block;
        }
        .lb-title span {
            float:right;
            display:block;
            width:100px;
            text-align:right;
            margin-right:5px;
        }
        
        .lb-content {
            
        }

        .lb-c-u li {
            margin:0;
            display:inline-block;
            line-height:14px;
            margin-bottom:8px;
        }
        .lb-c-u span {
            float:left;
            display:block;
            text-align:left;
            margin-right:5px;
        }
            .lb-c-u span.rank {
                width:30px;
            }
            .lb-c-u span.country-flags {
                width:30px;
                height: 13px;
                overflow:hidden;
                display:block;
            }
            .lb-c-u span.initial {
                width:30px;
                text-align:center;
            }
            .lb-c-u span.uid {
                width:100px;
                text-align:right;
            }
            .lb-c-u span.score {
                width:100px;
                text-align:right;
            }

        .lb-c-u .country-flags img {
            display:inherit;
            width:auto;
            margin:0px;
            border-radius:0;
            box-shadow:none;
        }
    </style>
    <div class="lb-wrap">
        <h2>Leaderboard</h2>
        <div class="lb-title">
            <span class="score">Score</span>
            <span class="uid">PlayerID</span>
        </div>
        <div class="lb-content" id="lb-content">
            <ul id="lb-c-u" class="lb-c-u">
                
            </ul>
        </div>
    </div>
<script src="//cdn.everymatrix.com/_js/jCarouselLite.js" type="text/javascript"></script>
<script type="text/javascript">
    $(function () {
        $.getJSON("/_get_casinorace.ashx?xmlurl=<%=HttpUtility.UrlEncode(this.GetMetadata(".FeedLink").SafeJavascriptStringEncode())%>",
            function (rankScoreData) {
                var _a_ = [];
                for (var i = 0 ; i < rankScoreData.length; i++) {
                    var rank = rankScoreData[i];
                    _a_.push($.format('<li><span class="rank">{0}.</span>' +
                            '<span class="country-flags">' +
                            '    <img alt="{1}" src="/images/transparent.gif" class="{2}">' +
                            '</span>' +
                            '<span class="initial">{3}</span>' +
                            '<span class="uid">{4}</span>' +
                            '<span class="score">{5}</span></li>',
                            rank.Rank,
                            rank.CountryName,
                            rank.CountryCode,
                            rank.Initials,
                            rank.PlayerID,
                            rank.Score
                            ));
                }
                $("#lb-c-u").html(_a_.join(''));
                $(".lb-content").jCarouselLite({
                     vertical: true,
                     visible: 20,
                     speed: 1000,
                     auto: 2000
                 });
            });
    });
</script>
<%= this.GetMetadata(".HTML") %>
</asp:Content>

