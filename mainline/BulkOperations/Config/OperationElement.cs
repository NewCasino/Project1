using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BulkOperations.Operations;

namespace BulkOperations.Config
{
	public abstract class OperationElement : ConfigurationElement
	{
		private OperationBase Operation;
		

		[ConfigurationProperty("type", IsRequired = true)]
		public string Type
		{
			get
			{
				return (string)this["type"];
			}
		}


		public OperationBase GetOperation()
		{
			if (Operation == null)
				Operation = CreateOperation();
			return Operation;
		}

		public void ProxyDeserializeElement(System.Xml.XmlReader reader, bool serializeCollectionKey)
		{
			DeserializeElement(reader, serializeCollectionKey);
		}


		protected abstract OperationBase CreateOperation();
	}
}
