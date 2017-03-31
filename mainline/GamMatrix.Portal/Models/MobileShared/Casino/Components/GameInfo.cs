using System.Collections.Generic;
using System.Linq;
using CasinoEngine;

namespace GamMatrix.CMS.Models.MobileShared.Casino.Components
{
	public class GameInfo
	{
		public List<Game> Games { get; private set; }

		public GameInfo(List<Game> games)
		{
			Games = games;
		}

		private class GameComparer : IEqualityComparer<Game>
		{
			public bool Equals(Game x, Game y)
			{
				if (x == null || y == null)
					return false;
				return x.ID == y.ID;
			}

			public int GetHashCode(Game obj)
			{
				return obj.ID.GetHashCode();
			}
		}

		public List<Game> TakeByPopularity(List<Game> games, int limit)
		{
			return games.Select(x => x)
					.OrderByDescending(g => g.Popularity)
					.Take(limit)
					.ToList();
		}

		public List<GameCategoryData> SelectByCategory(List<Game> games)
		{
			var categories = new List<GameCategoryData>();
			var gameCompare = new GameComparer();

			foreach (GameCategory category in GameMgr.GetCategories())
			{
				var gameList = category.Games.Where(r => games.Contains(r.Game, gameCompare)).Select(r => r.Game).ToList<Game>();

				if (gameList.Count != 0)
					categories.Add(new GameCategoryData { Id = category.ID, Name = category.Name, Games = gameList });
			}

			return categories;
		}
	}
}
