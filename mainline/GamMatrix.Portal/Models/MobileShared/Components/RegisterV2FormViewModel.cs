using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using CM.Content;
using GamMatrix.CMS.Models.Common.Base;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
    public class RegisterV2FormViewModel : ViewModelBase
    {
        public string UserTitlesMetaPath = "/Metadata/UserTitle/";
        public SelectList GetPersonTitles(string selectLabel, string selectedValue = null)
        {
            var items = new List<SelectListItem>();

            if (selectedValue == null)
            {
                items.Add(new SelectListItem() { Value = "", Text = selectLabel, Selected = true });
            }

            items.Add(new SelectListItem() { Value = "Mr.", Text = GetMetadata(UserTitlesMetaPath + ".Mr"), Selected = ("Mr." == selectedValue) });
            items.Add(new SelectListItem() { Value = "Mrs.", Text = GetMetadata(UserTitlesMetaPath + ".Mrs"), Selected = ("Mrs." == selectedValue) });
            items.Add(new SelectListItem() { Value = "Miss", Text = GetMetadata(UserTitlesMetaPath + ".Miss"), Selected = ("Miss" == selectedValue) });
            items.Add(new SelectListItem() { Value = "Ms.", Text = GetMetadata(UserTitlesMetaPath + ".Ms"), Selected = ("Ms." == selectedValue) });

            var selectList = new SelectList(items, "Value", "Text");
            return selectList;
        }

        public SelectList MobilePrefixes(string selectLabel)
        {
            var list = CountryManager.GetAllPhonePrefix().Select(p => new { Key = p, Value = p }).ToList();
            list.Insert(0, new { Key = string.Empty, Value = selectLabel });

            return new SelectList(list, "Key", "Value");
        }

        public SelectList GetCountries(string selectLabel)
        {
            var countryList = CountryManager.GetAllCountries()
                .Where(c => c.UserSelectable && c.InternalID > 0)
                .OrderBy(c => c.DisplayName)
                .ToList();

            var list = countryList
                        .Select(c => new { Key = c.InternalID.ToString(), Value = c.DisplayName })
                        .ToList();
            list.Insert(0, new { Key = string.Empty, Value = selectLabel });
            return new SelectList(list, "Key", "Value");
        }

        public SelectList GetCurrencies(string selectLabel)
        {
			var list = GamMatrixClient.GetSupportedCurrencies()
							.FilterForCurrentDomain()
							.Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
							.ToList();
            list.Insert(0, new { Key = string.Empty, Value = selectLabel });

			return new SelectList(list, "Key", "Value");
        }

        public SelectList GetSecurityQuestionList(string selectLabel)
        {
            string[] paths = Metadata.GetChildrenPaths("/Metadata/SecurityQuestion");

            var list = paths.Select(p => new { Key = GetMetadata(p + ".Text"), Value = GetMetadata(p + ".Text") }).ToList();
            list.Insert(0, new { Key = "", Value = selectLabel });

            return new SelectList(list, "Key", "Value");
        }

        public string GetLegalAgeDate()
        {
            return DateTime.Now.AddYears(-1 * Settings.Registration.LegalAge).ToString("yyyy, M - 1, d");
        }

        //public string UserName { get; set; }
        //public string Title { get; set; }
        //public string FirstName { get; set; }
        //public string Surname { get; set; }
        //public string Email { get; set; }
        //public string BirthDate { get; set; }
        //public string Password { get; set; }
        //public string City { get; set; }
        //public string Address { get; set; }
        //public string PostalCode { get; set; }
        //public string Currency { get; set; }
        //public string Phone { get; set; }

        //public bool AllowNewsEmail { get; set; }
        //public bool LegalAgeConfirmation { get; set; }

        //public string ValidationMessagesMetaPath = "/Metadata";
        //public Dictionary<string, string> Validate(out bool isValid)
        //{
        //    isValid = false;
        //    var errors = new Dictionary<string, string>();


        //    isValid = errors.Count > 0;
        //    return errors;
        //}
    }
}
