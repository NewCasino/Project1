using System;
using System.Collections.Generic;

namespace IGTIntegration
{
    public enum GameChannel
    {
        Internet,
        Terminal,
        Mobile,
    }

    public enum PresentationType
    {
        HTML,
        Flash,
    }

    public sealed class Configuration
    {
        public decimal DenomAmount { get; internal set; }
        public decimal MinBet { get; internal set; }
        public decimal MaxBet { get; internal set; }
    }
    
    [Serializable]
    public sealed class Game
    {
        public GameChannel GameChannel { get; set; }
        public PresentationType PresentationType { get; set; }
        public string SoftwareID { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public string Url { get; set; }
        public string [] LanguageCodes { get; set; }

        public Dictionary<string, List<IGTIntegration.Configuration> > Configurations { get; private set; }

        public Game(string gameChannel, string presentationType, Dictionary<string, List<IGTIntegration.Configuration> > configurations)
        {
            switch (gameChannel.ToUpperInvariant())
            {
                case "INT": this.GameChannel = IGTIntegration.GameChannel.Internet; break;
                case "TERM": this.GameChannel = IGTIntegration.GameChannel.Terminal; break;
                case "MOB": this.GameChannel = IGTIntegration.GameChannel.Mobile; break;
                default:
                    break;
            }

            switch (presentationType.ToUpperInvariant())
            {
                case "FLSH": this.PresentationType = IGTIntegration.PresentationType.Flash; break;
                case "HTML:": this.PresentationType = IGTIntegration.PresentationType.HTML; break;
                default:
                    break;
            }

            this.Configurations = configurations;
        }
    }
}
