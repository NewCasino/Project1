using System;
using CM.Content;
using GamMatrixAPI;

namespace GmCore
{
    /// <summary>
    /// Summary description for GmException
    /// </summary>
    public sealed class GmException : GmExceptionBase
    {
        public ReplyResponse ReplyResponse  { get; private set; }

        public GmException(ReplyResponse replyResponse)
            : base( string.Format( "{0} - {1}", replyResponse.ErrorCode, replyResponse.ErrorSysMessage ))
        {
            this.ReplyResponse = replyResponse;
        }


        /// <summary>
        /// Try to get the friendly error message
        /// </summary>
        /// <param name="ex"></param>
        /// <returns></returns>
        public static string TryGetFriendlyErrorMsg(Exception ex)
        {
            var gex = ex as GmException ?? ex.InnerException as GmException;
            if (gex == null)
            {
                return ex.Message;
            }

            string msg = gex.ReplyResponse.ErrorUserMessage;
            try
            {
                string path = string.Format("/Metadata/GmCoreErrorCodes/{0}.UserMessage", gex.ReplyResponse.ErrorCode.Replace('-', '_'));
                var userMessage = Metadata.Get(path);

                if (!string.IsNullOrWhiteSpace(userMessage))
                {
                    msg = userMessage;
                    msg = string.Format(userMessage, gex.ReplyResponse.ErrorRawUserMessageArgs.ToArray());
                }
            }
            catch
            {
                // ignored
            }

            return string.Format("{0} [{1}]", msg, gex.ReplyResponse.ErrorCode);
        }

        public static string TryGetFriendlyErrorMsg(string errorCode)
        {
            string path = string.Format("/Metadata/GmCoreErrorCodes/{0}.UserMessage", errorCode.Replace('-', '_'));

            var message = Metadata.Get(path);

            return string.IsNullOrWhiteSpace(message)? string.Empty : string.Format("{0} [{1}]", message, errorCode);
        }

        public override string TryGetFriendlyErrorMsg()
        {
            return TryGetFriendlyErrorMsg(this);
        }
    }
}