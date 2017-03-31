using System.Collections.Generic;
using CasinoEngine;

namespace GamMatrix.CMS.Models.MobileShared.Casino.Components
{
	public class GameCategoryData
	{
		public string Id;
		public string Name;
		public List<Game> Games;

		public GameCategoryData()
		{
			Games = new List<Game>();
		}
	}
}
