using System;
using System.Threading.Tasks.Dataflow;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using System.Net.Http;
using System.Web.Script.Serialization;
using CmsAgent.FileManager;
using System.Web;

namespace CmsAgent
{


    public class FileManagerController : ApiController
    {
        [AcceptVerbs("POST")]
        public async Task<HttpResponseMessage> Upload(string path, string filename, int length, string distinctName = null,int domainID = 0,bool debug = false)
        {
            if (debug)
            {
                Logger.Get().AppendFormat(" Upload distinctName:{0}", distinctName != null ? distinctName : "none");
                Logger.Get().AppendFormat(" Upload domainID:{0}", domainID);
            }
            try
            {
                Logger.Get().AppendFormat(" Upload domainID:{0}", domainID);
                this.OnlyAllowInternalAccess();

                byte[] buffer = await Request.Content.ReadAsByteArrayAsync();
                if (buffer == null)
                    buffer = new byte[0];
                if (buffer.Length != length)
                    throw new ArgumentException();

                List<FileManagerBase> clients = FileManagerBase.GetAllManagers(distinctName, domainID);

                var action = new ActionBlock<FileManagerBase>(async client =>
                {
                    await client.Upload(path, filename, buffer);
                }, new ExecutionDataflowBlockOptions()
                {
                    MaxDegreeOfParallelism = clients.Count,
                });
                clients.ForEach((c) => action.Post(c));

                action.Complete();
                await action.Completion;

                return new HttpResponseMessage()
                {
                    Content = new StringContent("{ \"success\" : true }", Encoding.UTF8, "text/javascript")
                };
            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
                string json = string.Format("{{ \"success\" : false, \"error\" : \"{0}\" }}", HttpUtility.JavaScriptStringEncode(ex.Message));
                return new HttpResponseMessage()
                {
                    Content = new StringContent(json, Encoding.UTF8, "text/javascript")
                };
            }
        }

     
        [AcceptVerbs("GET")]
        public async Task<HttpResponseMessage> PrepareUpload(string path, string filename, int length,string distinctName = null,int domainID = 0)
        {
            try
            {
                Logger.Get().AppendFormat(" PrepareUpload domainID:{0}", domainID);
                Logger.Get().AppendFormat("PrepareUpload url:{0}", Request.RequestUri.ToString());
                this.OnlyAllowInternalAccess();

                List<FileManagerBase> clients = FileManagerBase.GetAllManagers(distinctName,domainID);

                var action = new ActionBlock<FileManagerBase>(async client =>
                {
                    await client.PrepareUpload(path, filename, length);
                }, new ExecutionDataflowBlockOptions()
                {
                    MaxDegreeOfParallelism = clients.Count,
                });
                clients.ForEach((c) => action.Post(c));

                action.Complete();
                await action.Completion;

                return new HttpResponseMessage()
                {
                    Content = new StringContent("{ \"success\" : true }", Encoding.UTF8, "text/javascript")
                };
            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
                string json = string.Format("{{ \"success\" : false, \"error\" : \"{0}\" }}", HttpUtility.JavaScriptStringEncode(ex.Message));
                return new HttpResponseMessage()
                {
                    Content = new StringContent(json, Encoding.UTF8, "text/javascript")
                };
            }
        }

        [AcceptVerbs("POST")]
        public async Task<HttpResponseMessage> PartialUpload(string path, string filename, int offset, int length, string distinctName = null,int domainID = 0,bool debug =false)
        {
            if (debug)
            {
                Logger.Get().AppendFormat(" PartialUpload domainID:{0}", domainID);
            }
            try
            {
                Logger.Get().AppendFormat(" PartialUpload domainID:{0}", domainID);
                Logger.Get().AppendFormat(" PartialUpload url:{0}", Request.RequestUri.ToString());
                this.OnlyAllowInternalAccess();

                byte[] buffer = await Request.Content.ReadAsByteArrayAsync();
                if (buffer == null)
                    buffer = new byte[0];
                if (buffer.Length != length)
                    throw new ArgumentException();

                List<FileManagerBase> clients = FileManagerBase.GetAllManagers(distinctName, domainID);

                var action = new ActionBlock<FileManagerBase>(async client =>
                {
                    await client.PartialUpload(path, filename, offset, buffer);
                }, new ExecutionDataflowBlockOptions()
                {
                    MaxDegreeOfParallelism = clients.Count,
                });
                clients.ForEach((c) => action.Post(c));

                action.Complete();
                await action.Completion;

                return new HttpResponseMessage()
                {
                    Content = new StringContent("{ \"success\" : true }", Encoding.UTF8, "text/javascript")
                };
            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
                string json = string.Format("{{ \"success\" : false, \"error\" : \"{0}\" }}", HttpUtility.JavaScriptStringEncode(ex.Message));
                return new HttpResponseMessage()
                {
                    Content = new StringContent(json, Encoding.UTF8, "text/javascript")
                };
            }
        }


        [AcceptVerbs("GET")]
        public async Task<HttpResponseMessage> List(string path, string distinctName = null,int domainID = 0,bool debug =false)
        {
            if (debug)
            {
                Logger.Get().AppendFormat("List distinctName:{0}", distinctName != null ? distinctName : "none");
            }
            try
            {
                Logger.Get().AppendFormat(" List domainID:{0}", domainID);
                //this.OnlyAllowInternalAccess();

                FileManagerBase client = FileManagerBase.GetPrimaryManager(distinctName, domainID);
                var list = await client.GetList(path);

                var array = list.Select(i => new { @isFolder = i.Item1, @filename = i.Item2 })
                    .OrderBy(i => i.isFolder)
                    .OrderBy(i => i.filename)
                    .ToArray();

                JavaScriptSerializer jss = new JavaScriptSerializer();
                string json = string.Format("{{ \"success\" : true, \"list\" : {0} }}"
                    , jss.Serialize(array)
                    );

                return new HttpResponseMessage()
                {
                    Content = new StringContent(json, Encoding.UTF8, "text/javascript")
                };
            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
                string json = string.Format("{{ \"success\" : false, \"error\" : \"{0}\" }}", HttpUtility.JavaScriptStringEncode(ex.Message));
                return new HttpResponseMessage()
                {
                    Content = new StringContent(json, Encoding.UTF8, "text/javascript")
                };
            }
        }


        [AcceptVerbs("GET")]
        public async Task<HttpResponseMessage> Delete(string path, string distinctName = null,int domainID = 0)
        {
            try
            {
                Logger.Get().AppendFormat(" Delete domainID:{0}", domainID);
                this.OnlyAllowInternalAccess();

                List<FileManagerBase> clients = FileManagerBase.GetAllManagers(distinctName, domainID);

                var action = new ActionBlock<FileManagerBase>(async client =>
                {
                    await client.Delete(path);
                }, new ExecutionDataflowBlockOptions()
                {
                    MaxDegreeOfParallelism = clients.Count,
                });
                clients.ForEach((c) => action.Post(c));

                action.Complete();
                await action.Completion;

                return new HttpResponseMessage()
                {
                    Content = new StringContent("{ \"success\" : true }", Encoding.UTF8, "text/javascript")
                };
            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
                string json = string.Format("{{ \"success\" : false, \"error\" : \"{0}\" }}", HttpUtility.JavaScriptStringEncode(ex.Message));
                return new HttpResponseMessage()
                {
                    Content = new StringContent(json, Encoding.UTF8, "text/javascript")
                };
            }
        }

        [AcceptVerbs("GET")]
        public async Task<HttpResponseMessage> CreateFolder(string path, string distinctName = null,int domainID = 0)
        {
            try
            {
                Logger.Get().AppendFormat(" CreateFolder domainID:{0}", domainID);
                this.OnlyAllowInternalAccess();

                List<FileManagerBase> clients = FileManagerBase.GetAllManagers(distinctName, domainID);

                var action = new ActionBlock<FileManagerBase>(async client =>
                {
                    await client.CreateFolder(path);
                }, new ExecutionDataflowBlockOptions()
                {
                    MaxDegreeOfParallelism = clients.Count,
                });
                clients.ForEach((c) => action.Post(c));

                action.Complete();
                await action.Completion;

                return new HttpResponseMessage()
                {
                    Content = new StringContent("{ \"success\" : true }", Encoding.UTF8, "text/javascript")
                };
            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
                string json = string.Format("{{ \"success\" : false, \"error\" : \"{0}\" }}", HttpUtility.JavaScriptStringEncode(ex.Message));
                return new HttpResponseMessage()
                {
                    Content = new StringContent(json, Encoding.UTF8, "text/javascript")
                };
            }
        }

        #region internal methods
        protected static string GetRealUserAddress(HttpRequestMessage request)
        {
            if (request != null)
            {
                string ip = null;

                IEnumerable<string> values;
                if (request.Headers.TryGetValues("X-Real-IP", out values))
                {
                    ip = values.FirstOrDefault();
                }

                if (string.IsNullOrWhiteSpace(ip))
                {
                    if (request.Headers.TryGetValues("X-Forwarded-For", out values))
                    {
                        ip = values.FirstOrDefault();
                    }
                }

                if (string.IsNullOrWhiteSpace(ip))
                {
                    if (request.Properties.ContainsKey("MS_HttpContext"))
                    {
                        dynamic ctx = request.Properties["MS_HttpContext"];
                        if (ctx != null)
                        {
                            return ctx.Request.UserHostAddress;
                        }
                    }

                    if (request.Properties.ContainsKey("System.ServiceModel.Channels.RemoteEndpointMessageProperty"))
                    {
                        dynamic remoteEndpoint = request.Properties["System.ServiceModel.Channels.RemoteEndpointMessageProperty"];
                        if (remoteEndpoint != null)
                        {
                            return remoteEndpoint.Address;
                        }
                    }
                }
                if (!string.IsNullOrEmpty(ip))
                {
                    return ip.Split(',')[0].Trim();
                }
            }
            return string.Empty;
        }

        protected void OnlyAllowInternalAccess()
        {
            string ip = GetRealUserAddress(Request);
            if (ip == "127.0.0.1" ||
                ip == "::1" ||
                ip == "124.233.3.10" ||
                ip == "85.9.28.130" ||
                ip.StartsWith("10.0.") ||
                ip.StartsWith("109.205.9") ||
                ip.StartsWith("78.133.") ||
                ip.StartsWith("192.168."))
            {
                return;
            }
            throw new UnauthorizedAccessException();
        }
        #endregion
    }
}
