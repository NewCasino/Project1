namespace CM.db
{
    //[Index(new string[]{"Guid"})]
    /// <summary>
    /// Stores a session value record.
    /// </summary>
    public class cmSessionValue
    {
        /// <summary>
        /// SessionGuid Field
        /// </summary>
        public string               SessionGuid { get; set; }

        /// <summary>
        /// SessionName Field
        /// </summary>
        public string               SessionName { get; set; }

        /// <summary>
        /// SessionValue Field
        /// </summary>
        public string               SessionValue { get; set; }
    }
}
