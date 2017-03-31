using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Config
{
	public class OperationElementProxy : ConfigurationElement
	{
		public string ID { get; private set; }
		public OperationElement Nested { get; private set; }


		public OperationElementProxy()
		{
			ID = Guid.NewGuid().ToString();
		}

		
		protected override void DeserializeElement(System.Xml.XmlReader reader, bool serializeCollectionKey)
		{
			string operationTypeName = string.Format("BulkOperations.Config.Operations.{0}Settings", reader.GetAttribute("type"));
			var operationType = Assembly.GetExecutingAssembly()
				.GetTypes()
				.Where(t => string.Equals(t.FullName, operationTypeName, StringComparison.OrdinalIgnoreCase))
				.FirstOrDefault();

			Nested = (OperationElement)Activator.CreateInstance(operationType);
			Nested.ProxyDeserializeElement(reader, serializeCollectionKey);
		}
	}
}
