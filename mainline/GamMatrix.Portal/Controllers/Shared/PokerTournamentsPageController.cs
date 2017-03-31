using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using CM.Sites;
using CM.Web;
using Poker;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ValidateInput(false)]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class PokerTournamentsPageController : AsyncControllerEx
    {
        
        [HttpGet]
        public ActionResult Index()
        {            
            return View("Index");
        }


        [HttpGet]
        public ActionResult MergePoker()
        {
            return View("MergePoker");
        }

        [HttpGet]
        public ActionResult MergePokerTournamentList()
        {
            List<Tournament> tournaments = MergePokerProxy.GetTournaments();
            return View("MergePokerTournamentList", tournaments);
        }


        [HttpGet]
        public ActionResult ENETPoker()
        {
            return View("ENETPoker");
        }

        #region ENETPokerTournamentList
        [HttpGet]
        public void ENETPokerTournamentListAsync()
        {
            ENETPokerProxy.GetTournamentsAsync(OnGetENETTournamentList);
            AsyncManager.OutstandingOperations.Increment();
        }

        private void OnGetENETTournamentList(List<Tournament> tournaments)
        {
            AsyncManager.Parameters["tournaments"] = tournaments;
            AsyncManager.OutstandingOperations.Decrement();
        }

        public ActionResult ENETPokerTournamentListCompleted(List<Tournament> tournaments)
        {
            return View("ENETPokerTournamentList", tournaments);
        }
        #endregion

        [HttpGet]
        public ActionResult CakePoker()
        {
            return View("CakePoker");
        }

        [HttpGet]
        public ActionResult CakePokerTournamentList()
        {
            List<Tournament> tournaments = CakePokerProxy.GetTournaments().OrderBy( t => t.StartTime ).ToList();
            return View("CakePokerTournamentList", tournaments);
        }

        [HttpGet]
        public ActionResult EverLeafPoker()
        {
            return View("EverLeafPoker");
        }

        [HttpGet]
        public ActionResult EverLeafPokerTournamentList(int count = 0, string matchType = "", bool onlyShowUnstart = true)
        {
            List<Tournament> tournaments = null;

            //get tournaments
            if (string.IsNullOrEmpty(matchType))
                tournaments = EverleafPokerProxy.GetTournaments(onlyShowUnstart);
            else
            {
                EverleafPokerProxy.TournamentMatchType tournamentMatchType;
                if (Enum.TryParse<EverleafPokerProxy.TournamentMatchType>(matchType, out tournamentMatchType))
                {
                    tournaments = EverleafPokerProxy.GetTournaments(tournamentMatchType, onlyShowUnstart);
                }
            }

            if (tournaments != null && tournaments.Count>0)
            {
                //filter tournaments
                if (tournaments.Exists(p => p.Status == TournamentStatus.ANNOUNCED || p.Status == TournamentStatus.REGISTERING || p.Status == TournamentStatus.LATEREGISTRATION))
                {
                    tournaments = tournaments.Where(p => p.Status == TournamentStatus.ANNOUNCED || p.Status == TournamentStatus.REGISTERING || p.Status == TournamentStatus.LATEREGISTRATION).OrderBy(p=>p.StartTime).ToList();

                    if (onlyShowUnstart && tournaments.Exists(p => p.StartTime > DateTime.Now.ToUniversalTime()))
                    {
                        tournaments = tournaments.Where(p => p.StartTime > DateTime.Now.ToUniversalTime()).ToList();
                    }
                }
                else
                {
                    tournaments = new List<Tournament>();
                }

                //take specified number tournaments
                if (count > 0 && tournaments.Count>count)
                {
                    tournaments = tournaments.Take(count).ToList();
                }
            }
            

            return View("EverLeafPokerTournamentList", tournaments.OrderBy(p=>p.StartTime).ToList());
        }
    }
}
