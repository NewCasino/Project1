using System;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;

namespace CE.db
{
    /// <summary>
    ///  CeDataDictionary table
    /// </summary>
    [TableName("CeDataDictionary")]
    public sealed class ceDataItem
    {
        [PrimaryKey, Identity, NonUpdatable]
        public long ID { get; set; }

        public long DomainID { get; set; }

        public string Type { get; set; }

        public string DataValue { get; set; }

        public string Text { get; set; }


        [DefaultValue("GETDATE()")]
        public DateTime Ins { get; set; }        
    }
 
}
