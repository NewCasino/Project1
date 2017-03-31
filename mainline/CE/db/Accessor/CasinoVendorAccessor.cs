using System.Collections.Generic;
using System.Data;
using System.Text;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using GamMatrixAPI;

namespace CE.db.Accessor
{
    public abstract class CasinoVendorAccessor : DataAccessor<ceCasinoVendor>
    {
        [SqlQuery( @"SELECT VendorID FROM CeCasinoVendor WHERE DomainID = @domainID AND Enabled = 1" )]
        public abstract List<VendorID> GetEnabledVendors(long domainID);


        [SqlQuery(@"SELECT VendorID FROM CeCasinoVendor WHERE DomainID = @domainID AND HasLiveCasino = 1")]
        public abstract List<VendorID> GetLiveCasinoVendors(long domainID);

        [SqlQuery(@"
INSERT INTO CeCasinoVendor
(DomainID
,VendorID
,BonusDeduction
,RestrictedTerritories
,Enabled
,Languages
)
SELECT @systemDomainID, d.ID ,0.00 ,'' ,1,''
FROM CeDataDictionary d
WHERE d.Type = 'VendorID' AND NOT EXISTS
(
	SELECT * FROM CeCasinoVendor v
	WHERE v.DomainID = @systemDomainID
	AND v.VendorID = d.ID
);
SELECT * FROM CeCasinoVendor WHERE DomainID = @domainID AND Enabled = 1")]
        public abstract List<ceCasinoVendor> GetEnabledVendorList(long domainID, long systemDomainID);

        
        [Index("VendorID")]
        [ScalarFieldName("RestrictedTerritories")]
        [SqlQuery(@"SELECT VendorID, RestrictedTerritories FROM CeCasinoVendor WHERE DomainID = @domainID")]
        public abstract Dictionary<VendorID, string> GetRestrictedTerritoriesDictionary(long domainID);

        [Index("VendorID")]
        [ScalarFieldName("Languages")]
        [SqlQuery(@"SELECT VendorID, Languages FROM CeCasinoVendor WHERE DomainID = @domainID AND Enabled = 1")]
        public abstract Dictionary<VendorID, string> GetLanguagesDictionary(long domainID);

        [Index("VendorID")]
        [ScalarFieldName("Currencies")]
        [SqlQuery(@"SELECT VendorID, Currencies FROM CeCasinoVendor WHERE DomainID = @domainID AND Enabled = 1")]
        public abstract Dictionary<VendorID, string> GetCurrenciesDictionary(long domainID);

        [Index("VendorID")]
        [ScalarFieldName("License")]
        [SqlQuery(@"SELECT VendorID, License FROM CeCasinoVendor WHERE DomainID = @domainID")]
        public abstract Dictionary<VendorID, LicenseType> GetVendorsLicenses(long domainID);
        /// <summary>
        /// 
        /// </summary>
        /// <param name="domainID"></param>
        /// <param name="vendors"></param>
        public static void SetEnabledVendors(long domainID, long systemDomainID
            , VendorID[] enabledVendors
            , VendorID[] liveCasinoVendors
            )
        {
            using (DbManager db = new DbManager())
            {
                StringBuilder sql = new StringBuilder();
                List<IDbDataParameter> cmdParams = new List<IDbDataParameter>();

                if (enabledVendors == null || enabledVendors.Length == 0)
                {
                    sql.Append(@"UPDATE CeCasinoVendor SET Enabled = 0 WHERE DomainID = @domainID");
                }
                else
                {
                    // IN CLAUSE
                    StringBuilder inClause1 = new StringBuilder();
                    for (int i = 0; i < enabledVendors.Length; i++)
                    {
                        inClause1.AppendFormat("@p{0},", i + 1);
                        var v = db.Parameter(string.Format("@p{0}", i + 1), DbType.Int32);
                        v.Value = (int)enabledVendors[i];
                        cmdParams.Add(v);
                    }
                    if (inClause1.Length > 0 && inClause1[inClause1.Length - 1] == ',')
                        inClause1.Remove(inClause1.Length - 1, 1);

                    string subSql;
                    if (liveCasinoVendors == null || liveCasinoVendors.Length == 0)
                    {
                        subSql = @"UPDATE CeCasinoVendor SET HasLiveCasino = 0 WHERE DomainID = @domainID;";
                    }
                    else
                    {
                        StringBuilder inClause2 = new StringBuilder();
                        for (int i = 0; i < liveCasinoVendors.Length; i++)
                        {
                            inClause2.AppendFormat("@q{0},", i + 1);
                            var v = db.Parameter(string.Format("@q{0}", i + 1), DbType.Int32);
                            v.Value = (int)liveCasinoVendors[i];
                            cmdParams.Add(v);
                        }
                        if (inClause2.Length > 0 && inClause2[inClause2.Length - 1] == ',')
                            inClause2.Remove(inClause2.Length - 1, 1);

                        subSql = string.Format(@"UPDATE CeCasinoVendor SET HasLiveCasino = 0 WHERE DomainID = @domainID AND VendorID NOT IN ({0});
UPDATE CeCasinoVendor SET HasLiveCasino = 1 WHERE DomainID = @domainID AND VendorID IN ({0});"
                            , inClause2.ToString()
                            );
                    }

                    switch (db.DataProvider.Name.ToUpperInvariant())
                    {
                        case "MYSQL":
                            sql.AppendFormat(@"
INSERT INTO CeCasinoVendor( DomainID, VendorID, BonusDeduction,RestrictedTerritories,Languages )
SELECT @domainID, d.ID, IFNULL( s.BonusDeduction, 0.00), IFNULL( s.RestrictedTerritories, ''), IFNULL( s.Languages, '')
FROM CeDataDictionary d
LEFT JOIN CeCasinoVendor s ON s.DomainID = @systemDomainID AND s.VendorID = d.ID
WHERE d.Type = 'VendorID'
AND NOT EXISTS
(
	SELECT * FROM CeCasinoVendor v
	WHERE v.DomainID = @domainID
	AND v.VendorID = d.ID
)
AND d.ID IN ( {0} );
UPDATE CeCasinoVendor SET Enabled = 0 WHERE DomainID = @domainID AND VendorID NOT IN ({0});
UPDATE CeCasinoVendor SET Enabled = 1 WHERE DomainID = @domainID AND VendorID IN ({0});
{1}
"
                            , inClause1.ToString()
                            , subSql
                            );
                            break;

                        default:
                            sql.AppendFormat(@"
INSERT INTO CeCasinoVendor( DomainID, VendorID, BonusDeduction ,RestrictedTerritories,Languages )
SELECT @domainID, d.[ID],  s.BonusDeduction , ISNULL( s.RestrictedTerritories, N''), ISNULL( s.Languages, N'')
FROM CeDataDictionary d WITH(NOLOCK)
LEFT JOIN CeCasinoVendor s ON s.DomainID = @systemDomainID AND s.VendorID = d.ID
WHERE d.[Type] = 'VendorID'
AND NOT EXISTS
(
	SELECT * FROM CeCasinoVendor v
	WHERE v.DomainID = @domainID
	AND v.VendorID = d.[ID]
)
AND d.[ID] IN ( {0} );
UPDATE CeCasinoVendor SET Enabled = 0 WHERE DomainID = @domainID AND VendorID NOT IN ({0});
UPDATE CeCasinoVendor SET Enabled = 1 WHERE DomainID = @domainID AND VendorID IN ({0});
{1}"
                            , inClause1.ToString()
                            , subSql
                            );
                            break;
                    }// switch
                    
                }

                {
                    var v = db.Parameter("@domainID", DbType.Int64);
                    v.Value = domainID;
                    cmdParams.Add(v);

                    v = db.Parameter("@systemDomainID", DbType.Int64);
                    v.Value = systemDomainID;
                    cmdParams.Add(v);
                }

                db.SetCommand(sql.ToString(), cmdParams.ToArray())
                    .ExecuteNonQuery();
            }
        }// SetEnabledVendors
    }
}
