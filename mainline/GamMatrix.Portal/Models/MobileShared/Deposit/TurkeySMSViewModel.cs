using System.Collections.Generic;
using Finance;
using GamMatrix.CMS.Models.MobileShared.Components;
using CM.Content;

namespace GamMatrix.CMS.Models.MobileShared.Deposit
{
	public class TurkeySMSViewModel : TransactionInfo
	{
		public bool ShowSenderPhoneNumber { get; private set; }
		public bool ShowReceiverPhoneNumber { get; private set; }
		public bool ShowReceiverBirthDate { get; private set; }
		public bool ShowPassword { get; private set; }
		public bool ShowReferenceNumber { get; private set; }
		public bool ShowSenderTCNumber { get; private set; }
		public bool ShowReceiverTCNumber { get; private set; }

		public TurkeySMSViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
			: base(paymentMethod, stateVars)
		{
			switch (paymentMethod.UniqueName)
			{
				case "ArtemisSMS_Garanti":
				case "TurkeySMS_Garanti":
				case "TurkeySMS_Yapikredi":
                    {
                        ShowSenderPhoneNumber = Metadata.Get("Metadata/Settings/Deposit.TurkeySMS_Yapikredi_ShowSenderPhoneNumber").ParseToBool(false); ;
                        ShowReceiverPhoneNumber = Metadata.Get("Metadata/Settings/Deposit.TurkeySMS_Yapikredi_ShowReceiverPhoneNumber").ParseToBool(false); ;
                        ShowReceiverBirthDate = false;
                        ShowPassword = Metadata.Get("Metadata/Settings/Deposit.TurkeySMS_Yapikredi_ShowPassword").ParseToBool(false); ;
                        ShowReferenceNumber = false;
                        ShowSenderTCNumber = false;
                        ShowReceiverTCNumber = Metadata.Get("Metadata/Settings/Deposit.TurkeySMS_Yapikredi_ShowReceiverTCNumber").ParseToBool(false);
                        break;
                    }
				case "TurkeySMS_Havalesi":
					{
						ShowSenderPhoneNumber = true;
						ShowReceiverPhoneNumber = true;
						ShowReceiverBirthDate = false;
						ShowPassword = true;
						ShowReferenceNumber = false;
						ShowSenderTCNumber = false;
						ShowReceiverTCNumber = false;
						break;
					}
				case "ArtemisSMS_Akbank":
				case "TurkeySMS_Akbank":
					{
						ShowSenderPhoneNumber = true;
						ShowReceiverPhoneNumber = true;
						ShowReceiverBirthDate = false;
						ShowPassword = false;
						ShowReferenceNumber = true;
						ShowSenderTCNumber = true;
						ShowReceiverTCNumber = false;
						break;
					}
				case "ArtemisSMS_Isbank":
				case "TurkeySMS_Isbank":
					{
						ShowSenderPhoneNumber = true;
						ShowReceiverPhoneNumber = false;
						ShowReceiverBirthDate = true;
						ShowPassword = false;
						ShowReferenceNumber = true;
						ShowSenderTCNumber = false;
						ShowReceiverTCNumber = true;
						break;
					}
				case "ArtemisSMS_YapiKredi":
					{
						ShowSenderPhoneNumber = false;
						ShowReceiverPhoneNumber = true;
						ShowReceiverBirthDate = false;
						ShowPassword = true;
						ShowReferenceNumber = false;
						ShowSenderTCNumber = false;
						ShowReceiverTCNumber = true;
						break;
					}
			}
		}
	}
}
