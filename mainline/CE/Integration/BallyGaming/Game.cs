using System;
using System.Collections.Generic;

namespace BallyIntegration
{
    public sealed class Configuration
    {
        public decimal DenomAmount { get; internal set; }
        public decimal MinBet { get; internal set; }
        public decimal MaxBet { get; internal set; }
    }

    [Serializable]
    public sealed class GamesWrapper
    {
        public Games Games { get; set; }
    }

    [Serializable]
    public sealed class Games
    {
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public int PageCount { get; set; }
        public int TotalCount { get; set; }
        public List<Game> Items { get; set; }
    }

    [Serializable]
    public sealed class Game
    {
        /// <summary>
        /// The unique identifier of the configured game.
        /// </summary>
        public string SoftwareID { get; set; }

        /// <summary>
        /// The uniform resource identifier for the configured game.
        /// </summary>
        public string URI { get; set; }

        /// <summary>
        /// The theme of the game identifies the name of the game and the presentation. It does not include the pay table or denomination information.
        /// </summary>
        public string Theme { get; set; }

        /// <summary>
        /// The URL that the GP game console uses to launch the game.
        /// </summary>
        public string LaunchUrl { get; set; }

        /// <summary>
        /// A Boolean flag indicating whether or not the game is available for play.
        /// </summary>
        public bool Active { get; set; }

        /// <summary>
        /// A list of currency codes supported by the game. Each currency code is a three-character ISO 4217 code.
        /// </summary>
        public List<string> CurrencyCode { get; set; }
    }
}
