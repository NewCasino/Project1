using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace CM.Web.UI
{
    /// <summary>
    /// Helper class to generate validator for controls, and the validator is used by jQuery.validation plug in.
    /// </summary>
    public sealed class ClientValidators
    {
        private sealed  class ValidatorInfo
        {
            public string ErrorMessage {get; set;}
            public object ExtraParameter1 {get; set;}
            public object ExtraParameter2 { get; set; }
        }

        private Dictionary<string, ValidatorInfo> m_Validators = new Dictionary<string, ValidatorInfo>();

        private ClientValidators()
        {
        }

        /// <summary>
        /// Create an instance
        /// </summary>
        /// <returns></returns>
        public static ClientValidators Create()
        {
            return new ClientValidators();
        }

        /// <summary>
        /// Value can't be empty
        /// </summary>
        /// <param name="errorMessage">Error message when value is empty</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Required(string errorMessage = null)
        {
            m_Validators["required"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is required")
            };
            return this;
        }

        /// <summary>
        /// Value can;t be empty in some conditions
        /// </summary>
        /// <param name="callback">javascript function, returns the bool value indicates if the validator is enabled/disabled</param>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators RequiredIf(string callback, string errorMessage = null)
        {
            m_Validators["required"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is required"),
                ExtraParameter1 = callback,
            };
            return this;
        }

        /// <summary>
        /// Value's length must be equal or greater than the minimum length.
        /// </summary>
        /// <param name="minLen">min length</param>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators MinLength(int minLen, string errorMessage = null)
        {
            m_Validators["minlength"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
                ExtraParameter1 = minLen,
            };
            return this;
        }

        /// <summary>
        /// Value's length must be equal or less than the max length.
        /// </summary>
        /// <param name="maxLen">max length</param>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators MaxLength(int maxLen, string errorMessage = null)
        {
            m_Validators["maxlength"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
                ExtraParameter1 = maxLen,
            };
            return this;
        }

        /// <summary>
        /// Value's length must in the range
        /// </summary>
        /// <param name="minLen">min length</param>
        /// <param name="maxLen">max length</param>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Rangelength(int minLen, int maxLen, string errorMessage = null)
        {
            m_Validators["rangelength"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
                ExtraParameter1 = minLen,
                ExtraParameter2 = maxLen,
            };
            return this;
        }

        /// <summary>
        /// Numberic value must equal or greater than min value
        /// </summary>
        /// <param name="minValue">min value</param>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Min(int minValue, string errorMessage = null)
        {
            m_Validators["min"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
                ExtraParameter1 = minValue,
            };
            return this;
        }

        /// <summary>
        /// Numberic value must be equal or less than max value
        /// </summary>
        /// <param name="maxValue">max value</param>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Max(int maxValue, string errorMessage = null)
        {
            m_Validators["max"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
                ExtraParameter1 = maxValue,
            };
            return this;
        }

        /// <summary>
        /// Numberic value must in the range
        /// </summary>
        /// <param name="minValue">min value</param>
        /// <param name="maxValue">max value</param>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Range(decimal minValue, decimal maxValue, string errorMessage = null)
        {
            m_Validators["range"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
                ExtraParameter1 = minValue,
                ExtraParameter2 = maxValue,
            };
            return this;
        }


        /// <summary>
        /// Text value must be correct email address
        /// </summary>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Email(string errorMessage = null)
        {
            m_Validators["email"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
            };
            return this;
        }

        /// <summary>
        /// Text value must be correct url address.
        /// </summary>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Url(string errorMessage = null)
        {
            m_Validators["url"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
            };
            return this;
        }

        /// <summary>
        /// Text value must be correct date format
        /// </summary>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Date(string errorMessage = null)
        {
            m_Validators["date"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
            };
            return this;
        }

        /// <summary>
        /// Text value must be iso date date format
        /// </summary>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators DateISO(string errorMessage = null)
        {
            m_Validators["dateISO"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
            };
            return this;
        }

        /// <summary>
        /// Text value must be number
        /// </summary>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Number(string errorMessage = null)
        {
            m_Validators["number"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
            };
            return this;
        }

        /// <summary>
        /// Text value must be digits
        /// </summary>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Digits(string errorMessage = null)
        {
            m_Validators["digits"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
            };
            return this;
        }

        /// <summary>
        /// Value of this countrol must be equal to the compared control's value
        /// </summary>
        /// <param name="selector">CSS selector</param>
        /// <param name="errorMessage">error message</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators EqualTo(string selector, string errorMessage = null)
        {
            m_Validators["equalTo"] = new ValidatorInfo()
            {
                ErrorMessage = errorMessage.DefaultIfNullOrEmpty("This field is invalid"),
                ExtraParameter1 = selector,
            };
            return this;
        }

        /// <summary>
        /// Validate this field via server method
        /// </summary>
        /// <param name="url">server url</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Server(string url)
        {
            m_Validators["server"] = new ValidatorInfo()
            {
                ExtraParameter1 = string.Format( "{{ url:'{0}', type:'post'}}"
                    , url.SafeHtmlEncode()
                    )
            };
            return this;
        }

        /// <summary>
        /// Custom validation
        /// </summary>
        /// <param name="javascriptFunction">javascript function</param>
        /// <returns>ClientValidators instance</returns>
        public ClientValidators Custom(string javascriptFunction)
        {
            m_Validators["custom"] = new ValidatorInfo()
            {
                ExtraParameter1 = javascriptFunction,
            };
            return this;
        }

        /// <summary>
        /// Output the validator attributes string, used by jQuery.validation plug in
        /// </summary>
        /// <returns>the string</returns>
        public override string ToString()
        {
            StringBuilder sb1 = new StringBuilder();
            StringBuilder sb2 = new StringBuilder();
            sb1.Append("{");
            sb2.Append("messages:{");
            foreach (var item in m_Validators)
            {
                switch (item.Key.ToLower(CultureInfo.InvariantCulture))
                {
                    case "required":
                        sb1.AppendFormat("required:{0},", item.Value.ExtraParameter1 ?? "true");
                        break;

                    case "minlength":
                        sb1.AppendFormat("minlength:{0},", item.Value.ExtraParameter1);
                        break;

                    case "maxlength":
                        sb1.AppendFormat("maxlength:{0},", item.Value.ExtraParameter1);
                        break;

                    case "rangelength":
                        sb1.AppendFormat("rangelength:[{0},{1}],", item.Value.ExtraParameter1, item.Value.ExtraParameter2);
                        break;

                    case "min":
                        sb1.AppendFormat("min:{0},", item.Value.ExtraParameter1);
                        break;

                    case "max":
                        sb1.AppendFormat("max:{0},", item.Value.ExtraParameter1);
                        break;

                    case "range":
                        sb1.AppendFormat("range:[{0},{1}],", item.Value.ExtraParameter1, item.Value.ExtraParameter2);
                        break;

                    case "email":
                        sb1.Append("email:true,");
                        break;

                    case "url":
                        sb1.Append("url:true,");
                        break;

                    case "date":
                        sb1.Append("date:true,");
                        break;

                    case "dateiso":
                        sb1.Append("dateISO:true,");
                        break;

                    case "number":
                        sb1.Append("number:true,");
                        break;

                    case "digits":
                        sb1.Append("digits:true,");
                        break;

                    case "equalto":
                        sb1.AppendFormat("equalTo:\"{0}\",", (item.Value.ExtraParameter1 as string).SafeJavascriptStringEncode());
                        break;

                    case "server":
                        sb1.AppendFormat("server:{0},", item.Value.ExtraParameter1);
                        break;

                    case "custom":
                        sb1.AppendFormat("custom:function(){{ return {0}; }},", (item.Value.ExtraParameter1 as string).SafeHtmlEncode());
                        break;

                    default:
                        throw new Exception(string.Format("Unknown validator type:{0}", item.Key));
                }
                
                if( item.Value.ErrorMessage != null )
                    sb2.AppendFormat("{0}:\"{1}\",", item.Key, item.Value.ErrorMessage.SafeJavascriptStringEncode());
            }
            if (sb2[sb2.Length - 1] == ',')
                sb2.Remove(sb2.Length - 1, 1);
            sb2.Append("}");
            sb1.Append(sb2);
            sb1.Append("}");
            return sb1.ToString();
        }
    }
}
