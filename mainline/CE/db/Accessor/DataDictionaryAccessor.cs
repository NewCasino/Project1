using System;
using System.Collections.Generic;
using BLToolkit.DataAccess;
using GamMatrixAPI;

namespace CE.db.Accessor
{
    public abstract class DataDictionaryAccessor : DataAccessor
    {
        [SqlQuery(@"SELECT * FROM CeDataDictionary WHERE Type = @type")]
        public abstract List<ceDataItem> GetByType(string type);

        [SqlQuery(@"SELECT * FROM CeDataDictionary WHERE ID = @id")]
        public abstract ceDataItem GetById(long id);

        [Index("DataValue")]
        [ScalarFieldName("Text")]
        [SqlQuery(@"SELECT DataValue, Text FROM CeDataDictionary WHERE Type = 'GameCategory'")]
        public abstract Dictionary<string, string> GetAllGameCategory();

        
        [Index("DataValue")]
        [ScalarFieldName("Text")]
        [SqlQuery(@"SELECT DataValue, Text FROM CeDataDictionary WHERE Type = 'ClientType'")]
        public abstract Dictionary<string, string> GetAllClientType();

        
        [Index("DataValue")]
        [ScalarFieldName("Text")]
        [SqlQuery(@"SELECT DataValue, Text FROM CeDataDictionary WHERE Type = 'InvoicingGroup'")]
        public abstract Dictionary<string, string> GetAllInvoicingGroup();

        
        [Index("DataValue")]
        [ScalarFieldName("Text")]
        [SqlQuery(@"SELECT DataValue, Text FROM CeDataDictionary WHERE Type = 'ReportCategory'")]
        public abstract Dictionary<string, string> GetAllReportCategory();

        [Index("DataValue")]
        [ScalarFieldName("Text")]
        [SqlQuery(@"SELECT DataValue, Text FROM CeDataDictionary WHERE Type = 'LiveCasinoCategory'")]
        public abstract Dictionary<string, string> GetAllLiveCasinoCategory();

        
        [Index("ID")]
        [ScalarFieldName("Text")]
        [SqlQuery(@"SELECT ID, Text FROM CeDataDictionary WHERE Type = 'VendorID'")]
        public abstract Dictionary<VendorID, string> GetAllVendorID();
    }
}
