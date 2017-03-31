//using System;
//using System.Collections.Generic;
//using System.Linq;
//using System.Text;
//using System.Diagnostics;
//using System.Web;

//namespace CE.Utils
//{
//    public static class ExceptionExtension
//    {
//        public static void AppendToErrorLog(this Exception ex)
//        {
//            if (ex == null)
//                return;

//            StringBuilder text = new StringBuilder();
//            while (ex != null)
//            {
//                text.AppendLine("-----------------------------------------------");
//                text.AppendFormat("{0}\n\n", ex.Message);
//                text.AppendFormat("{0}\n", ex.StackTrace);

//                ex = ex.InnerException;
//            }

//            text.AppendLine("=====================================================");
//            try
//            {
//                if (HttpContext.Current != null)
//                {
//                    text.AppendFormat("URL: {0}\n", HttpContext.Current.Request.Url.ToString());
//                    foreach (string key in HttpContext.Current.Request.Form.Keys)
//                    {
//                        text.AppendFormat("{0}= {1}\n", key, HttpContext.Current.Request.Form[key]);
//                    }
//                }
//            }
//            catch
//            {
//            }

//            // eventcreate /ID 662 /L APPLICATION /T ERROR /SO CasinoEngine  /D "CasinoEngine"
//            EventLog.WriteEntry("CasinoEngine", text.ToString(), EventLogEntryType.Error);
//        }
//    }
//}
