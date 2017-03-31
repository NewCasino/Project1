package
{
	import flash.xml.XMLNode;
	
	import mx.collections.CursorBookmark;
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.collections.IViewCursor;
	import mx.collections.XMLListCollection;
	import mx.controls.treeClasses.DefaultDataDescriptor;
	import mx.controls.treeClasses.ITreeDataDescriptor;

	
	public class CustomTreeDataDescriptor extends DefaultDataDescriptor 
	{
		private var m_pfnFilter:Function;
		public function CustomTreeDataDescriptor(filterFunction:Function)
		{
			super();
			m_pfnFilter = filterFunction;
		}
		
		public override function getChildren(node:Object, model:Object=null):ICollectionView
		{
			var coll : XMLListCollection = super.getChildren( node, model) as XMLListCollection;
			
			for( var i : int = coll.length - 1; i >= 0; i--){
				var child : XML = coll[i];
				if( child.@isBranch != "true" )
				{
					if( !m_pfnFilter(child) )
						coll.removeItemAt(i);
				}
			}

			return coll;
		}
		
		
		
		
	}
}