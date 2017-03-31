using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CasinoEngine
{
    class CacheKeyFormat
    {
        internal const string ContentProviders = "casino.content-providers.{0}";
        internal const string GamePopularities = "casino.game-popularities.{0}";
        internal const string Games = "casino.games.{0}";
        internal const string Jackpots = "casino.jackpots.{0}";
        internal const string DesktopRecentWinners = "casino.recent-winners.desktop.{0}";
        internal const string MobileRecentWinners = "casino.recent-winners.mobile.{0}";
        internal const string Tables = "casino.tables.{0}";
        internal const string DesktopTopWinners = "casino.top-winners.desktop.{0}";
        internal const string MobileTopWinners = "casino.top-winners.mobile.{0}";
        internal const string Vendors = "casino.vendors.{0}";
    }
}
