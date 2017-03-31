using System;
using System.Collections.Generic;
using System.Linq;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.AvailableBonus
{
	public class BonusInfo<T>
	{
		public List<T> Bonuses { get; private set; }
		public string ErrorMessage { get; private set; }

		public BonusInfo(List<T> bonuses, Exception exception)
		{
			Bonuses = bonuses;

			if (exception != null)
				ErrorMessage = GmException.TryGetFriendlyErrorMsg(exception);
		}

		public bool HasBonuses()
		{
			return Bonuses != null && Bonuses.Count() > 0;
		}

		public bool HasError()
		{
			return !string.IsNullOrEmpty(ErrorMessage);
		}
	}
}
