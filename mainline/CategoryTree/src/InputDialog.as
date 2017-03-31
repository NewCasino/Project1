package
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.TitleWindow;
	import mx.controls.Button;
	import mx.controls.TextInput;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	public class InputDialog extends TitleWindow
	{
		public var m_pfnCallback : Function = null;
		private var m_oTextEditor : TextInput = new TextInput();
		public function InputDialog()
		{
			super();
			
			this.addEventListener(FlexEvent.CREATION_COMPLETE, this.onCreateComplete);
		}
		private function onCreateComplete(evt:Event) : void{
			this.title = "Please input the name below";
			this.width = 300;
			this.height = 120;
			this.showCloseButton = true;
			this.layout = "absolute";
			this.addEventListener(CloseEvent.CLOSE, this.onCloseClick);
			
			this.addElement(m_oTextEditor);
			m_oTextEditor.top = 10;
			m_oTextEditor.horizontalCenter = 0;
			m_oTextEditor.width = 250;
			
			var button : Button = new Button();
			button.label = "OK";
			button.horizontalCenter = 0;
			button.bottom = 10;
			this.addElement(button);
			
			button.addEventListener(MouseEvent.CLICK, this.onBtnOkClick);
			this.stage.focus = m_oTextEditor;
		}
		
		private function onCloseClick(evt:CloseEvent) : void{
			PopUpManager.removePopUp(this);
		}
		
		private function onBtnOkClick(evt:MouseEvent) : void{
			if( m_oTextEditor.text.length == 0 )
				return;
			m_pfnCallback(m_oTextEditor.text);
			PopUpManager.removePopUp(this);
		}
	}
}