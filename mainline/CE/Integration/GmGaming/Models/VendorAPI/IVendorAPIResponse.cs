namespace CE.Integration.GmGaming.Models.VendorAPI
{
   public interface IVendorAPIResponse
    {
        bool Success { get; set; }

        string VendorError { get; set; }
        
        string GICError { get; set; }

        string Message { get; set; }
    }
}
