using System;
using GamMatrixAPI;

/// <summary>
/// Summary description for GmException
/// </summary>
public sealed class GmException : Exception
{
    public ReplyResponse ReplyResponse  { get; private set; }

    public GmException(ReplyResponse replyResponse)
        : base( string.Format( "{0} - {1}", replyResponse.ErrorCode, replyResponse.ErrorSysMessage ))
    {
        this.ReplyResponse = replyResponse;
    }
}
