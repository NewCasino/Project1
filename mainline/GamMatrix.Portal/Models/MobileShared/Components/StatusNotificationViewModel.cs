using System;
using GamMatrix.CMS.Models.Common.Base;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public enum StatusType { Success, Warning, Error, Info }

	public class StatusNotificationViewModel : MultiuseView
	{
		public StatusType Status { get; private set; }
		public string Message { get; private set; }
		public bool IsHtml { get; set; }

		public StatusNotificationViewModel(StatusType status, string message)
		{
			Status = status;
			Message = message;
		}

		public string GetStatusProperty(string postfix)
		{
			return Enum.GetName(typeof(StatusType), Status) + postfix;
		}
	}
}
