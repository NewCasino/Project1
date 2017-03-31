using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Caching;
using System.Web.Mvc;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrix.Infrastructure;
using GamMatrixAPI;
using GmCore;

/// <summary>
/// Summary description for MessagesCountrol
/// </summary>
namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "")]
    public class MessagesController : AsyncControllerEx
    {

        public static bool status = false;
        public static string errorMsg = "";
        public static long counts = 0;
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            return View("Index");
        }

        [HttpGet]
        public ActionResult MessageForm()
        {
            return View("MessageForm");
        }

        [HttpGet]
        public ActionResult MessagesCount()
        {
            return View("MessagesCount");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public void AddMessageAsync(string body, string subject)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();
                body = body.SafeHtmlEncode();
                subject = subject.SafeHtmlEncode();
                if (string.IsNullOrEmpty(subject))
                {
                    throw new ArgumentNullException("subject");
                }
                if (string.IsNullOrEmpty(body)) body = subject;
                AddUserMessageRequest addUserMessageRequest = new AddUserMessageRequest()
                {
                    Body = body,
                    Subject = subject,
                    UserID = CustomProfile.Current.UserID,
                    Type = UserMessageType.FromUser,
                };
                GamMatrixClient.SingleRequestAsync(addUserMessageRequest, OnAddUserMessageRequest);
                AsyncManager.OutstandingOperations.Increment();
            }
            catch (GmException ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }

        public void OnAddUserMessageRequest(AsyncResult reply)
        {
            try
            {
                AsyncManager.Parameters["getUserMessagesRequest"] = reply.EndSingleRequest().Get<AddUserMessageRequest>();
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
            finally
            {
                AsyncManager.OutstandingOperations.Decrement();
            }
        }
        public JsonResult AddMessageCompleted(AddUserMessageRequest getUserMessagesRequest
            , Exception exception
            )
        {

            try
            {
                if (exception != null)
                    throw exception;
                return this.Json(new { @success = true, @error = "", @count = 0 }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message, @count = 0 }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        public void GetMessagesUnReadCountAsync()
        {
            try
            {
                string cacheKey = string.Format("MessagesUnReadCount_{0}", CustomProfile.Current.SessionID);
                AsyncManager.Parameters["cacheKey"] = cacheKey;
                MessagesCountCacheEntry cache = HttpRuntime.Cache[cacheKey] as MessagesCountCacheEntry;
                long count;
                if (cache != null && !cache.IsExpried && cache.Value != null && long.TryParse(cache.Value.PagedData.TotalRecords.ToString()
                    , NumberStyles.Integer
                    , CultureInfo.InvariantCulture
                    , out count
                    ))
                {
                    AsyncManager.Parameters["getUserMessagesRequest"] = cache.Value;
                    AsyncManager.Parameters["counts"] = count;
                }
                else
                {
                    GetUserMessagesRequest getUserMessagesRequest = new GetUserMessagesRequest()
                    {
                        SelectionCriteria = new UserMessageSelectParams
                        {
                            ByStatus = true,
                            ByUserID = true,
                            ByType = true,
                            ParamUserID = CustomProfile.Current.UserID,
                            ParamStatus = UserMessageStatus.UnRead,
                            ParamType = UserMessageType.ToUser,
                        },
                        PagedData = new PagedDataOfUserMessageInfoRec
                        {
                            PageNumber = 0,
                            PageSize = long.MaxValue
                        },
                    };
                    GamMatrixClient.SingleRequestAsync(getUserMessagesRequest, OnGetMessagesUnReadCountCompleted);
                    AsyncManager.OutstandingOperations.Increment();
                }
            }
            catch (GmException ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }

        }

        public void OnGetMessagesUnReadCountCompleted(AsyncResult reply)
        {
            GetUserMessagesRequest request = new GetUserMessagesRequest();
            try
            {
                request = reply.EndSingleRequest().Get<GetUserMessagesRequest>();
                AsyncManager.Parameters["getUserMessagesRequest"] = request;
                AsyncManager.Parameters["counts"] = request.PagedData.TotalRecords;
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
            finally
            {
                AsyncManager.OutstandingOperations.Decrement();
            }
        }

        public JsonResult GetMessagesUnReadCountCompleted(
            GetUserMessagesRequest getUserMessagesRequest,
            Exception exception,
            long counts,
            string cacheKey)
        {
            try
            {
                if (exception != null)
                    throw exception;

                if (HttpRuntime.Cache[cacheKey] == null && getUserMessagesRequest != null)
                {
                    HttpRuntime.Cache.Insert(cacheKey
                          , new MessagesCountCacheEntry(getUserMessagesRequest)
                          , null
                          , Cache.NoAbsoluteExpiration
                          , TimeSpan.FromSeconds(30)
                          );
                }
                return this.Json(new { @success = true, @error = "", @count = counts }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message, @count = 0 }, JsonRequestBehavior.AllowGet);
            }
        }

        private sealed class MessagesCountCacheEntry : CacheEntryBase<GetUserMessagesRequest>
        {
            public override int ExpirationSeconds { get { return 30; } }
            public MessagesCountCacheEntry(GetUserMessagesRequest request)
                : base(request)
            {
            }
        }

        [HttpGet]
        public void MessageDetailAsync(long messageId)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                AsyncManager.Parameters["messageId"] = messageId;

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GetUserMessagesRequest prepareMessagesRequest = new GetUserMessagesRequest()
                    {
                        SelectionCriteria = new UserMessageSelectParams
                        {
                            ByStatus = false,
                            ByUserID = true,
                            ByType = false,
                            ParamUserID = CustomProfile.Current.UserID,
                            ParamStatus = UserMessageStatus.UnRead,
                            ParamType = UserMessageType.ToUser,
                        },
                        PagedData = new PagedDataOfUserMessageInfoRec
                        {
                            PageNumber = 0,
                            PageSize = long.MaxValue,
                        },
                    };
                    GamMatrixClient.SingleRequestAsync<GetUserMessagesRequest>(prepareMessagesRequest, OnMessageDetailCompleted);
                    AsyncManager.OutstandingOperations.Increment();
                }
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }
        public void OnMessageDetailCompleted(AsyncResult reply)
        {
            try
            {
                AsyncManager.Parameters["getUserMessagesRequest"] = reply.EndSingleRequest().Get<GetUserMessagesRequest>();
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
            finally
            {
                AsyncManager.OutstandingOperations.Decrement();
            }
        }
        public ActionResult MessageDetailCompleted(GetUserMessagesRequest getUserMessagesRequest, Exception exception, long messageId)
        {
            try
            {
                if (exception != null)
                    throw exception;
                List<UserMessageInfoRec> UserMessageList = getUserMessagesRequest.PagedData.Records;
                List<UserMessageInfoRec> ic = UserMessageList.Where(p => p.ID == messageId).ToList();

                if (ic != null && ic[0].Type == UserMessageType.ToUser)
                {
                    UpdateViewStatusAsync(messageId);
                }

                return View("MessageDetail", ic);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return View("MessageDetail", null);
            }

        }
        public void UpdateViewStatusAsync(long messageId)
        {
            try
            {
                UpdateUserMessageStatusRequest updateUserMessageStatusRequest = new UpdateUserMessageStatusRequest()
                {
                    UserID = CustomProfile.Current.UserID,
                    Status = UserMessageStatus.Read,
                    UserMessageID = messageId,
                };
                GamMatrixClient.SingleRequestAsync(updateUserMessageStatusRequest, OnUpdateViewStatusCompleted);
                AsyncManager.OutstandingOperations.Increment();
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }
        public void OnUpdateViewStatusCompleted(AsyncResult reply)
        {
            try
            {
                AsyncManager.Parameters["updateUserMessageStatusRequest"] = reply.EndSingleRequest().Get<UpdateUserMessageStatusRequest>();
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
            finally
            {
                AsyncManager.OutstandingOperations.Decrement();
            }
        }
        public void UpdateViewStatusCompleted(UpdateUserMessageStatusRequest updateUserMessageStatusRequest, Exception exception, long messageId)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();
                if (exception != null)
                    throw exception;
                return;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return;
            }
        }



        [HttpGet]
        public void MessagesListAsync(long pageNumber = 0, long pageSize = 20)
        {
            try
            {
                GetUserMessagesRequest getUserMessagesRequest = new GetUserMessagesRequest();
                string cacheKey = string.Format("MessagesList_{0}_{1}_{2}",
                    CustomProfile.Current.SessionID,
                    pageNumber,
                    pageSize
                    );
                AsyncManager.Parameters["cacheKey"] = cacheKey;
                MessagesCountCacheEntry cache = HttpRuntime.Cache[cacheKey] as MessagesCountCacheEntry;
                if (cache != null && !cache.IsExpried && cache.Value != null)
                {
                    AsyncManager.Parameters["getUserMessagesRequest"] = cache.Value;
                    AsyncManager.Parameters["isNew"] = false;
                }
                else
                {
                    if (!CustomProfile.Current.IsAuthenticated)
                        throw new UnauthorizedAccessException();
                    else
                    {
                        getUserMessagesRequest = new GetUserMessagesRequest()
                        {
                            SelectionCriteria = new UserMessageSelectParams
                            {
                                ByStatus = false,
                                ByUserID = true,
                                ByType = false,
                                ParamUserID = CustomProfile.Current.UserID,
                                ParamStatus = UserMessageStatus.UnRead,
                                ParamType = UserMessageType.ToUser,
                            },
                            PagedData = new PagedDataOfUserMessageInfoRec
                            {
                                PageNumber = pageNumber,
                                PageSize = pageSize,
                            },
                        };
                        GamMatrixClient.SingleRequestAsync<GetUserMessagesRequest>(getUserMessagesRequest, OnGetUserMessagesRequestCompeleted);
                        AsyncManager.OutstandingOperations.Increment();
                        AsyncManager.Parameters["isNew"] = true;
                    }
                }
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }
        public void OnGetUserMessagesRequestCompeleted(AsyncResult reply)
        {
            GetUserMessagesRequest getUserMessagesRequest = new GetUserMessagesRequest();
            try
            {
                getUserMessagesRequest = reply.EndSingleRequest().Get<GetUserMessagesRequest>();
                AsyncManager.Parameters["getUserMessagesRequest"] = getUserMessagesRequest;
                PagedDataOfUserMessageInfoRec UserMessageList = getUserMessagesRequest.PagedData;
                AsyncManager.Parameters["UserMessageList"] = UserMessageList;
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
            finally
            {
                AsyncManager.OutstandingOperations.Decrement();
            }
        }
        public ActionResult MessagesListCompleted(GetUserMessagesRequest getUserMessagesRequest, Exception exception, string cacheKey, bool isNew)
        {
            try
            {
                if (exception != null)
                    throw exception;
                if (isNew && getUserMessagesRequest != null)
                {
                    HttpRuntime.Cache.Insert(cacheKey
                        , new MessagesCountCacheEntry(getUserMessagesRequest)
                          , null
                          , Cache.NoAbsoluteExpiration
                          , TimeSpan.FromSeconds(30)
                        );
                }
                return View("MessagesList", getUserMessagesRequest.PagedData);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return View("MessagesList", null);
            }
        }
    }
}