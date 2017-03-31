using System;
using System.Collections;
using System.Collections.Generic;
using System.Web.Mvc;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class DateSelectorView
	{
		public DateTime SelectedDate { private get; set; }

		public DateSelectorView(){}
		public DateSelectorView(DateTime selectedDate) 
		{
			SelectedDate = selectedDate;
		}

		public SelectList GetDayList(string selectLabel)
		{
			Dictionary<string, string> list = new Dictionary<string, string>();
			list.Add(string.Empty, selectLabel);
			for (int i = 1; i <= 31; i++)
			{
				list.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
			}

			return CreateDateFieldSelect(list, SelectedDate.Day);
		}

		public SelectList GetMonthList(string selectLabel)
		{
			Dictionary<string, string> list = new Dictionary<string, string>();
			list.Add(string.Empty, selectLabel);
			for (int i = 1; i <= 12; i++)
			{
				list.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
			}

			return CreateDateFieldSelect(list, SelectedDate.Month);
		}

		public SelectList GetYearList(string selectLabel)
		{
			return GetYearList(selectLabel, DateTime.Now.Year - 17, 1900);
		}

		public SelectList GetYearList(string selectLabel, int timeSpan)
		{
			return GetYearList(selectLabel, DateTime.Now.Year, DateTime.Now.Year - timeSpan);
		}

		private SelectList GetYearList(string selectLabel, int fromYear, int toYear)
		{
			Dictionary<string, string> list = new Dictionary<string, string>();
			list.Add(string.Empty, selectLabel);
			for (int i = fromYear; i >= toYear; i--)
			{
				list.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
			}

			return CreateDateFieldSelect(list, SelectedDate.Year);
		}

		private SelectList CreateDateFieldSelect(IEnumerable values, int selectedValue)
		{
			if (SelectedDate != default(DateTime))
				return new SelectList(values, "Key", "Value", string.Format("{0:00}", selectedValue));
			return new SelectList(values, "Key", "Value");
		}
	}
}
