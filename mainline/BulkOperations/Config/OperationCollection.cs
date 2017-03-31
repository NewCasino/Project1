using System;
using System.Collections;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Config
{
	public class OperationCollection : ConfigurationElementCollection
	{
		protected override ConfigurationElement CreateNewElement()
		{
			return new OperationElementProxy();
		}

		protected override object GetElementKey(ConfigurationElement element)
		{
			return ((OperationElementProxy)element).ID;
		}

		public OperationElement this[int index]
		{
			get
			{
				return ((OperationElementProxy)BaseGet(index)).Nested;
			}
		}

		public new IEnumerator<OperationElement> GetEnumerator()
		{
			IEnumerator enumerator = base.GetEnumerator();
			while (enumerator.MoveNext())
				yield return ((OperationElementProxy)enumerator.Current).Nested;
		}
	}
}
