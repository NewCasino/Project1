using System;

namespace GamMatrix.Infrastructure
{
    public abstract class CacheEntryBase<T> where T : class
    {
        public DateTime Ins { get; private set; }
        public T Value { get; private set; }
        public abstract int ExpirationSeconds { get; }

        public CacheEntryBase(T t)
        {
            Ins = DateTime.Now;
            this.Value = t;
        }

        public bool IsExpried
        {
            get
            {
                return (DateTime.Now - Ins).TotalSeconds > ExpirationSeconds;
            }
        }
    }
}
