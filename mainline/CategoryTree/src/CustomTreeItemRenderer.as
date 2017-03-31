package
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.text.TextLineMetrics;
	
	import mx.controls.Alert;
	import mx.controls.Image;
	import mx.controls.treeClasses.*;
	import mx.controls.treeClasses.TreeItemRenderer;
	import mx.core.IFlexDisplayObject;
	import mx.effects.IAbstractEffect;

	public class CustomTreeItemRenderer extends TreeItemRenderer
	{
		[Embed(source="del.png")]
		[Bindable]		
		public static var ICON_DELETE:Class; 
		
		[Embed(source="edit.png")]
		[Bindable]		
		public static var ICON_EDIT:Class; 
		
		[Embed(source="netent.png")]
		[Bindable]		
		public static var ICON_NETENT:Class; 
		
		[Embed(source="microgaming.png")]
		[Bindable]		
		public static var ICON_MICROGAMING:Class; 
		
		[Embed(source="ctxm.png")]
		[Bindable]		
		public static var ICON_CTXM:Class; 
		
		[Embed(source="igt.png")]
		[Bindable]		
		public static var ICON_IGT:Class; 
		
		[Embed(source="playngo.png")]
		[Bindable]		
		public static var ICON_PLAYNGO:Class; 

		[Embed(source="betsoft.png")]
		[Bindable]		
		public static var ICON_BETSOFT:Class; 

		[Embed(source="greentube.png")]
		[Bindable]		
		public static var ICON_GREENTUBE:Class; 

		[Embed(source="sheriff.png")]
		[Bindable]		
		public static var ICON_SHERIFF:Class; 
		
		[Embed(source="xprogaming.png")]
		[Bindable]		
		public static var ICON_XPROGAMING:Class; 
		
		[Embed(source="evolutiongaming.png")]
		[Bindable]		
		public static var ICON_EVOLUTIONGAMING:Class; 
		
		[Embed(source="nyxgaming.png")]
		[Bindable]		
		public static var ICON_NYXGAMING:Class; 

		private var deleteIcon : Image = null;
		private var editIcon : Image = null;
		public static var refreshListHandler : Function = null;
		public static var checkGameAvailable : Function = null;
		public static var disableCategoryDeleteButton : Boolean = false;
		public static var showGameEditButton : Boolean = true;

		public function CustomTreeItemRenderer()
		{
			super();
		}
		
		private function getVendorIcon() : Class {
			if( super.data != null ){

				if( super.data.@vendor != null ){
					var vendor : String = super.data.@vendor.toString();
					
					switch(vendor.toUpperCase()){
						case "NETENT":
						{
							return ICON_NETENT;
						}
							
						case "MICROGAMING":
						{
							return ICON_MICROGAMING;
						}
							
						case "CTXM":
						{
							return ICON_CTXM;
						}
							
							
						case "IGT":
						{
							return ICON_IGT;
						}
							
						case "PLAYNGO":
						{
							return ICON_PLAYNGO;
						}

						case "BETSOFT":
						{
							return ICON_BETSOFT;
						}

						case "SHERIFF":
						{
							return ICON_SHERIFF;
						}

						case "GREENTUBE":
						{
							return ICON_GREENTUBE;
						}
							
						case "XPROGAMING":
						{
							return ICON_XPROGAMING;
						}
							
						case "EVOLUTIONGAMING":
						{
							return ICON_EVOLUTIONGAMING;
						}
							
						case "NYXGAMING":
						{
							return ICON_EVOLUTIONGAMING;
						}
						default:
							break;
					}
				}
			}
			
			return null;
		}
		
		override protected function createChildren():void  
		{   
			super.createChildren();   
			

			deleteIcon = new Image();
			deleteIcon.source = ICON_DELETE;
			deleteIcon.width = 16;
			deleteIcon.height = 16;
			deleteIcon.toolTip = "Delete";
			deleteIcon.buttonMode = true;
			deleteIcon.useHandCursor = true;
			addChild( deleteIcon );   
			deleteIcon.addEventListener( MouseEvent.CLICK, this.onIconDeleteClick);  

			
			editIcon = new Image();
			editIcon.source = ICON_EDIT;
			editIcon.width = 16;
			editIcon.height = 16;
			editIcon.toolTip = "Edit the name / thumbnail and description.";
			editIcon.buttonMode = true;
			editIcon.useHandCursor = true;
			addChild( editIcon );
			editIcon.addEventListener( MouseEvent.CLICK, this.onIconEditClick);
			
			
		}   
		
		private function onIconDeleteClick(evt:MouseEvent) : void{
			evt.preventDefault();
			var xml : XML = super.data as XML;
			var parent : XML = xml.parent();
			
			
			delete parent.node[xml.childIndex()];
			if( refreshListHandler != null )
				refreshListHandler();
		}
		
		private function onIconEditClick(evt:MouseEvent) : void{
			evt.preventDefault();
			var xml : XML = super.data as XML;
			if( disableCategoryDeleteButton )
				ExternalInterface.call( "openLiveCasinoEditor", xml.@type == "category",  xml.@id.toString(), xml.@label.toString());
			else
				ExternalInterface.call( "openEditor", xml.@type == "category",  xml.@id.toString(), xml.@label.toString());
		}
		
		override protected function measure():void  
		{   
			super.measure();   
		} 
		
		override protected function commitProperties():void
		{
			if (listData && listData is TreeListData) {
				var icon : Class = getVendorIcon();
				if( icon != null )
					TreeListData(listData).icon = icon;
			}
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void  
		{   
			super.updateDisplayList(unscaledWidth, unscaledHeight);  
					
			this.deleteIcon.x = super.label.x + super.label.width - this.deleteIcon.width - 5;
			this.deleteIcon.y = super.label.y + 2;
					
			var xml : XML = super.data as XML;
			if( xml.@isBranch == "true" && disableCategoryDeleteButton ){
				this.deleteIcon.visible = false;
			}
			
			editIcon.x = deleteIcon.x - 5 - editIcon.width;
			editIcon.y = deleteIcon.y;
			
			if( xml.@isBranch == "true" || xml.@type == "category" || xml.@type == "group")
			{
				editIcon.visible = true;
				
			}
			else
			{
				editIcon.visible = showGameEditButton;
				
				if( checkGameAvailable != null && !checkGameAvailable(super.data.@id) ){
					
					super.label.setColor(0x666666);
					
					var metrics : TextLineMetrics = super.label.getLineMetrics( 0 );
					var y : int = ( metrics.ascent * 0.66 ) + 2;
					
					graphics.clear();
					graphics.lineStyle( 1, 0x666666, 1 );
					graphics.moveTo( super.label.x + 2, y );
					graphics.lineTo( super.label.x + 2 + metrics.width, y );
				}
			}
		}
		
		
	}
}