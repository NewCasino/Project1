<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script runat="server">
    protected string CountryName = string.Empty;
    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);
        int countryId = Profile.IpCountryID;
        if (Profile.IsAuthenticated)
            countryId = Profile.UserCountryID;
        var country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == countryId);
        if (country != null)
            CountryName = country.DisplayName;
    }
    public bool IsHorizontal
    {
        get
        {
            if (ViewData["IsHorizontal"] == null)
                return true;

            return (ViewData["IsHorizontal"] as string).Equals("IsHorizontal", StringComparison.InvariantCultureIgnoreCase);
        }
    }
    private string InternalClass
    {
        get
        {
            return IsHorizontal ? "HorizontalLayout" : "VerticalLayout";
        }
    }

    private string ContainerClass
    {
        get
        {
            return ViewData["ContainerClass"] == null ? string.Empty : ViewData["ContainerClass"] as string;
        }
    }


</script>
<div class="PopularGamesInCountryWrap <%=InternalClass %> <%=ContainerClass %>">
 <script type="text/javascript">
     function getPpopularCountryGames(callBack) {
         $.getJSON("/Casino/Hall/GetPopularityGamesInCountry", function (json) {
             json = [{ "ID": 7726, "P": 1, "V": 108, "G": "Thunderstruck", "I": "//static.gammatrix.com/_casino/4/4D0C9721EF53FCF64372B3C9FF6FD03C.jpg", "F": 1, "R": 0, "S": "thunderstruck", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/F/F40218916FFAEC59A867D4813672706C.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7730, "P": 1, "V": 108, "G": "Tomb Raider", "I": "//static.gammatrix.com/_casino/8/80133BA37B9A991CAFA2845069E359DC.jpg", "F": 1, "R": 0, "S": "tomb-raider", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/E/EEC3FC1EC8304C11E1DE446BCD830B1F.png", "CP": "NetEnt", "Fav": 0 }, { "ID": 7139, "P": 1, "V": 108, "G": "Hot Ink", "I": "//static.gammatrix.com/_casino/D/DE7AC4D044EB1056FAA92E7DE9AC6F41.jpg", "F": 1, "R": 0, "S": "hot-ink", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/A/A0DDFD0DA6280C7CEA1BD0743D54804D.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7752, "P": 1, "V": 108, "G": "Cool Buck", "I": "//static.gammatrix.com/_casino/F/F4244B59E6CCF2223C08B9580AC46DBE.jpg", "F": 1, "R": 0, "S": "cool-buck-microgaming", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/6/67CA9D680A49956800A7C5042A4C28B1.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7121, "P": 1, "V": 108, "G": "Jackpot Express", "I": "//static.gammatrix.com/_casino/5/5AE2E9B42562B825591E3C6AB3942349.jpg", "F": 1, "R": 0, "S": "jackpot-express", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/2/2FC0912329FAFB09CC1FECDA5AB001DB.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7075, "P": 1, "V": 108, "G": "Fruit Fiesta", "I": "//static.gammatrix.com/_casino/7/7B644767D7B224AC2A34A0E854D350FF.jpg", "F": 0, "R": 0, "S": "fruit-fiesta-3-reel", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/9/9B921CBA0546407FBBF879A38F5FC745.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7073, "P": 1, "V": 108, "G": "Cash Splash", "I": "//static.gammatrix.com/_casino/B/B15E5273C77CB212F7E098AEA42D478F.jpg", "F": 0, "R": 0, "S": "cashsplash-3-reel", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/1/16629FB1A20ADA212124C97ED269AF90.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7116, "P": 1, "V": 108, "G": "Flying Ace", "I": "//static.gammatrix.com/_casino/2/2555C244FB0D7A4A2AEACD61410FC25D.jpg", "F": 1, "R": 0, "S": "flying-ace", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/2/2CA1DED3C2A5CFBDEABAB22276A2C7A7.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7129, "P": 1, "V": 108, "G": "Triple Magic", "I": "//static.gammatrix.com/_casino/8/83FB4230D3C7BCEEA8C69724DF28525B.jpg", "F": 1, "R": 0, "S": "triple-magic", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/C/C67584D22FD6F53CB333C15E48F6838C.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7122, "P": 1, "V": 108, "G": "Jingle Bells", "I": "//static.gammatrix.com/_casino/4/4F150EF8B03C204604D6FB8E3E3C18A4.jpg", "F": 1, "R": 0, "S": "jingle-bells", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/9/9F011AF4BD5022C13B906C857FF5F704.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7189, "P": 1, "V": 108, "G": "Bubble Bonanza", "I": "//static.gammatrix.com/_casino/4/4365CEAC0D133508F2486521F346DA7E.jpg", "F": 1, "R": 0, "S": "bubble-bonanza", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/E/EE3748B10CBD2B0C0811F84FC6DAD66C.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7083, "P": 1, "V": 108, "G": "Tunzamunni", "I": "//static.gammatrix.com/_casino/8/8301D91F12958B67584AD22CD61B86DB.jpg", "F": 0, "R": 0, "S": "tunzamunni", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/7/7C4E515DDD28728C0F2C5326B4D99689.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7076, "P": 1, "V": 108, "G": "Fruit Fiesta 5 Reel", "I": "//static.gammatrix.com/_casino/B/B9CC9B0036E7F31F1A40EAAF9D2A88ED.jpg", "F": 0, "R": 0, "S": "fruit-fiesta-5-reel", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/9/9F99551CFFE56DA6335A0F9AB5311ED4.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7130, "P": 1, "V": 108, "G": "Zany Zebra", "I": "//static.gammatrix.com/_casino/D/DC270ACCF351C323C270AA95BF92DEE7.jpg", "F": 1, "R": 0, "S": "zany-zebra", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/3/32DB86034A19343F2F3C570D363F0DD0.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7117, "P": 1, "V": 108, "G": "Fortune Cookie", "I": "//static.gammatrix.com/_casino/2/24F23821F398C51BE0B86BC274A4EE8D.jpg", "F": 1, "R": 0, "S": "fortune-cookie", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/F/FD7CF99E22AA63BC8D3D5DE9239E4735.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7125, "P": 1, "V": 108, "G": "Rock the Boat", "I": "//static.gammatrix.com/_casino/E/E4E5792115AAD894906B5F39697D6BEE.jpg", "F": 1, "R": 0, "S": "rock-the-boat", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/B/B5FECC62411B002B305DDA9709D44FFD.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7127, "P": 1, "V": 108, "G": "Roman Riches", "I": "//static.gammatrix.com/_casino/8/8FF21492E5DA7FEFDCAA06F3A39473E2.jpg", "F": 1, "R": 0, "S": "roman-riches", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/2/2FFC0BB5871380FA9A439F4F45524534.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7124, "P": 1, "V": 108, "G": "Legacy", "I": "//static.gammatrix.com/_casino/3/325FC5C134147184F0C3F30A5CA9F3DA.jpg", "F": 1, "R": 0, "S": "legacy", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/0/0C8B514CDC083C164C7B84A57FB244C5.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7120, "P": 1, "V": 108, "G": "Golden Dragon", "I": "//static.gammatrix.com/_casino/9/94D9ED4E5D89A55697D49785D277B140.jpg", "F": 1, "R": 0, "S": "golden-dragon", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/8/8CE1184DDF49A33A18DBAC5E1DB53AF0.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7211, "P": 1, "V": 108, "G": "Triangulation", "I": "//static.gammatrix.com/_casino/3/3EF9B1EE6466240E97D045D8D63CC9BA.jpg", "F": 1, "R": 0, "S": "triangulation", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/E/E1A385309647C907A0111369C6118BFB.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7128, "P": 1, "V": 108, "G": "Spe Wheel of Wealth", "I": "//static.gammatrix.com/_casino/4/483696B3A48678FEA58CA08D22F6C0B5.jpg", "F": 1, "R": 0, "S": "spectacular-wheel-of-wealth", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/C/CB29B8864B8C32C7F10F4750E61890CD.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7727, "P": 1, "V": 108, "G": "Break Da Bank", "I": "//static.gammatrix.com/_casino/E/E6F1DC6D1EA8FC17865E95FE2EB2D91A.jpg", "F": 1, "R": 0, "S": "break-da-bank", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/B/B6F982B630DE768E3BF0979AD3A1375A.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7123, "P": 1, "V": 108, "G": "Jurassic Jackpot ", "I": "//static.gammatrix.com/_casino/0/0747BDD38BC73DB0EB8158461EF98ADC.jpg", "F": 1, "R": 0, "S": "jurassic-jackpot", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/9/96A2354B23FC5DE9AFEA58F030E6AA2C.png", "CP": "Microgaming", "Fav": 0 }, { "ID": 7115, "P": 1, "V": 108, "G": "Fantastic 7s", "I": "//static.gammatrix.com/_casino/7/7658E3851623EF4BBAE6794D4A35DE00.jpg", "F": 1, "R": 0, "S": "fantastic-7s", "N": 0, "T": 0, "H": 0, "O": 0, "D": 0, "L": "//static.gammatrix.com/_casino/E/E2337C63E82DF5851B044AA941E5E31E.png", "CP": "Microgaming", "Fav": 0 }];
             callBack({ data: json });
         });
     }
</script>
    <%if(IsHorizontal) {%>
    <% Html.RenderPartial("/Components/GamesSlider", this.ViewData.Merge(new { @ContainerClass = "PopularGames InCountry", @Title = string.Format( this.GetMetadata(".Title_Format"),CountryName), @GetGamesDataFun = "getPpopularCountryGames" })); %>
    <%} %>
</div>
