# D2HTTPSocket
Extended flash socket implementing a basic version of the HTTP protocol to be used in dota 2 UI.

The file that matters is D2HTTPSocket.as, an example of how to use this class can be found in sockethttp.as.

# How to use:

## Importing
First of all import the class:
```actionscript
import dota2Net.D2HTTPSocket;
```

## Initialisation
Then in initialise the socket at some point, onLoaded is recommended.
Initialisation looks like this:

```javascript
var socket:D2HTTPSocket = new D2HTTPSocket(hostName:String, hostIP:String [, ignoreHeaders:Boolean = true] );
```

The constructor takes a hostName and hostIP parameter which are for example 'someDomain.eu' and '8.8.8.8'. Note: these are strings. Optionaly an ignoreHeaders parameter can be supplied, which determines if HTTP headers are stripped from response messages (also see **Callback format**). This is true by default.

The socket is persistent as long as your UI exists, so should probably be saved in an instance variable.

### GET Request
GET requests are requests for data at some URL that do not send any data with the request except for parameters in the URL. These requests can be used to retrieve data from a location. These requests are doen asynchronously, so a callback should be provided to handle the data once it is returned.

GET request code: 
```javascript
socket.getDataAsync( path:String, callback:Function );
```

### POST Request
POST requests are commonly used for sending data to a server. This method does not include the data in the URL unlike GET requests. This request is also done asynchronously, but since POST requests are done for transmitting it is optional. It is however recommended to also handle the returns for these requests, so you can check if the request was successful.

POST request code: 
```javascript
socket.postDataAsync( path:String, data:String [, callback:Function] );
```

## Callback format
After a request returns a callback is called. This callback should be in the following format:
```javascript
function callback( statusCode:int, data:String ) {
  /* do something here, for example:
  if (statusCode == 200) {
    //success! Do something
  } else {
    //error happened...
  } */
}
```

The statuscode can be used to do a fast check if the request was successful or not (200 is success, read up on HTTP status codes). The data parameter contains the data returned by the request. By default the headers are stripped from this, unless configured otherwise (see **Initialisation**).
