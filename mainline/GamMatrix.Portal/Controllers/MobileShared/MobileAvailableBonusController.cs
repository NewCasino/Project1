using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GamMatrix.CMS.Models.MobileShared.AvailableBonus;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
    [RequireLogin]
	[ControllerExtraInfo(DefaultAction = "Index")]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "AvailableBonusSection")]
    public class MobileAvailableBonusController : AvailableBonusController 
    {
		public void IndexAsync()
		{
			RequestCasinoBonus();
			if (Settings.IsOMSeamlessWalletEnabled)
				RequestSportsBonus();
            if (Settings.IsBetConstructWalletEnabled)
                RequestBetConstructBonus();
		}

		public ViewResult IndexCompleted(List<BonusData> casinoBonuses
			, Exception casinoBonusException
			, List<AvailableBonusData> sportsBonuses
			, Exception sportsBonusException
            , List<AvailableBonusData> betConstructBonuses
            , Exception betConstructException)
		{
			var model = new AvailableBonusViewModel
			{
				Casino = new BonusInfo<BonusData>(casinoBonuses, casinoBonusException),
				Sports = new BonusInfo<AvailableBonusData>(sportsBonuses, sportsBonusException),
                BetConstruct = new BonusInfo<AvailableBonusData>(betConstructBonuses, betConstructException),
			};

			return View(model);
		}

		#region RequestCasinoBonus
		private void RequestCasinoBonus()
		{
			AsyncManager.OutstandingOperations.Increment();

			GamMatrixClient.SingleRequestAsync<GetUserBonusDetailsRequest>(new GetUserBonusDetailsRequest
			{
				UserID = CustomProfile.Current.UserID
			}
			, OnCasinoBonusReceived);
		}

		private void OnCasinoBonusReceived(AsyncResult reply)
		{
			try
			{
				var request = reply.EndSingleRequest().Get<GetUserBonusDetailsRequest>();

				var bonuses = request.Data
					.Where(b => b.VendorID == VendorID.NetEnt || b.VendorID == VendorID.CasinoWallet)
					.ToList();

				foreach (BonusData bonus in bonuses)
				{
					if (!string.Equals(bonus.Status, "Queued", StringComparison.InvariantCultureIgnoreCase))
					{
						if (string.Equals(bonus.Type, "No deposit", StringComparison.InvariantCultureIgnoreCase) ||
							string.Equals(bonus.Type, "Free Spin bonus", StringComparison.InvariantCultureIgnoreCase))
						{
							bonus.ConfiscateAllFundsOnForfeiture = false;
						}
					}
				}

				AsyncManager.Parameters["casinoBonuses"] = bonuses;
			}
			catch (Exception exception)
			{
				AsyncManager.Parameters["casinoBonusException"] = exception;
			}
			finally
			{
				AsyncManager.OutstandingOperations.Decrement();
			}
		}
		#endregion

		#region RequestSportsBonus
		private void RequestSportsBonus()
		{
			AsyncManager.OutstandingOperations.Increment();

			GamMatrixClient.SingleRequestAsync<GetUserAvailableBonusDetailsRequest>(new GetUserAvailableBonusDetailsRequest
			{
				UserID = CustomProfile.Current.UserID
			}
			, OnSportsBonusReceived);
		}

		private void OnSportsBonusReceived(AsyncResult reply)
		{
			try
			{
				var request = reply.EndSingleRequest().Get<GetUserAvailableBonusDetailsRequest>();

				List<AvailableBonusData> bonuses = null;
				if (request != null && request.Data != null)
				{
					bonuses = request.Data
						.Where(b => b.VendorID == VendorID.OddsMatrix)
						.ToList();
				}

				AsyncManager.Parameters["sportsBonuses"] = bonuses;
			}
			catch (Exception exception)
			{
				AsyncManager.Parameters["sportsBonusException"] = exception;
			}
			finally
			{
				AsyncManager.OutstandingOperations.Decrement();
			}
		}
		#endregion

        #region RequestSportsBonus
        private void RequestBetConstructBonus()
        {
            AsyncManager.OutstandingOperations.Increment();

            GamMatrixClient.SingleRequestAsync<GetUserAvailableBonusDetailsRequest>(new GetUserAvailableBonusDetailsRequest
            {
                UserID = CustomProfile.Current.UserID
            }
            , OnBetConstructBonusReceived);
        }

        private void OnBetConstructBonusReceived(AsyncResult reply)
        {
            try
            {
                var request = reply.EndSingleRequest().Get<GetUserAvailableBonusDetailsRequest>();

                List<AvailableBonusData> bonuses = null;
                /*if (request != null && request.Data != null)
                {
                    bonuses = request.Data
                        .Where(b => b.VendorID == VendorID.BetConstruct)
                        .ToList();
                }*/

                AsyncManager.Parameters["betConstructBonuses"] = bonuses;
            }
            catch (Exception exception)
            {
                AsyncManager.Parameters["betConstructException"] = exception;
            }
            finally
            {
                AsyncManager.OutstandingOperations.Decrement();
            }
        }
        #endregion
	}
}