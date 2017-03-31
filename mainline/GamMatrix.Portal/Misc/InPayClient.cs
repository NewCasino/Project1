using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Web.Hosting;
using System.Xml.Linq;
using CM.Sites;
using CM.State;
using GmCore;

[Serializable]
public class InPayBank
{
    public string Name { get; set; }
    public int ID { get; set; }
}

[Serializable]
public class InPayCountry
{
    public string CountryCode { get; set; }
    public string CountryName { get; set; }
    public List<InPayBank> Banks { get; set; }

    public InPayCountry()
    {
        Banks = new List<InPayBank>();
    }
}

[Serializable]
[DataContract]
public class InPayInstructions
{
    [DataMember(Name = "url")]
    public string Url { get; set; }

    [DataMember(Name = "currency")]
    public string Currency { get; set; }

    [DataMember(Name = "amount")]
    public string Amount { get; set; }

    [DataMember(Name = "reference")]
    public string Reference { get; set; }

    [DataMember(Name = "accountdetails")]
    public List<InPayBeneficiaryAccount> BeneficiaryAccounts { get; set; }

    public InPayInstructions()
    {
        BeneficiaryAccounts = new List<InPayBeneficiaryAccount>();
    }
}

[Serializable]
[DataContract]
public class InPayBeneficiaryAccount
{
    [DataMember(Name = "id")]
    public string ID { get; set; }

    [DataMember(Name = "name")]
    public string Name { get; set; }

    [DataMember(Name = "value")]
    public string Value { get; set; }
}

public static class InPayClient
{
    public static List<InPayCountry> GetInPayCountryAndBanks()
    {
        var domain = SiteManager.Current;
        var profile = CustomProfile.Current;

        //string cacheKey = string.Format("GamMatrixClient.InPayCountriesAndBanksRequest.{0}.{1}", domain.DistinctName, CustomProfile.Current.UserCountryID);
        string cacheKey = string.Format("GamMatrixClient.InPayCountriesAndBanksRequest.{0}", domain.DistinctName);

        string inPayCountryAndBanksFile = HostingEnvironment.MapPath(string.Format("~/App_Data/{0}/Payment.InPayCountryAndBanks", domain.DistinctName));
        FileSystemUtility.EnsureDirectoryExist(inPayCountryAndBanksFile);

        Func<List<InPayCountry>> func = () =>
        {
            try
            {
                List<InPayCountry> list = new List<InPayCountry>();

                var countries = CountryManager.GetAllCountries(domain.DistinctName);

                XDocument xml = XDocument.Parse(GamMatrixClient.GetInPayCountryAndBanksXml(domain, profile));
                //XDocument xml = XDocument.Parse(ReadXml());
                var countryElements = xml.Root.Element("countries").Elements("country");
                foreach (XElement countryElement in countryElements)
                {
                    XElement isoElement = countryElement.Element("iso");

                    if (isoElement == null)
                        continue;

                    var bankElements = countryElement.Element("banks").Elements("bank");
                    if (bankElements.Count() == 0)
                        continue;

                    var c = countries.FirstOrDefault(c1 => c1.ISO_3166_Alpha2Code == isoElement.Value);
                    if (c == null)
                        continue;

                    InPayCountry country = new InPayCountry()
                    {
                        CountryCode = c.ISO_3166_Alpha2Code,
                        CountryName = c.EnglishName
                    };
                    list.Add(country);

                    foreach (var bankElement in bankElements)
                    {
                        string bankName = bankElement.GetElementValue("name");
                        int bankID;
                        if (bankName != null && int.TryParse(bankElement.GetElementValue("id"), out bankID))
                        {
                            country.Banks.Add(new InPayBank()
                            {
                                ID = bankID,
                                Name = bankName
                            });
                        }
                    }

                }// foreach

                //if (list.Count > 0)
                //    ObjectHelper.BinarySerialize<List<InPayCountry>>(list, inPayCountryAndBanksFile);

                return list;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        };

        //return func();

        List<InPayCountry> cached;
        if (DelayUpdateCache<List<InPayCountry>>.TryGetValue(cacheKey, out cached, func, 300))
            return cached;

        return func();
        //if (!DelayUpdateCache<List<InPayCountry>>.TryGetValue(cacheKey, out cached, func, 300))
        //{
        //    cached = ObjectHelper.BinaryDeserialize<List<InPayCountry>>(inPayCountryAndBanksFile, cached);
        //}
        //return cached != null ? cached : new List<InPayCountry>();
    }

    public static bool IsThirdParty(string xml)
    {
        // there are 2 types of methods from InPay: bank transfer & 3rd-party
        // the type is indicated by instructions -> invoice -> is-third-party
        XDocument doc = XDocument.Parse(xml);
        return doc.Root.Element("invoice").GetElementValue("is-third-party", false);
    }

    public static string GetThirdPartyRedirectForm(string xml)
    {
        if (!IsThirdParty(xml))
            throw new NotSupportedException();

        #region XML
        /*
<?xml version="1.0" encoding="UTF-8"?>
<instructions>
  <invoice>
    <status>pending</status>
    <delay type="symbol">instant</delay>
    <amount type="decimal">1.19</amount>
    <is-third-party type="boolean">true</is-third-party>
    <transfer-amount>10.60</transfer-amount>
    <merchant>
      <main-url>http://www.everymatrix.com</main-url>
      <name>Everymatrix</name>
      <id type="integer">238</id>
    </merchant>
    <transfer-amount-with-currency>10.60 CNY</transfer-amount-with-currency>
    <bank-id type="integer">55</bank-id>
    <reference>4EP7DSB</reference>
    <order-id>4985f4737f03482880e599ba79b65190</order-id>
    <invoice-comment></invoice-comment>
    <order-text>Order</order-text>
    <buyer-submitted-details>
    </buyer-submitted-details>
    <currency>EUR</currency>
    <transfer-currency>CNY</transfer-currency>
  </invoice>
  <bank>
    <bank-address>Alipay CNY&lt;br /&gt;China&lt;br /&gt;</bank-address>
    <inpay-bank-account>
      <date-format>%m.%d.%Y</date-format>
      <swift>irelevant</swift>
      <iban>irelevant</iban>
      <currency>CNY</currency>
      <money-format>x,xxx.xx</money-format>
    </inpay-bank-account>
    <country>CN</country>
    <url>http://www.alipay.com</url>
    <owner-address>inpay a/s&lt;br /&gt;Store Kongensgade 40H&lt;br /&gt;1264 Copenhagen&lt;br /&gt;Denmark&lt;br /&gt;</owner-address>
    <online-bank-url>http://www.alipay.net/cooperate/gateway.do</online-bank-url>
    <payment-instructions>
      <binaries-revision>5965
</binaries-revision>
      <bank-interface>
        <third-party>alipay</third-party>
        <fields type="array">
          <field>
            <label>subject</label>
            <value>4EP7DSB</value>
          </field>
          <field>
            <label>seller_name</label>
            <value>Global Green Community </value>
          </field>
          <field>
            <label>partner</label>
            <value>2088101000922533</value>
          </field>
          <field>
            <label>service</label>
            <value>create_forex_trade</value>
          </field>
          <field>
            <label>body</label>
            <value>4EP7DSB</value>
          </field>
          <field>
            <label>supplier</label>
            <value>701706549</value>
          </field>
          <field>
            <label>sign</label>
            <value>116e96e20d8ee2c4d8a7bda851a9b8e6</value>
          </field>
          <field>
            <label>sign_type</label>
            <value>MD5</value>
          </field>
          <field>
            <label>seller_id</label>
            <value>564220354</value>
          </field>
          <field>
            <label>out_trade_no</label>
            <value>4EP7DSB</value>
          </field>
          <field>
            <label>return_url</label>
            <value>https://test-secure.inpay.com/third_party/success</value>
          </field>
          <field>
            <label>notify_url</label>
            <value>https://test-admin.inpay.com/third_party/notify_payment_alipay</value>
          </field>
          <field>
            <label>currency</label>
            <value>CNY</value>
          </field>
          <field>
            <label>seller_industry</label>
            <value>Co2 quotes</value>
          </field>
          <field>
            <label>total_fee</label>
            <value>10.6</value>
          </field>
          <field>
            <label>_input_charset</label>
            <value>UTF-8</value>
          </field>
        </fields>
        <form-method>get</form-method>
        <instructions>shared/bank-templates/v1/banks/alipay/instructions</instructions>
      </bank-interface>
    </payment-instructions>
    <name>Alipay CNY</name>
    <id type="integer">55</id>
  </bank>
 
</instructions>
                     */
        #endregion

        XDocument doc = XDocument.Parse(xml);

        // form post method is from instructions -> bank -> payment-instructions -> bank-interface -> form-method
        // form action url is from instructions -> bank -> online-bank-url
        XElement bankInterfaceElement = doc.Root.Element("bank").Element("payment-instructions").Element("bank-interface");

        StringBuilder form = new StringBuilder();
        form.AppendFormat("<form method=\"{0}\" action=\"{1}\">"
            , bankInterfaceElement.GetElementValue("form-method").SafeHtmlEncode()
            , doc.Root.Element("bank").GetElementValue("online-bank-url").SafeHtmlEncode()
            );

        // populate the post fields
        var fields = bankInterfaceElement.Element("fields").Elements("field");
        foreach (var field in fields)
        {
            form.AppendFormat("<input type=\"hidden\" name=\"{0}\" value=\"{1}\" />"
                , field.GetElementValue("label").SafeHtmlEncode()
                , field.GetElementValue("value").SafeHtmlEncode()
                );
        }

        form.Append("</form>");
        var redirectionForm = form.ToString();
        return redirectionForm;
    }

    public static InPayInstructions GetInstructions(string xml)
    {
        #region XML
        /*
<?xml version="1.0" encoding="UTF-8"?>
<instructions>
  <bank>
    <bank-address>CommonwealthBank&lt;br /&gt;Level 7, 101 George Street&lt;br /&gt;2150 Parramatta&lt;br /&gt;NSW&lt;br /&gt;Australia&lt;br /&gt;</bank-address>
    <inpay-bank-account>
      <date-format>%d/%m/%Y</date-format>
      <registration>062-000</registration>
      <swift>CTBAAU2S</swift>
      <account>13127453</account>
      <currency>AUD</currency>
      <money-format>x,xxx.xx</money-format>
    </inpay-bank-account>
    <country>AU</country>
    <url>http://www.commbank.com.au</url>
    <owner-address>Inpay AS&lt;br /&gt;Store Kongensgade 40H&lt;br /&gt;1264 Copenhagen K&lt;br /&gt;Denmark&lt;br /&gt;</owner-address>
    <online-bank-url>https://www3.netbank.commbank.com.au/netbank/bankmain</online-bank-url>
    <payment-instructions>
      <binaries-revision>5965
</binaries-revision>
      <account-details>
        <fields type="array">
          <field>
            <label>bank_code</label>
            <transfer-route>domestic</transfer-route>
            <value>062-000</value>
            <label-value>BSB</label-value>
          </field>
          <field>
            <label>bank_account_no</label>
            <transfer-route>both</transfer-route>
            <value>13127453</value>
            <label-value>Account no.</label-value>
          </field>
        </fields>
      </account-details>
    </payment-instructions>
    <name>CommonwealthBank</name>
    <id type="integer">17</id>
  </bank>
  <invoice>
    <status>pending</status>
    <delay type="symbol">instant</delay>
    <amount type="decimal">1.19</amount>
    <is-third-party type="boolean">false</is-third-party>
    <transfer-amount>1.89</transfer-amount>
    <merchant>
      <main-url>http://www.everymatrix.com</main-url>
      <name>Everymatrix</name>
      <id type="integer">238</id>
    </merchant>
    <transfer-amount-with-currency>1.89 AUD</transfer-amount-with-currency>
    <bank-id type="integer">17</bank-id>
    <reference>45AHSG3</reference>
    <order-id>427de92374714347844e6861cd16b998</order-id>
    <invoice-comment></invoice-comment>
    <order-text>Order</order-text>
    <buyer-submitted-details>
    </buyer-submitted-details>
    <currency>EUR</currency>
    <transfer-currency>AUD</transfer-currency>
  </invoice>
</instructions>
                     */
        #endregion

        XDocument doc = XDocument.Parse(xml);

        bool is3rdParty = doc.Root.Element("invoice").GetElementValue("is-third-party", false);
        if (is3rdParty)
            throw new NotSupportedException();

        var instructions = new InPayInstructions
        {
            Url = doc.Root.Element("bank").GetElementValue("url"),
            Currency = doc.Root.Element("invoice").GetElementValue("transfer-currency"),
            Amount = doc.Root.Element("invoice").GetElementValue("transfer-amount"),
            Reference = doc.Root.Element("invoice").GetElementValue("reference"),
        };

        // detect domestic v.s. internaltional transfer by user's profile country
        string countryCode = doc.Root.Element("bank").GetElementValue("country");
        bool isDomestic = true; //  string.Equals(profile.UserCountry, countryCode, StringComparison.InvariantCultureIgnoreCase);

        //beneficiaryAccount
        var fields = doc.Root.Element("bank").Element("payment-instructions").Element("account-details").Element("fields").Elements("field");
        foreach (XElement field in fields)
        {
            // exclude the necessary field
            string type = field.GetElementValue("transfer-route");
            if (!string.Equals(type, "both", StringComparison.InvariantCultureIgnoreCase))
            {
                if (isDomestic && !string.Equals(type, "domestic", StringComparison.InvariantCultureIgnoreCase))
                    continue;

                if (!isDomestic && !string.Equals(type, "foreign", StringComparison.InvariantCultureIgnoreCase))
                    continue;
            }

            instructions.BeneficiaryAccounts.Add(new InPayBeneficiaryAccount
            {
                ID = field.GetElementValue("label"),
                Name = field.GetElementValue("label-value"),
                Value = field.GetElementValue("value")
            });
        }

        return instructions;

    }





}
