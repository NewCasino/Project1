import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.external.ExternalInterface;
import flash.net.FileReference;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.system.Security;
import flash.utils.ByteArray;

import mx.events.FlexEvent;
import mx.utils.UIDUtil;

private var m_FileReference : FileReference = null;
private var m_Key : String = null;
private var m_UrlRequest : URLRequest = null;
private var m_FileByteArray : ByteArray = null;
private var m_CurrentFilePointer : uint = 0;
private var m_UrlLoader : URLLoader = new URLLoader();
private var m_RetryTimes : int = 0;

protected function creationCompleteHandler(event:FlexEvent):void
{
	Security.allowDomain("*");
	ExternalInterface.addCallback( "startUpload", this.startUpload);
}

private function scriptEncode(text:String) : String{
	if( text == null )
		return "";
	var pattern:RegExp = new RegExp( "([^\\x00-\\x7F]|&|\\\"|'|\\<|\\>|\\n|\\r|\\t)", "g");
	return text.replace( pattern, function() : String {
		var temp : String = arguments[0].charCodeAt(0).toString(16);
		while (temp.length < 4) temp = "0" + temp;
		return "\\u" + temp;
	});
}

public function startUpload(key:String) : void {
	
	this.m_Key = key;
	m_CurrentFilePointer = 0;
	ctlProgress.setProgress( 0, 1);
	this.m_RetryTimes = 0;
	this.partialUpload();
	this.btnUpload.enabled = false;
}

private function partialUpload() : void{
	try
	{
		m_UrlRequest = new URLRequest(this.parameters["PartialUploadUrl"]);
		m_UrlRequest.contentType = "application/octet-stream";
		m_UrlRequest.method = "POST";
		
		
		var buffer : ByteArray = new ByteArray();
		var length : uint = Math.min(102400 * 10,  m_FileByteArray.length - m_CurrentFilePointer);
		m_FileByteArray.position = m_CurrentFilePointer;
		m_FileByteArray.readBytes( buffer, 0, length);
		
		m_UrlRequest.data = buffer;
		
		var ary : Array = new Array();
		ary.push( new URLRequestHeader("cmSession", this.parameters["cmSession"]));
		ary.push( new URLRequestHeader("TotalLength", m_FileByteArray.length.toString()) );
		ary.push( new URLRequestHeader("CurrentPosition", m_CurrentFilePointer.toString()) );
		ary.push( new URLRequestHeader("UploadIdentity", this.m_Key) );
		m_UrlRequest.requestHeaders = ary;
		
		m_CurrentFilePointer += length;
		
		m_UrlLoader.load(m_UrlRequest);
		m_UrlLoader.addEventListener(Event.COMPLETE, this.onUploadComplete);
		m_UrlLoader.addEventListener(IOErrorEvent.IO_ERROR, this.onIoError);
		m_UrlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onSecurityError);
	}
	catch(e:Error){
		ExternalInterface.call( "setTimeout( function() { alert(\"Error!\"); }, 0)" );
		this.btnUpload.enabled = true;
	}
}

private function onUploadComplete(evt:Event):void {
	if( m_UrlLoader.data != "OK" )
	{
		ExternalInterface.call( "setTimeout( function() { alert(\"" + scriptEncode(m_UrlLoader.data) + "\"); }, 0)" );
		this.btnUpload.enabled = true;
		return;
	}
	ctlProgress.setProgress( m_CurrentFilePointer, m_FileByteArray.length);
	if( m_CurrentFilePointer < m_FileByteArray.length ){
		this.m_RetryTimes = 0;
		this.partialUpload();		
	}
	else{
		ExternalInterface.call("self.fileManager.refresh");
		ExternalInterface.call( "setTimeout( function() { alert(\"The file has been uploaded successfully!\"); }, 0)" );
		this.btnUpload.enabled = true;
	}
}

private function onBtnUploadClick(evt:MouseEvent) : void{
	
	m_FileReference = new FileReference();
	m_FileReference.addEventListener(Event.SELECT, this.onFileSelect);
	m_FileReference.addEventListener(Event.COMPLETE, this.onLoadComplete);	
	m_FileReference.browse();
}

private function onFileSelect(evt:Event):void {
	
	m_FileReference.load();
}

private function onLoadComplete(evt:Event):void {
	var data : ByteArray = m_FileReference.data;
	if( data == null ) return;
	m_FileByteArray = data;
	ExternalInterface.call("self.prepareUpload", m_FileReference.name, data.length);
}

private function onIoError(evt:IOErrorEvent) : void{
	this.m_RetryTimes ++;
	if( this.m_RetryTimes > 3 ){
		ExternalInterface.call( "setTimeout( function() { alert(\"IoError!\"); }, 0)" );
		this.btnUpload.enabled = true;
	}
	else{
		m_CurrentFilePointer -= 102400 * 10;
		m_CurrentFilePointer = Math.max( 0, m_CurrentFilePointer);
		this.partialUpload();
	}
}

private function onSecurityError(evt:SecurityErrorEvent) : void{
	this.m_RetryTimes ++;
	if( this.m_RetryTimes > 3 ){
		ExternalInterface.call( "setTimeout( function() { alert(\"SecurityError!\"); }, 0)" );
		this.btnUpload.enabled = true;
	}
	else{
		m_CurrentFilePointer -= 102400 * 10;
		m_CurrentFilePointer = Math.max( 0, m_CurrentFilePointer);
		this.partialUpload();
	}
}
