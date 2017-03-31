using System;
using System.Collections.Generic;
using System.Globalization;
using CM.Content;

namespace CasinoEngine
{
    /// <summary>
    /// Summary description for GameCategory
    /// </summary>
    [Serializable]
    public sealed class GameCategory : ICloneable
    {
        public const string TRANSLATION_PATH = @"/Metadata/_CasinoEngine/Category/{0}";
        public const string NAME_ENTRY_PATH = @"/Metadata/_CasinoEngine/Category/{0}.Name";
        public const string FRIENDLY_ID_ENTRY_PATH = @"/Metadata/_CasinoEngine/Category/{0}.FriendlyID";

        public const string TABLEGAMES = @"TABLEGAMES";
        public const string VIDEOPOKERS = @"VIDEOPOKERS";
        public const string CLASSICSLOTS = @"CLASSICSLOTS";
        public const string VIDEOSLOTS = @"VIDEOSLOTS";
        public const string LOTTERY = @"LOTTERY";
        public const string MINIGAMES = @"MINIGAMES";
        public const string JACKPOTGAMES = @"JACKPOTGAMES";

        public List<GameRef> Games { get; private set; }

        /// <summary>
        /// The Guid of this category
        /// </summary>
        public string ID { get; internal set; }

        public string FriendlyID
        {
            get
            {
                string path = string.Format( CultureInfo.InvariantCulture, FRIENDLY_ID_ENTRY_PATH, this.ID);
                string friendlyID = Metadata.Get(path, "en");
                if (string.IsNullOrEmpty(friendlyID))
                    return this.ID;
                return friendlyID;
            }
        }


        /// <summary>
        /// The localized name
        /// </summary>
        public string Name
        {
            get
            {
                string path = string.Format(NAME_ENTRY_PATH, this.ID);
                return Metadata.Get(path);
            }
        }

        public GameCategory()
        {
            this.Games = new List<GameRef>();
        }

        public object Clone()
        {
            return new GameCategory()
            {
                ID = this.ID,
            };
        }
    }
}