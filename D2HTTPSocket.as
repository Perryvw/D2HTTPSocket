/*
Implementation of a basic version of the HTTP protocol, allowing POST
and GET requests to a webserver from within the dota 2 UI. All data is
returned asynchronously.

Update: Now contains a queueing system that will accept requests even when
the callback of the previous request has not fired yet.

Author: Perry
Contributors: BMD
*/
package dota2Net {
	import flash.net.Socket;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.ProgressEvent;

	public class D2HTTPSocket extends Socket {
		//public settings
		public var ignoreHeaders:Boolean;
		
		//host name and IP
		private var hostName:String;
		private var hostIP:String;
		
		//default http port
		private var port:int = 80;
		
		//internal variables
		private var currentJob:Object = null;
		private var isConnected:Boolean = false;
		private var checkProgress:Boolean = false;
		private var responseMsg:String = "";
		private var callback:Function = null;
		
		private var path:String;
		private var data:String;
		private var postContentType:String;
		
		private var TYPE_POST:int = 1;
		private var TYPE_GET:int = 2;
		private var httpQueue:Array = new Array();
		
		
		//===========PUBLIC SECTION - INTERFACE ============
		//constructor
		public function D2HTTPSocket( hostname:String, hostip:String, ignoreHeaders:Boolean = true ) : void {
			super();
			this.hostName = hostname;
			this.hostIP = hostip;
			
			this.ignoreHeaders = ignoreHeaders;
			
			//register events
			//addEventListener(Event.CONNECT, onConnected);
			addEventListener(ProgressEvent.SOCKET_DATA, onProgressed);
		}
		
		//Send a POST request with some data to the specified path
		//Parameters:	path:String - The path of the page to send the request to
		//				data:String - The data to send with the POST request
		//				callback:Function - Callback that is executed once data is returned (optional but recommended)
		//				contentType:String - The Content-Type header to be used (optional)
		public function postDataAsync( path:String, data:String, callback:Function = null, contentType:String = 'application/x-www-form-urlencoded' ) : void {
			if (this.currentJob != null){
				httpQueue.push({"type":TYPE_POST, "path":path, "data":data, "callback":callback, "contentType":contentType});
				return;
			}
			
			//connect
			this.currentJob = {"type":TYPE_POST, "path":path, "data":data, "callback":callback, "contentType":contentType};
			connect( hostIP, port );
			
			this.path = path;
			this.data = data;
			this.postContentType = contentType;
			this.callback = callback;
			
			//check if the socket is connected
			addEventListener(Event.CONNECT, postDataCallback);
		}
		
		//Send a GET request for some data
		//Parameters:	path:String - The path of the page to send the request to
		//				callback:Function - Callback that is executed once data is returned
		public function getDataAsync( path:String, callback:Function ) : void {
			if (this.currentJob != null){
				httpQueue.push({"type":TYPE_GET, "path":path, "data":null, "callback":callback});
				return;
			}
			
			//connect
			this.currentJob = {"type":TYPE_GET, "path":path, "data":null, "callback":callback};
			connect( hostIP, port );
			
			this.path = path;
			this.callback = callback;
			
			//check if the socket is connected
			addEventListener(Event.CONNECT, getDataCallback);
		}
		
		//====== PRIVATE SECTION - INTERNAL WORKINGS ===========
		//Callback for when the socket has connected to send a POST request
		private function postDataCallback() : void {
			removeEventListener(Event.CONNECT, postDataCallback);
			
			//reset response message
			responseMsg = "";
			//check progress on the response
			checkProgress = true;
			
			//Write data to socket
			writeStrToSocket("POST /"+path+" HTTP/1.0\r\n");
			writeStrToSocket("Host: "+hostName+"\r\n");
			writeStrToSocket("Content-Type: "+postContentType+"\r\n");
			writeStrToSocket("Content-Length: "+data.length+"\r\n\r\n");
			writeStrToSocket(data);
			flush();
		}
		
		//Callback for when the socket has connected for a GET request
		private function getDataCallback() : void {
			removeEventListener(Event.CONNECT, getDataCallback);
			//reset response message
			responseMsg = "";
			//check progress on the response
			checkProgress = true;
			
			//Write data to socket
			writeStrToSocket("GET /"+path+" HTTP/1.0\r\n");
			writeStrToSocket("Host: "+hostName+"\r\n\r\n");	
			flush();
		}
		
		//Handle connection event
		private function onConnected( event:Event ) : void {
			isConnected = true;
		}
		
		//Handle progress event
		private function onProgressed( event:ProgressEvent ) : void {
			if (checkProgress) {
				//check for empty progress events
				if (event.bytesLoaded == 0) {
					//stop checking progress
					checkProgress = false;
					close();
					
					//return data to the callback if it exists
					if (callback != null) {
						//check if we got a correct response
						var statusCode = parseInt(responseMsg.split("\r\n")[0].split(" ")[1]);
						
						var msg:String = responseMsg.substr(responseMsg.indexOf("\r\n\r\n")+4);
						
						//call the callback with the status and the
						//response message
						callback( statusCode, msg );
					}
					
					this.currentJob = null;
					checkQueue();
				} else {
					//if there is data available, read it
					readSocket();
				}
			}
		}
		
		//Check the request-queue to see if there are any other requests that have to be made
		private function checkQueue(){
			//trace("queuelen: " + this.httpQueue.length);
			
			//No requests
			if (this.httpQueue.length == 0)
				return;
				
			//Pop the queue
			this.currentJob = this.httpQueue.shift();
			
			//Handle different types of requests
			if (this.currentJob.type == TYPE_GET){
				//connect
				connect( hostIP, port );
				
				this.path = this.currentJob.path;
				this.callback = this.currentJob.callback;
				
				//check if the socket is connected
				addEventListener(Event.CONNECT, getDataCallback);
			}
			else if (this.currentJob.type == TYPE_POST){
				//connect
				connect( hostIP, port );
				
				this.path = this.currentJob.path;
				this.data = this.currentJob.data;
				this.postContentType = this.currentJob.contentType;
				this.callback = this.currentJob.callback;
				
				//check if the socket is connected
				addEventListener(Event.CONNECT, postDataCallback);
			}
		}
		
		//Read string data from the socket
		private function readSocket() : void {
			var str:String = readUTFBytes(bytesAvailable);
			responseMsg += str;
		}
		
		//Write string data to the socket
		private function writeStrToSocket(str:String) : void {
			//Try writing data to the socket, otherwise output the error
			try {
				writeUTFBytes(str);
			}
			catch(e:IOError) {
				trace(e);
			}
		}
	}
}