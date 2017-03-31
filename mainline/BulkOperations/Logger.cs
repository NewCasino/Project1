using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations
{
	public class Logger : ILogger, IDisposable
	{
		private TextWriter TextWriter;

		public Logger()
		{
			TextWriter = File.CreateText(string.Format(".\\log_{0}.txt", DateTime.Now.ToString("yyyyMMddHHmmss")));
			TextWriter.WriteLine("Log created at {0}", DateTime.Now);
		}

		public void Log(string message)
		{
			Console.WriteLine(message);
			TextWriter.WriteLine(message);
		}

		public void Dispose()
		{
			TextWriter.Dispose();
		}
	}
}
