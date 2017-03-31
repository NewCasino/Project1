<%@ WebHandler Language="C#" Class="_see_gmcore_bonus" %>

using System;
using System.Linq;
using System.Web;
using System.Text;
using GamMatrixAPI;
using GmCore;

public class _see_gmcore_bonus : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {

       
        try
        {
            VendorID vendorID;
            if (!Enum.TryParse<VendorID>(context.Request.QueryString["vendor"], out vendorID))
                vendorID = VendorID.CasinoWallet;
        
            ProfileCommon.Current.Init(context);
            
            if (!ProfileCommon.Current.IsAuthenticated)
            {
                context.Response.Write("Not logged In");
                context.Response.ContentType = "text/plain";
                return;
            }
       
            GamMatrixClient client = new GamMatrixClient();
            var accounts = GamMatrixClient.GetUserGammingAccounts(ProfileCommon.Current.UserID);
            var account = accounts.First(a => a.Record.VendorID == VendorID.CasinoWallet);

            
            byte[] buffer;
            byte[] bufferABD = null;
            if (vendorID == VendorID.CasinoWallet)
            {
                GetUserAvailableCasinoBonusDetailsRequest request = new GetUserAvailableCasinoBonusDetailsRequest()
                {
                    AccountID = account.ID,
                };

                request = client.SingleRequest<GetUserAvailableCasinoBonusDetailsRequest>(request);
                buffer = ObjectHelper.XmlSerialize(request);
            }
            else
            {
                GetUserAvailableBonusDetailsRequest request = new GetUserAvailableBonusDetailsRequest()
                {
                    VendorID = vendorID,
                    UserID = ProfileCommon.Current.UserID,
                };

                request = client.SingleRequest<GetUserAvailableBonusDetailsRequest>(request);
                buffer = ObjectHelper.XmlSerialize(request);
            }

            if (Settings.IsOMSeamlessWalletEnabled)
            {
                GetUserAvailableBonusDetailsRequest requestABD = new GetUserAvailableBonusDetailsRequest()
                {
                    UserID = ProfileCommon.Current.UserID,
                    VendorID = VendorID.OddsMatrix
                };

                requestABD = client.SingleRequest<GetUserAvailableBonusDetailsRequest>(requestABD);
                bufferABD = ObjectHelper.XmlSerialize(requestABD);
            }
            context.Response.Write("<Root>");
            context.Response.Write(Encoding.UTF8.GetString(buffer));
            
            if (bufferABD != null && bufferABD.Length > 0)
            {
                context.Response.Write(Encoding.UTF8.GetString(bufferABD));
            }
            context.Response.Write("</Root>");
            context.Response.ContentType = "text/xml";
        }
        catch (Exception ex)
        {
            context.Response.Write(ex.Message);
        }
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}