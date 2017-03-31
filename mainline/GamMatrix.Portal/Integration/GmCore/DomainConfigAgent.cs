using System;
using System.IO;
using System.Web.Hosting;
using CM.db;
using CM.Sites;
using Finance;
using GamMatrixAPI;

namespace GmCore
{
    public static class DomainConfigAgent
    {
        private static GetDomainModuleFeaturesRequest InternalGetConfig(cmSite site)
        {
            string filepath = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                , site.DistinctName
                , "DomainConfigAgent.InternalGetConfig.dat"
                );

            GetDomainModuleFeaturesRequest request = new GetDomainModuleFeaturesRequest()
            {
                DomainID = site.DomainID,
                SESSION_ID = GamMatrixClient.GetSessionID(site, true),
            };

            Func<GetDomainModuleFeaturesRequest> func = () =>
            {
                try
                {
                    using( GamMatrixClient client = new GamMatrixClient() )
                    {
                        request = client.SingleRequest<GetDomainModuleFeaturesRequest>(request);

                        ObjectHelper.BinarySerialize<GetDomainModuleFeaturesRequest>(request, filepath);

                        return request;
                    }                    
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    throw;
                }
            };

            GetDomainModuleFeaturesRequest cached;
            if (!DelayUpdateCache<GetDomainModuleFeaturesRequest>.TryGetValue(filepath, out cached, func, 1 * 60))
            {
                try
                {
                    cached = ObjectHelper.BinaryDeserialize<GetDomainModuleFeaturesRequest>(filepath, null);
                }
                catch
                {
                }
            }

            return cached;
        }

        public static bool IsVendorEnabled(this PaymentMethod paymentMethod)
        {
            return IsVendorEnabled(paymentMethod, SiteManager.Current);
        }

        public static bool IsVendorEnabled(this PaymentMethod paymentMethod, cmSite site)
        {
            return true;
            GetDomainModuleFeaturesRequest request = InternalGetConfig(site);
            if (request == null)
                return true;

            try
            {
                switch (paymentMethod.VendorID)
                {
                    case VendorID.ArtemisBank:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardArtemisBank].IsEnabled;

                    case VendorID.ArtemisCard:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardArtemisCard].IsEnabled;

                    case VendorID.ArtemisSMS:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardArtemisSMS].IsEnabled;

                    case VendorID.Bank:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardBankVendor].IsEnabled;

                    case VendorID.Click2Pay:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardClick2PayVendor].IsEnabled;

                    case VendorID.ClickandBuy:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardClickandBuyVendor].IsEnabled;

                    case VendorID.DotpaySMS:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardDotpaySMSVendor].IsEnabled;

                    case VendorID.Dotpay:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardDotpayVendor].IsEnabled;

                    case VendorID.EcoCard:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardEcoCardVendor].IsEnabled;

                    case VendorID.EntroPay:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardEntroPayVendor].IsEnabled;

                    case VendorID.Envoy:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardEnvoyVendor].IsEnabled;

                    case VendorID.GeorgianCard:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardGeorgianCardVendor].IsEnabled;

                    case VendorID.ICEPAY:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardICEPAYVendor].IsEnabled;

                    case VendorID.Intercash:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardIntercashVendor].IsEnabled;

                    case VendorID.IPSToken:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardIPSTokenVendor].IsEnabled;

                    case VendorID.Moneybookers:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardMoneybookersVendor].IsEnabled;

                    case VendorID.Neteller:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardNetellerVendor].IsEnabled;

                    case VendorID.NLB:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardNLBVendor].IsEnabled;

                    case VendorID.NOVA:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardNOVAVendor].IsEnabled;

                    case VendorID.OSMP:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardOSMPVendor].IsEnabled;

                    case VendorID.PayAnyWay:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardPayAnyWayVendor].IsEnabled;

                    case VendorID.PayGE:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardPayGEVendor].IsEnabled;

                    case VendorID.PaymentTrust:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardPaymentTrustVendor].IsEnabled;

                    case VendorID.Paynet:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardPaynetVendor].IsEnabled;

                    case VendorID.Paysafecard:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardPaysafecardVendor].IsEnabled;

                    case VendorID.QVoucher:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardQVoucherVendor].IsEnabled;

                    case VendorID.TBC:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardTBCVendor].IsEnabled;

                    case VendorID.TLNakit:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardTLNakitVendor].IsEnabled;

                    case VendorID.ToditoCard:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardToditoCardVendor].IsEnabled;

                    case VendorID.TurkeyBank:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardTurkeyBank].IsEnabled;

                    case VendorID.TurkeyBankWire:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardTurkeyBankWire].IsEnabled;

                    case VendorID.TurkeyCard:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardTurkeyCard].IsEnabled;

                    case VendorID.TurkeySMS:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardTurkeySMS].IsEnabled;

                    case VendorID.Ukash:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardUkashVendor].IsEnabled;

                    case VendorID.Voucher:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardVoucherVendor].IsEnabled;

                    case VendorID.WebMoney:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardWebMoneyVendor].IsEnabled;

                    case VendorID.UiPas:
                        return request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardUiPasVendor].IsEnabled;

                    default:
                        return true;
                }
            }
            catch
            {
                return true;
            }
        }


        public static bool IsWithdrawEnabled(this PaymentMethod paymentMethod)
        {
            return true;
            GetDomainModuleFeaturesRequest request = InternalGetConfig(SiteManager.Current);
            if (request == null)
                return true;

            if (!IsVendorEnabled(paymentMethod))
                return false;

            try
            {
                switch (paymentMethod.VendorID)
                {
                    case VendorID.Ukash:
                        return string.Equals("YES"
                            , request.DomainModuleFeatureConfig[ModuleID.PayCard][ModuleFeatureID.PayCardUkashVendor]["Ukash Issue Live Mode enabled#"]
                            , StringComparison.InvariantCultureIgnoreCase);

                    case VendorID.PaymentTrust:
                        {
                            if (!request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardPaymentTrustVendor].IsEnabled)
                                return false;
                            bool enablePT = string.Equals("YES"
                                , request.DomainModuleFeatureConfig[ModuleID.PayCard][ModuleFeatureID.PayCardPaymentTrustVendor]["PaymentTrust Live Mode enabled#"]
                                , StringComparison.InvariantCultureIgnoreCase
                                );
                            bool enablePP = request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardPayPointVendor].IsEnabled;
                            bool enableDP = request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardDirectPaymentVendor].IsEnabled;
                            bool enableIPS = request.DomainModuleFeature[ModuleID.PayCard][ModuleFeatureID.PayCardIPSVendor].IsEnabled;

                            if ( (enableDP | enableIPS) && !enablePT && !enablePP && !enableIPS)
                                return false;

                            return true;
                        }

                    default:
                        return true;
                }
            }
            catch
            {
                return true;
            }
        }
    }
}
