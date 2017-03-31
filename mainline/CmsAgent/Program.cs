using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceProcess;
using System.Text;

using CmsAgent.FileManager;
namespace CmsAgent
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static void Main()
        {
            //var clients = FileManagerBase.GetAllManagers(domainID: 1096).Where(f => f.Config.Name == "CasinoCruise");

            //foreach (var c in clients)
            //{
            //    var list = c.GetList("_js");

            //    list.ContinueWith( t => {
            //        Console.WriteLine(list.Result.Count.ToString());
            //    });

            //}
#if !DEBUG
                        ServiceBase[] ServicesToRun;
                        ServicesToRun = new ServiceBase[]
                        {
                            new MainSvc()
                        };
                        ServiceBase.Run(ServicesToRun);
#else
            (new MainSvc()).TestRun();
#endif
        }
    }
}
