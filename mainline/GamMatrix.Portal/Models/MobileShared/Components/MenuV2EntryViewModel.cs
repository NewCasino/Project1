namespace GamMatrix.CMS.Models.MobileShared.Components
{
    public class MenuV2EntryViewModel
    {
        public MenuV2EntryViewModel()
        {
            IsLinkEntry = true;
        }

        public string EntryId { get; set; }
        public string Url { get; set; }
        public string CssClass { get; set; }
        public bool IsLinkEntry { get; set; }
    }
}
