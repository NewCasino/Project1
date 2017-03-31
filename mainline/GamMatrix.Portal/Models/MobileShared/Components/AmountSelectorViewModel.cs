using System.Collections.Generic;
using System.Globalization;
using System.Text;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class AmountSelectorViewModel
	{
		public bool IsDebitSource = true;
		public TransType TransferType = TransType.Transfer;
		public bool IsCurrencyChangable { get; private set; }

		private PaymentMethod _paymentDetails;
		public PaymentMethod PaymentDetails//mandatory if TransferType is Deposit or Withdraw
		{
			get { return _paymentDetails; }
			set 
			{
				_paymentDetails = value;
				IsCurrencyChangable = _paymentDetails.IsCurrencyChangable;
			}
		}

		private List<CurrencyData> _supportedCurrencies;
		public List<CurrencyData> SupportedCurrencies
		{
			get
			{
				if (_supportedCurrencies == null)
					_supportedCurrencies = GamMatrixClient.GetSupportedCurrencies();
				return _supportedCurrencies;
			}
		}

		private Range GetLimitsPerCurrency(CurrencyData currency)
		{
			Range limit;

			switch (TransferType)
			{
				case TransType.Deposit:
					limit = SmoothLimit(PaymentDetails.GetDepositLimitation(currency.Code));
					break;
				case TransType.Withdraw:
					limit = SmoothLimit(PaymentDetails.GetWithdrawLimitation(currency.Code));
					break;
				default:
					limit = new Range()
					{
						Currency = currency.Code,
						MinAmount = 0.01M,
						MaxAmount = MoneyHelper.SmoothFloor(MoneyHelper.TransformCurrency("EUR", currency.ISO4217_Alpha, 10000M))
					};
					break;
			}

			return limit;
		}

		public string GetLimitsPerCurrencyJson(CurrencyData currency)
		{
			Range limits = GetLimitsPerCurrency(currency);
			string json = string.Format(CultureInfo.InvariantCulture, "{{\"min\":{0:f2},\"max\":{1:f2} }}", limits.MinAmount, limits.MaxAmount);

			return json;
		}

		public string GetCurrencyRatesJson()
		{
			var rates = new StringBuilder("{");
			foreach (var currency in GamMatrixClient.GetCurrencyRates())
			{
				rates.AppendFormat(CultureInfo.InvariantCulture, "\"{0}\":{1:f2},"
					, currency.Key
					, currency.Value.MidRate
					);
			}
			rates.Length -= 1;
			rates.Append("}");

			return rates.ToString();
		}

		private Range SmoothLimit(Range limit)
		{
			decimal min = limit.MinAmount, max = limit.MaxAmount;
			if (min > 0.00M)
				min = MoneyHelper.SmoothCeiling(min);
			if (max > 0.00M)
				max = MoneyHelper.SmoothFloor(max);

			limit.MinAmount = min;
			limit.MaxAmount = max;
			return limit;
		}
	}
}
