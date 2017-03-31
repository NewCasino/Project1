namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class UserFlowStatusViewModel
	{
		public int FlowSteps = 3;
		public int CurrentStep = 0;
		public int DisplayStep { get { return CurrentStep + 1; } }

		public string HasOpen(int step, string property)
		{
			return step <= CurrentStep ? property : string.Empty;
		}

		public string HasCheck(int step, string property)
		{
			return step < CurrentStep ? property : string.Empty;
		}

		public string IntervalPos(int step, string propFirst, string propMid, string propLast)
		{
			if (step == 0)
				return propFirst;
			if (step == FlowSteps - 1)
				return propLast;
			return propMid;
		}
	}
}
