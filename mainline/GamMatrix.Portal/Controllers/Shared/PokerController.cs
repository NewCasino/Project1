using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class PokerController : AsyncControllerEx
    {
        [HttpGet]
        public ActionResult Index()
        {
            return View("Index");
        }
        
        /*
        [HttpGet]
        public void EverleafPokerFlashAsync()
        {
            AsyncManager.OutstandingOperations.Increment();
            EverleafPokerProxy.GenerateSessionIDAsync(OnEverleafPokerSessionIDGenerated);
        }

        private void OnEverleafPokerSessionIDGenerated(string pokerSessionID)
        {
            AsyncManager.Parameters["pokerSessionID"] = pokerSessionID;
            AsyncManager.OutstandingOperations.Decrement();
        }

        public ActionResult EverleafPokerFlashCompleted(string pokerSessionID)
        {
            // http://playadjara.everleafgaming.com/flashclient/index.php?id=xxxxxxxx
            string url = string.Format(Settings.EverleafPoker_FlashClientUrl, HttpUtility.UrlEncode(pokerSessionID));
            return this.Redirect(url);
        }

        public ActionResult EverleafPokerTopWinners()
        {
            return View("EverleafPokerTopWinners");
        }

        public ActionResult EverleafPokerTopWinnerList(int? maxRecords, bool isHistory = false, string strongRanges = null)
        {
            List<Winner> winners = EverleafPokerProxy.GetTopWinners(isHistory);
            if (maxRecords.HasValue)
            {
                this.ViewData["MaxRecords"] = maxRecords.Value;
                this.ViewData["StrongRanges"] = strongRanges;

                if (!string.IsNullOrEmpty(Settings.EverleafPoker_TopWinners_ExcludedUsers))
                {
                    string[] excludedUsers = Settings.EverleafPoker_TopWinners_ExcludedUsers.Split(',');
                    foreach (string excludedUser in excludedUsers)
                    {
                        if (winners.Exists(p => p.Nickname.Equals(excludedUser, StringComparison.OrdinalIgnoreCase)))
                            winners.RemoveAll(p => p.Nickname.Equals(excludedUser, StringComparison.OrdinalIgnoreCase));
                    }
                }
                winners = winners.Take(maxRecords.Value).ToList();
            }
            
            return View("EverleafPokerTopWinnerList", winners);
        }
        */

    }
}
