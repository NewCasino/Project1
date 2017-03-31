<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.UserFlowStatusViewModel>" %>

<ul id="CircleProgress" class="CircleWrapper Cols-<%= this.Model.FlowSteps %> DepositProgress Step<%= this.Model.DisplayStep%>">
<%
	for (int step = 0; step < this.Model.FlowSteps; step++)
	{
%>
	<li class="Col <%= this.Model.IntervalPos(step, "FirstCol", "MiddleCol", "LastCol")%> <%= this.Model.HasOpen(step, "ActiveCol") %>">
		<div class="CircleDiv <%= this.Model.IntervalPos(step, "First", "", "Last")%> <%= this.Model.HasCheck(step, "HasCheck") %>">Step <%= this.Model.DisplayStep %></div>
	</li>
<%
	}
%>
	<li class="ProgressLoading ">
		<div class="ProgressBar">
			<span class="expand"></span>
		</div>
	</li>
</ul>