using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BLToolkit.DataAccess;
using CE.db.Accessor;
using CE.Integration.VendorApi;
using CE.Integration.VendorApi.Models;
using CE.Utils;
using EveryMatrix.Configuration;
using EveryMatrix.SessionAgent.Protocol;
using GamMatrixAPI;

namespace CE.Integration.TransferMoneyBetweenWallets
{
    public class CashTransporter
    {
        private readonly SessionPayload _userSession;
        private readonly long _domainId;
        private readonly VendorID _vendor;
        private readonly VendorApiClient _vendorApi;


        public CashTransporter(SessionPayload session,long domainId, VendorID vendor)
        {
            _vendorApi = new VendorApiClient(vendor.ToString());
            _domainId = domainId;            
            _userSession = session;
            _vendor = vendor;
        }

        private void CreateUser(string language)
        {
            CreateUserResponse userResponse = _vendorApi.CreateUser(new CreateUserRequest
            {
                DomainId = _domainId,
                UserDetails =
                {
                    UserId = _userSession.UserID,
                    UserName = _userSession.Username,
                    UserCasinoCurrency = _userSession.Currency,
                    Language = language
                }
            });

            if (!userResponse.Success)
            {
                throw new CeException(string.Format("Invalid response when creating user on vendor side, {0}", userResponse.Message));
            }
        }

        public void TransferMoney(string language)
        {
            if (IsDomainNonSeamless())
            {
                bool nonSeamlessVendor = GlobalConstant.NonSeamlessVendors.Contains(_vendor);
                if (nonSeamlessVendor)
                {         
                    CreateUser(language);
                }

                int currentWalletId = nonSeamlessVendor ? (int)_vendor : (int)VendorID.CasinoWallet;
                TransferToWallet(target: currentWalletId);

                try
                {
                    List<VendorBalance> walletBalances = GetWalletBalances();

                    foreach (VendorBalance vendorBalance in walletBalances)
                    {
                        if (vendorBalance.VendorId != currentWalletId && vendorBalance.Balance > 0) // Has funds on non-active wallet, so need to make transfer from it.
                        {
                            TransferFromWallet(source: vendorBalance.VendorId);
                        }
                    }
                }
                catch (Exception e)
                {
                    GmLogger.Instance.ErrorException(e, "Error while EnsureBalance");
                }    
            }
        }       

        private void TransferToWallet(int target)
        {
            TransferResponse response = _vendorApi.TransferMoney(new TransferRequest
            {
                Currency = _userSession.Currency,
                DomainId = _domainId,
                UserId = _userSession.UserID,
                IpAddress = _userSession.IP,
                UserName = _userSession.Username,
                Target = target,
            });

            if (!response.Success)
            {
                throw new CeException(String.Format("Transfer to {0}. Cannot open game of vendor {0} because {1}{2}", target, response.VendorError, response.Message));
            }
        }

        private void TransferFromWallet(int source)
        {
            TransferResponse response = _vendorApi.TransferMoney(new TransferRequest
            {
                Currency = _userSession.Currency,
                DomainId = _domainId,
                UserId = _userSession.UserID,
                IpAddress = _userSession.IP,
                UserName = _userSession.Username,
                Source = source
            });

            GmLogger.Instance.Trace(string.Format(
                       "Casino wallet money balance double check, transfer money for vendor:{0}, received result is {1}", _vendor, response.Success));
        }

        private List<VendorBalance> GetWalletBalances()
        {
            GetBalanceResponse response = _vendorApi.GetWalletBalance(new GetBalanceRequest
            {
                UserId = _userSession.UserID,
                DomainId = _domainId,
                UserName = _userSession.Username
            });

            if (!response.Success)
            {
                throw new CeException(String.Format("Cant get wallet balances, vendorId: {0}, domainId: {1}, UserId: {2}", _vendor, _domainId, _userSession.UserID));
            }

            return response.VendorBalances;
        }

        private bool IsDomainNonSeamless()
        {
            CasinoVendorAccessor cva = DataAccessor.CreateInstance<CasinoVendorAccessor>();
            List<VendorID> enabledVendors = cva.GetEnabledVendors(_domainId);

            foreach (var vendor in enabledVendors)
            {
                if (GlobalConstant.NonSeamlessVendors.Contains(vendor))
                {
                    return true;
                }
            }

            return false;
        }                  
    }
}
