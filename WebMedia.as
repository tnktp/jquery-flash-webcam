package {
    import flash.external.ExternalInterface;
    import flash.display.Sprite;
    import flash.system.Security;
    import flash.utils.Timer;
    import flash.media.*;
    import flash.net.*;
    import flash.events.*;

    public class WebMedia extends Sprite {
        [Bindable] private var nc:NetConnection;
        [Bindable] private var ns:NetStream;
        private var serverUrl:String;
        private var remoteVideo:Video;
        private var currentVideo:Video;
        private var playVideo:Video;
        private var cam:Camera;
        private var camStatus:String = 'None';
        private var movName:String;
        private var videoWidth:int;
        private var videoHeight:int;

        public function WebMedia() {
            Security.allowDomain('*');
            ExternalInterface.call('console.log', 'available ' + ExternalInterface.available);

            serverUrl = ExternalInterface.call('getServer');

            debug('server ' + serverUrl);
            debug('Added');

            rtmpConnect(serverUrl);
        }

        private function rtmpConnect(url:String):void {
            NetConnection.defaultObjectEncoding = ObjectEncoding.AMF0; // MUST SUPPLY THIS!!!

            if (nc == null) {
                nc = new NetConnection();
                nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
                nc.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
                nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
                nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler, false, 0, true);
                nc.client = {};

                debug('connect() ' + url);
                nc.connect(url);
            }
        }

        private function close():void {
            debug('close()');
            if (nc != null) {
                nc.close();
                nc = null;
            }
        }

        private function publish(name:String, record:Boolean):void {
            if (ns != null && nc != null && nc.connected) {
                debug('in publish ' + name + ' ' + record);
                ns.publish(name, record ? 'record' : null);
                debug('Publishing ' + name);
            }
        }

        private function play(name:String):void {
            if (nc != null && nc.connected) {
                ns = new NetStream(nc);
                ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
                ns.addEventListener(IOErrorEvent.IO_ERROR, streamErrorHandler, false, 0, true);
                ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, streamErrorHandler, false, 0, true);
                ns.client = {};

                ns.play(name);
                playVideo.attachNetStream(ns);
                addChild(playVideo);
                currentVideo = playVideo;
                debug('Playing ' + name);
            }
        }

        private function closeStream(current:Video):void {
            if (ns != null) {
                ns.close();
                ns = null;
            }
            currentVideo.clear();
            removeChild(current);
        }

        private function netStatusHandler(event:NetStatusEvent):void {
            debug('netStatusHandler() ' + event.type + ' ' + event.info.code);
            switch (event.info.code) {
            case 'NetConnection.Connect.Success':
                debug('connected ' + nc.connected);

                videoWidth = ExternalInterface.call('getWidth');
                videoHeight = ExternalInterface.call('getHeight');
                initVideo(videoWidth, videoHeight);

                var statusTimer:Timer = new Timer(330, 0);
                statusTimer.addEventListener(TimerEvent.TIMER, pollStatus);
                statusTimer.start();
                ExternalInterface.call('serverConnected');
                break;
            case 'NetConnection.Connect.Failed':
            case 'NetConnection.Connect.Reject':
            case 'NetConnection.Connect.Closed':
                ExternalInterface.call('serverDisconnected');
                nc = null;
                break;
            case 'NetStream.Play.Stop':
                ExternalInterface.call('playbackEnded');
                closeStream(currentVideo);
                break;
            }
        }

        private function errorHandler(event:ErrorEvent):void {
            debug('errorHandler() ' + event.type + ' ' + event.text);
            if (nc != null)
                nc.close();
            nc = null;
        }

        private function streamErrorHandler(event:ErrorEvent):void {
            debug('streamErrorHandler() ' + event.type + ' ' + event.text);
        }

        private function debug(msg:String):void {
            ExternalInterface.call('console.log', msg);
        }

        private function initRecord():void {
            ns = new NetStream(nc);
            ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
            ns.addEventListener(IOErrorEvent.IO_ERROR, streamErrorHandler, false, 0, true);
            ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, streamErrorHandler, false, 0, true);
            cam = Camera.getCamera();
            cam.setMode(videoWidth, videoHeight, 25, false);
            cam.setQuality(0, 100);

            debug('width: ' + cam.width);
            debug('height: ' + cam.height);
            debug('camera: ' + cam.name);
            debug('status: ' + camStatus);

            ns.attachCamera(Camera.getCamera());
            ns.attachAudio(Microphone.getMicrophone(-1));
            remoteVideo.attachCamera(Camera.getCamera());
            addChild(remoteVideo);
            currentVideo = remoteVideo;

            var newStatus:String = ExternalInterface.call('getStatus');

            ExternalInterface.addCallback('initFlash', initVideo);
            ExternalInterface.addCallback('serverConnect', rtmpConnect);
            ExternalInterface.addCallback('startRecording', publish);
        }

        private function initVideo(w:int, h:int):void {
            remoteVideo = new Video(w, h);
            remoteVideo.width = w;
            remoteVideo.height = h;
            playVideo = new Video(w, h);
            playVideo.width = w;
            playVideo.height = h;
        }

        private function pollStatus(event:TimerEvent):void {
            var newStatus:String = ExternalInterface.call('getStatus');
            if (newStatus != camStatus) {
                debug('status changed to: ' + newStatus);
                camStatus = newStatus;
                if (newStatus == 'recording') {
                    initRecord();
                    movName = ExternalInterface.call('movieName');
                    publish(movName, true);
                }
                else if (newStatus == 'stop') {
                    closeStream(currentVideo);
                }
                else if (newStatus == 'play') {
                    movName = ExternalInterface.call('movieName');
                    play(movName);
                }
            }
        }
    }
}
