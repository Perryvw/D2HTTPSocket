/*
Implementation of a basic version of the HTTP protocol, allowing POST
and GET requests to a webserver from within the dota 2 UI. All data is
returned asynchronously.

Author: Perry
*/
package {
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
		private var currentJob:Function;
		private var isConnected:Boolean = false;
		private var checkProgress:Boolean = false;
		private var responseMsg:String = "";
		private var callback:Function = null;
		
		private var path:String;
		private var data:String;
		
		
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
		public function postDataAsync( path:String, data:String, callback:Function = null ) : void {
			//connect
			trace('opening socket');
			connect( hostIP, port );
			
			this.path = path;
			this.data = data;
			this.callback = callback;
			
			//check if the socket is connected
			addEventListener(Event.CONNECT, postDataCallback);
		}
		
		//Send a GET request for some data
		public function getDataAsync( path:String, callback:Function ) : void {
			//connect
			connect( hostIP, port );
			
			this.path = path;
			this.callback = callback;
			
			//check if the socket is connected
			addEventListener(Event.CONNECT, getDataCallback);
		}
		
		//====== PRIVATE SECTION - INTERNAL WORKINGS ===========
		private function postDataCallback() : void {
			removeEventListener(Event.CONNECT, postDataCallback);
			
			//reset response message
			responseMsg = "";
			//check progress on the response
			checkProgress = true;
			
			//Write data to socket
			writeStrToSocket("POST /"+path+" HTTP/1.0\r\n");
			writeStrToSocket("Host: "+hostName+"\r\n");
			writeStrToSocket("Content-Type: text/plain\r\n");
			writeStrToSocket("Content-Length: "+data.length+"\r\n\r\n");
			writeStrToSocket(data);
			flush();
		}
		
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
					if (callback) {
						//check if we got a correct response
						var statusCode = parseInt(responseMsg.split("\r\n")[0].split(" ")[1]);
						
						var msg:String = responseMsg.substr(responseMsg.indexOf("\r\n\r\n")+4);
						
						//call the callback with the status and the
						//response message
						callback( statusCode, msg );
					}
				} else {
					//if there is data available, read it
					readSocket();
				}
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