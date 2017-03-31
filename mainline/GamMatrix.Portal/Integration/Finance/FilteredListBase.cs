using System;
using System.Collections.Generic;

namespace Finance
{
    [Serializable]
    /// <summary>
    /// Summary description for FilteredListBase
    /// </summary>
    public abstract class FilteredListBase<T>
    {
        public FilteredListBase()
        {
            this.Type = FilterType.Exclude;
        }

        public enum FilterType
        {
            Include,
            Exclude,
        }

        public FilterType Type { get; set; }
        public List<T> List { get; set; }

        public abstract List<T> GetAll();

        public bool Exists(T t)
        {
            if (this.Type == FilterType.Include)
            {
                if (this.List == null || this.List.Count == 0)
                    return false;
                return this.List.Exists(e => e.ToString() == t.ToString());
            }

            if (this.List == null || this.List.Count == 0)
                return true;

            return !this.List.Exists(e => e.ToString() == t.ToString());
        }
    }
}