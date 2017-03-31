using GamMatrixAPI;

namespace GamMatrix.CMS.Models.MobileShared.AvailableBonus
{
	public class AvailableBonusViewModel
	{
		public BonusInfo<BonusData> Casino { get; set; }
		public BonusInfo<AvailableBonusData> Sports { get; set; }
        public BonusInfo<AvailableBonusData> BetConstruct { get; set; }
	}
}
