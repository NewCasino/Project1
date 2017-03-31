using System;
using System.Collections.Generic;
using GamMatrixAPI;

namespace GamMatrix.CMS.Models.Common.Components
{
    public class MoneyMatrixPrepareViewModel
    {
        public MoneyMatrixPrepareViewModel(TransactionType transactionType, string paymentSolutionName)
        {
            this.Type = transactionType;
            this.MoneyMatrixPaymentSolutionName = paymentSolutionName;
        }

        public TransactionType Type { get; set; }

        public string MoneyMatrixPaymentSolutionName { get; set; }
    }

    public class MoneyMatrixCreditCardPrepareViewModel : MoneyMatrixPrepareViewModel
    {
        public MoneyMatrixCreditCardPrepareViewModel(TransactionType transactionType, List<string> brandTypes = null, bool hasLoadSdk = true, List<string> acceptableCardBins = null)
            : base(transactionType, "CreditCard")
        {
            this.BrandTypes = brandTypes;
            this.AcceptableCardBins = acceptableCardBins;
            this.HasLoadSdk = hasLoadSdk;

            BrandCardTypeMatching = new Dictionary<string, string>
            {
                {"VI", "visa"},
                {"VD", "visa" },
                {"VE", "visa" },
                {"MC", "mastercard"},
                {"MD", "mastercard" }
            };

            BinCardSubtypeMatching = new Dictionary<string, string>
            {
                {"5019", "dankort" },
                {"4571", "dankort" }
            };
        }

        public List<string> BrandTypes { get; set; }

        public List<string> AcceptableCardBins { get; set; }

        public Dictionary<string, string> BrandCardTypeMatching { get; set; }

        public Dictionary<string, string> BinCardSubtypeMatching { get; set; }

        public bool HasLoadSdk { get; private set; }
    }

    public class MoneyMatrixPaymentSolutionPrepareViewModel : MoneyMatrixPrepareViewModel
    {
        public MoneyMatrixPaymentSolutionPrepareViewModel(TransactionType transactionType, string paymentSolutionName, VendorID gmCorePaymentSolutionId = VendorID.Unknown, List<MmInputField> inputFields = null, bool allowInfiniteCardEntries = false, string[] relatedMoneyMatrixPaymentSolutionNames = null) :
            base (transactionType, paymentSolutionName)
        {
            this.GmCorePaymentSolutionId = gmCorePaymentSolutionId;
            this.InputFields = inputFields;
            this.AllowInfiniteCardEntries = allowInfiniteCardEntries;
            this.RelatedMoneyMatrixPaymentSolutionNames = relatedMoneyMatrixPaymentSolutionNames;
        }

        public VendorID GmCorePaymentSolutionId { get; set; }

        public List<MmInputField> InputFields { get; set; }

        public bool AllowInfiniteCardEntries { get; set; }

        public MmInputField CurrentInputField { get; set; }

        public string[] RelatedMoneyMatrixPaymentSolutionNames { get; set; }

        public void ForEachInputFieldInTheModel(Action interceptor)
        {
            this.CurrentInputField = null;


            if (this.InputFields != null && this.InputFields.Count > 0)
            {
                foreach (var inputField in this.InputFields)
                {
                    this.CurrentInputField = inputField;

                    interceptor();
                }
            }
        }

        public string Normalize(string value)
        {
            return value.Replace(".", string.Empty);
        }

        public string SupportedCurrency { get; set; }

        public string[] SupportedAmounts { get; set; }

        public bool UseDummyPayCard { get; set; }
    }

    public class MmInputField
    {
        private const string TimeRegex = @"^\d{2,}:(?:[0-5]\d)$";
        private const string TimeDefaultValue = "00:00";
        private const string NumberRegex = @"^[0-9]$";
        private const string NumberDefaultValue = "0";
        private const string DateRegex = @"^(0[1-9]|1\d|2\d|3[01])\/(0[1-9]|1[0-2])\/(19|20)\d{2}$";

        public MmInputField(string name, string label) : this(name, label, MmInputFieldType.TextBox) { }

        public MmInputField(string name, string label, MmInputFieldType type)
        {
            this.Name = name;
            this.Label = label;
            this.Type = type;
        }

        public string Name { get; set; }

        public string DefaultValue { get; set; }

        public Dictionary<string, string> Values { get; set; }

        public string Label { get; set; }

        private MmInputFieldType type = MmInputFieldType.TextBox;

        public MmInputFieldType Type
        {
            get { return type; }
            set
            {
                type = value;
                switch (value)
                {
                    case MmInputFieldType.TextBoxTime:
                        this.Format = TimeRegex;
                        this.DefaultValue = TimeDefaultValue;
                        break;
                    case MmInputFieldType.TextBoxNumber:
                        this.Format = NumberRegex;
                        this.DefaultValue = NumberDefaultValue;
                        break;
                    case MmInputFieldType.DropDownDate:
                        this.Format = DateRegex;
                        break;
                    default:
                        break;
                }
            }
        }

        public bool IsRequired { get; set; }

        public string Format { get; set; }

        public string ValidationJavaScriptMethodName { get; set; }

        public bool IsAlwaysUserInput { get; set; }

        public int MaxValue { get; set; }

        public int MinValue { get; set; }

        public static MmInputField FromMmMetadataField(PaymentSolutionMetadataField metadataField)
        {
            var inputField = new MmInputField(metadataField.Key, metadataField.Name)
            {
                IsRequired = metadataField.IsRequired
            };

            switch (metadataField.Type)
            {
                case "Text":
                    inputField.Type = MmInputFieldType.TextBox;
                    break;
                case "Lookup":
                    inputField.Type = MmInputFieldType.DropDown;
                    inputField.Values = metadataField.Values;
                    break;
                case "DateTime":
                case "Date":
                    inputField.Type = MmInputFieldType.DropDownDate;
                    break;
                case "Number":
                    inputField.Type = MmInputFieldType.TextBoxNumber;
                    break;
                case "Time":
                    inputField.Type = MmInputFieldType.TextBoxTime;
                    break;
            }

            if (!string.IsNullOrEmpty(metadataField.Format))
            {
                inputField.Format = metadataField.Format;
            }

            return inputField;
        }
    }

    public enum MmInputFieldType
    {
        TextBox,
        TextBoxEmail,
        TextBoxIban,
        TextBoxSwiftCode,
        TextBoxSortCode,
        DropDownDate,
        TextBoxTime,
        DropDown,
        TextBoxNumber,
    }

    public enum TransactionType
    {
        Deposit,
        Withdraw
    }
}
