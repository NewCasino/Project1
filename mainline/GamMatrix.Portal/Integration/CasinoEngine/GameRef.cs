using System;
using System.Collections.Generic;
using System.Linq;
using CM.Content;

namespace CasinoEngine
{
    public class GameRefComparer : IEqualityComparer<GameRef>
    {
        public bool Equals(GameRef x, GameRef y)
        {
            if (x == null)
                return y == null;
            return x.ID == y.ID;
        }

        public int GetHashCode(GameRef obj)
        {
            if (obj == null)
                return 0;
            return obj.ID.GetHashCode();
        }
    }

    /// <summary>
    /// Summary description for GameRef
    /// </summary>
    [Serializable]
    public sealed class GameRef : ICloneable
    {
        private const string NAME_ENTRY_PATH = @"/Metadata/_CasinoEngine/Category/{0}.Name";
        private const string DESC_ENTRY_PATH = @"/Metadata/_CasinoEngine/Category/{0}.Description";
        private const string SHORTNAME_ENTRY_PATH = @"/Metadata/_CasinoEngine/Category/{0}.ShortName";
        private const string THUMBNAIL_ENTRY_PATH = @"/Metadata/_CasinoEngine/Category/{0}.Thumbnail";
        private const string LOGO_ENTRY_PATH = @"/Metadata/_CasinoEngine/Category/{0}.Logo";
        private const string BACKGROUNDIMAGE_ENTRY_PATH = @"/Metadata/_CasinoEngine/Category/{0}.BackgroundImage";

        public GameRef()
        {
            this.Children = new List<GameRef>();
        }

        public object Clone()
        {
            return new GameRef()
            {
                IsGameGroup = this.IsGameGroup,
                ID = this.ID,
            };
        }

        /// <summary>
        /// Indicates if this is a game group
        /// </summary>
        public bool IsGameGroup { get; internal set; }

        /// <summary>
        /// Game : the id of the game
        /// Group : the id of the group
        /// </summary>
        public string ID { get; internal set; }


        /// <summary>
        /// the children games
        /// </summary>
        public List<GameRef> Children { get; internal set; }

        /// <summary>
        /// Get the game
        /// </summary>
        public Game Game 
        {
            get
            {
                Game game = null;
                Dictionary<string, Game> games = CasinoEngineClient.GetGames();
                games.TryGetValue( this.ID, out game);
                return game;
            }
        }

        /// <summary>
        /// Returns the localized name
        /// </summary>
        public string Name
        {
            get
            {
                if (this.IsGameGroup)
                {
                    return Metadata.Get( string.Format( NAME_ENTRY_PATH, this.ID) );
                }
                else
                {
                    if (this.Game != null)
                        return this.Game.Name;

                    return string.Empty;
                }
            }
        }


        /// <summary>
        /// Short name
        /// </summary>
        public string ShortName
        {
            get
            {
                if (this.IsGameGroup)
                {
                    return Metadata.Get( string.Format( SHORTNAME_ENTRY_PATH, this.ID) );
                }
                else
                {
                    if (this.Game != null)
                        return this.Game.ShortName;

                    return string.Empty;
                }
            }
        }

        /// <summary>
        /// Returns the localized name
        /// </summary>
        public string Description
        {
            get
            {
                if (this.IsGameGroup)
                {
                    return Metadata.Get(string.Format(DESC_ENTRY_PATH, this.ID));
                }
                else
                {
                    if (this.Game != null)
                        return this.Game.Description;

                    return string.Empty;
                }
            }
        }

        public long Popularity
        {
            get
            {
                if (this.IsGameGroup)
                {
                    if( this.Children != null )
                        return this.Children.Max(c => c.Popularity);
                    return 0L;
                }
                else
                {
                    if (this.Game != null)
                        return this.Game.Popularity;

                    return 0L;
                }
            }
        }


        public bool IsNewGame
        {
            get
            {
                if (this.IsGameGroup)
                {
                    if (this.Children != null)
                        return this.Children.Exists(c => c.IsNewGame);
                    return false;
                }
                else
                {
                    if (this.Game != null)
                        return this.Game.IsNewGame;

                    return false;
                }
            }
        }

        public GamMatrixAPI.VendorID VendorID
        {
            get
            {
                if (this.IsGameGroup)
                {
                    if (this.Children.Count > 0)
                    {
                        Game game = this.Children[0].Game;
                        if (game != null)
                            return game.VendorID;
                    }
                    return GamMatrixAPI.VendorID.Unknown;
                }
                else
                {
                    if (this.Game != null)
                        return this.Game.VendorID;

                    return GamMatrixAPI.VendorID.Unknown;
                }
            }
        }


        /// <summary>
        /// Thumbnail
        /// </summary>
        public string ThumbnailUrl
        {
            get
            {
                if (this.IsGameGroup)
                {
                    string url = ContentHelper.ParseFirstImageSrc( Metadata.Get( string.Format( THUMBNAIL_ENTRY_PATH, this.ID) ) );
                    if (url != null)
                        return url;

                    if (this.Children.Count > 0)
                    {
                        Game game = this.Children[0].Game;
                        if (game != null)
                            return game.ThumbnailUrl;
                    }
                    return string.Empty;
                }
                else
                {
                    if (this.Game != null)
                        return this.Game.ThumbnailUrl;

                    return string.Empty;
                }
            }
        }


        /// <summary>
        /// Logo
        /// </summary>
        public string Logo
        {
            get
            {
                if (this.IsGameGroup)
                {
                    string url = ContentHelper.ParseFirstImageSrc(Metadata.Get(string.Format(LOGO_ENTRY_PATH, this.ID)));
                    if (url != null)
                        return url;

                    if (this.Children.Count > 0)
                    {
                        Game game = this.Children[0].Game;
                        if (game != null)
                            return game.ThumbnailUrl;
                    }
                    return string.Empty;
                }
                else
                {
                    if (this.Game != null)
                        return this.Game.LogoUrl;

                    return string.Empty;
                }
            }
        }


        /// <summary>
        /// BackgroundImageUrl
        /// </summary>
        public string BackgroundImageUrl
        {
            get
            {
                if (this.IsGameGroup)
                {
                    string url = ContentHelper.ParseFirstImageSrc(Metadata.Get(string.Format(BACKGROUNDIMAGE_ENTRY_PATH, this.ID)));
                    if (url != null)
                        return url;

                    if (this.Children.Count > 0)
                    {
                        Game game = this.Children[0].Game;
                        if (game != null)
                            return game.ThumbnailUrl;
                    }
                    return string.Empty;
                }
                else
                {
                    if (this.Game != null)
                        return this.Game.BackgroundImageUrl;

                    return string.Empty;
                }
            }
        }
    }
}