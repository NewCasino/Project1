using System;

public abstract class GmExceptionBase : Exception
{
    public GmExceptionBase(string msg)
        : base(msg)
    {
    }

    public abstract string TryGetFriendlyErrorMsg();
}

