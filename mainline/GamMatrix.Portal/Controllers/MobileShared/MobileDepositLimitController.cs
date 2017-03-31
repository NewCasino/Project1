using System.Web.Mvc;
using System.Collections.Generic;
using System.Linq;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[RequireLogin]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "DepositLimitSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class MobileDepositLimitController : DepositLimitationController
	{

		[HttpGet]
		public override ActionResult Index()
		{
            List<RgDepositLimitInfoRec> records = GetLimitRecords();

            if (records != null)
                return View("Index", records);

			return Edit();
		}

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult Edit(long limitID = 0)
		{
            RgDepositLimitInfoRec rec;
            if (limitID > 0)
                rec = GetLimitRecord(limitID);
            else
                rec = GetLimitRecord();

            return View("Edit", rec);
		}

        private RgDepositLimitInfoRec GetLimitRecord()
        {
            RgDepositLimitInfoRec record = null;


            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetUserRgDepositLimitRequest getUserRgDepositLimitRequest = client.SingleRequest<GetUserRgDepositLimitRequest>(new GetUserRgDepositLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID,                    
                });
                record = getUserRgDepositLimitRequest.Record;
            }

            return record;
        }

        private RgDepositLimitInfoRec GetLimitRecord(long limitID)
        {
            List<RgDepositLimitInfoRec> records = GetLimitRecords();
            if (records != null && records.Exists(r => r.ID == limitID))
            {
                return records.FirstOrDefault(r => r.ID == limitID);
            }

            return null;            
        }

		private List<RgDepositLimitInfoRec> GetLimitRecords()
		{
            List<RgDepositLimitInfoRec> records = null;

            
			using (GamMatrixClient client = GamMatrixClient.Get())
			{
                if (Settings.Limitation.Deposit_MultipleSet_Enabled)
                {
                    GetUserRgDepositLimitListRequest getUserRgDepositLimitListRequest = client.SingleRequest<GetUserRgDepositLimitListRequest>(new GetUserRgDepositLimitListRequest
                    {
                        UserID = CustomProfile.Current.UserID
                    });

                    return getUserRgDepositLimitListRequest.DepositLimitRecords;
                }
                else
                {
                    GetUserRgDepositLimitRequest getUserRgDepositLimitRequest = client.SingleRequest<GetUserRgDepositLimitRequest>(new GetUserRgDepositLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID
                    });
                    if (getUserRgDepositLimitRequest.Record != null)
                    {
                        return new List<RgDepositLimitInfoRec>()
                        {
                            getUserRgDepositLimitRequest.Record
                        };
                    }
                }
			}

            return null;
		}
	}
}