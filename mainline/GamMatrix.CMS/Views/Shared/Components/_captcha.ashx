<%@ WebHandler Language="C#" Class="_captcha" %>

using System;
using System.IO;
using System.Text;
using System.Drawing;
using System.Drawing.Imaging;
using System.Web;
using System.Web.Caching;
using System.Web.SessionState;


public class _captcha : IHttpHandler, IRequiresSessionState{

    private const string LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private const float PI2 = 6.283185307179586476925286766559f;
    private const int LETTER_COUNT = 6;
    private const int IMAGE_WIDTH = 300;
    private const int IMAGE_HEIGHT = 60;
    private const int NOISE_NUM = 2000;
    private const int LINE_NUM = 16;
   
    
    public void ProcessRequest (HttpContext context) {
        ProfileCommon.Current.Init(context);
        context.Response.Clear();
        context.Response.ClearHeaders();
        context.Response.ContentType = "image/jpeg";
        context.Response.AddHeader("Cache-Control", "no-cache, must-revalidate");
        context.Response.AddHeader("Expires", "Mon, 26 Jul 1997 05:00:00 GMT");

        GenerateImage(context.Response);

        context.Response.Flush();
        context.Response.End();
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

    private void GenerateImage(HttpResponse response)
    {
        Random random = new Random();
        using (MemoryStream ms = new MemoryStream())
        {
            using (Bitmap image = new Bitmap(IMAGE_WIDTH, IMAGE_HEIGHT, PixelFormat.Format32bppArgb))
            {
                using (Graphics graph = Graphics.FromImage(image))
                {
                    graph.FillRectangle(new SolidBrush(Color.FromArgb(0x80, 0xDD, 0xDD, 0xDD)), 0, 0, IMAGE_WIDTH, IMAGE_HEIGHT);
                    
                    using( Image text = GetTextImage())
                    {
                        graph.DrawImage(text, new Point());
                    }

                    for (int i = 0; i < NOISE_NUM; i++)
                    {
                        int color = random.Next(0, 0x66);
                        int x = random.Next( 0, IMAGE_WIDTH);
                        int y = random.Next( 0, IMAGE_HEIGHT);
                        graph.FillPie(new SolidBrush(Color.FromArgb(color, color, color))
                        , new Rectangle(x, y, 2, 2)
                        , 0
                        , PI2
                        );
                    }

                    for (int i = 0; i < LINE_NUM; i++)
                    {
                        int color = random.Next(0, 0x66);
                        int x1 = random.Next(0, IMAGE_WIDTH);
                        int y1 = random.Next(0, IMAGE_HEIGHT);
                        int x2 = random.Next(0, IMAGE_WIDTH);
                        int y2 = random.Next(0, IMAGE_HEIGHT);

                        graph.DrawLine(new Pen(Color.FromArgb(color, color, color))
                            , x1
                            , y1
                            , x2
                            , y2
                            );
                    }

                    graph.DrawRectangle(new Pen(Color.Black), new Rectangle(0, 0, IMAGE_WIDTH -1, IMAGE_HEIGHT -1));
                }

                image.Save(ms, ImageFormat.Jpeg);
            }
            response.BinaryWrite(ms.ToArray());
            
        }
    }

    private Image GetTextImage()
    {
        Random random = new Random();
        StringBuilder result = new StringBuilder();
        using (Bitmap text = new Bitmap(IMAGE_WIDTH, IMAGE_HEIGHT, PixelFormat.Format32bppArgb))
        {
            using (Graphics graph = Graphics.FromImage(text))
            {
                using (Font font = new Font(FontFamily.GenericSerif, 42, FontStyle.Bold, GraphicsUnit.Pixel))
                {
                    for (int i = 0; i < LETTER_COUNT; i++)
                    {
                        int color = random.Next(0, 0x66);
                        result.Append(LETTERS.Substring(random.Next(0, LETTERS.Length - 1), 1));
                        graph.DrawString(result[result.Length - 1].ToString()
                            , font
                            , new SolidBrush(Color.FromArgb(color, color, color))
                            , i * (int)Math.Ceiling((IMAGE_WIDTH - 10) / (LETTER_COUNT * 1.0M)) + 5
                            , random.Next(0, 15)
                            );
                    }
                }
            }

            ProfileCommon.Current.Set("captcha", result.ToString());

            return TwistImage(text, true, random.Next(5, 15), 113);
        }
    }

    private Bitmap TwistImage(Bitmap srcBmp, bool bXDir, double dMultValue, double dPhase)
    {
        Bitmap destBmp = new Bitmap(srcBmp.Width, srcBmp.Height);



        double dBaseAxisLen = bXDir ? (double)destBmp.Height : (double)destBmp.Width;

        for (int i = 0; i < destBmp.Width; i++)
        {
            for (int j = 0; j < destBmp.Height; j++)
            {
                double dx = 0;
                dx = bXDir ? (PI2 * (double)j) / dBaseAxisLen : (PI2 * (double)i) / dBaseAxisLen;
                dx += dPhase;
                double dy = Math.Sin(dx);

                int nOldX = 0, nOldY = 0;
                nOldX = bXDir ? i + (int)(dy * dMultValue) : i;
                nOldY = bXDir ? j : j + (int)(dy * dMultValue);

                Color color = srcBmp.GetPixel(i, j);
                if (nOldX >= 0 && nOldX < destBmp.Width
                 && nOldY >= 0 && nOldY < destBmp.Height)
                {
                    destBmp.SetPixel(nOldX, nOldY, color);
                }
            }
        }

        return destBmp;
    }

}