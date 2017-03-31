using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.IO;
using System.Windows.Forms;
using System.Drawing;
using System.Drawing.Imaging;
using System.Text;

namespace CssSprite
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            var files = Directory.EnumerateFiles(@"F:\NewCMS\GamMatrix.CMS\images\flags\", "*.gif");

            int count = files.Count();
            int colNum = 10;
            int width = (16+4)*colNum;
            int rows = (int)Math.Ceiling(count / (colNum*1.0f));
            int height = (11+4) * rows;

            using (StreamWriter sw = new StreamWriter(@"F:\NewCMS\GamMatrix.CMS\images\flags\flags.css", false, Encoding.UTF8))
            {
                
                using (Bitmap bmp = new Bitmap(width, height, PixelFormat.Format24bppRgb))
                {
                    using (Graphics graph = Graphics.FromImage(bmp))
                    {
                        graph.FillRectangle(new SolidBrush(Color.White), 0, 0, width, height);

                        int index = 0;
                        foreach (string file in files)
                        {
                            int x = (index % colNum) * (16 + 4) + 2;
                            int y = (index / colNum) * (11 + 4) + 2;
                            using (Image image = Image.FromFile(file))
                            {
                                graph.DrawImage(image, new Point(x, y));
                            }

                            index++;

                            sw.WriteLine(string.Format(".country-flags .{0} {{ background:url(\"/images/flags/flags_sprite.png\") no-repeat -{1}px -{2}px; }}"
                                , Path.GetFileNameWithoutExtension(file)
                                , x
                                , y
                                )
                                );
                        }
                    }
                    bmp.Save(@"F:\NewCMS\GamMatrix.CMS\images\flags\flags_sprite.png", ImageFormat.Png);
                    sw.Flush();
                }
            }
        }
    }
}
