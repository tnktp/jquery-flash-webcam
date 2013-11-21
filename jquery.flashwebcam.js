(function($) {
    $.fn.webcam = function(options) {
        var opts = $.extend({}, $.fn.webcam.defaults, options);
        return this.each(function() {
            opts.id = this.id;
            $.webcam.id = opts.id;
            $.webcam.onWebcamReady = opts.onWebcamReady;
            $.webcam.onRecording = opts.onRecording;
            $.webcam.onStop = opts.onStop;
            $.webcam.onPlaying = opts.onPlaying;
            $.webcam.onPlaybackEnded = opts.onPlaybackEnded;
            $.webcam.onConnected = opts.onConnected;
            $.webcam.onDisconnected = opts.onDisconnected;
            $.webcam.width = opts.width;
            $.webcam.height = opts.height;
            $.webcam.serverUrl = opts.serverUrl;
            $.webcam.videoName = opts.videoName;
            $.webcam.status = 'waiting';
            $.webcam.swfLocation = opts.swfLocation;
            $.webcam.startRecording = function() {
                this.status = 'recording';
                this.onRecording();
            };
            $.webcam.stopRecording = function() {
                this.status = 'stop';
                this.onStop();
            };
            $.webcam.playRecording = function () {
                this.status = 'play';
                this.onPlaying();
            };

            populateObject(opts);
            $(this).width(opts.width).height(opts.height);
        });

        function populateObject(data) {
            var objectHtml = '<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" \
                                id="' + data.id + '" width="' + data.width + '" height="' + data.height + '" \
                                codebase="http://fpdownload.macromedia.com/get/flashplayer/current/swflash.cab">\
                                    <param name="movie" value="' + data.swfLocation + '" />\
                                    <param name="quality" value="high" />\
                                    <param name="allowScriptAccess" value="always" />\
                                    <embed src="' + data.swfLocation + '" quality="high" bgcolor="#000000" \
                                        width="' + data.width + '" height="' + data.height + '" \
                                        name="webmediacapture" align="middle" \
                                        play="true" \
                                        loop="false" \
                                        quality="high" \
                                        allowScriptAccess="always" \
                                        type="application/x-shockwave-flash" \
                                        pluginspage="http://www.adobe.com/go/getflashplayer">\
                                    </embed>\
                              </object>'
            console.log(objectHtml);
            $('#' + data.id).replaceWith(objectHtml);
        }
    }

    $.webcam = {};

    $.fn.webcam.defaults = {
        onWebcamReady: function() {},
        onRecording: function() {},
        onStop: function() {},
        onPlaying: function() {},
        onPlaybackEnded: function() {},
        onConnected: function() {},
        onDisconnected: function() {},
        width: 640,
        height: 480,
        serverUrl: 'rtmp://rtmp.server/myapp',
        swfLocation: 'WebMedia.swf'
    };
}(jQuery));

function videoObject(id) {
    return document.getElementById(id);
}

function flashReady() {
    $.webcam.onWebcamReady();
}

function serverConnected() {
    $.webcam.onConnected();
}

function serverDisconnected() {
    $.webcam.onDisconnected();
}

function getServer() {
    return $.webcam.serverUrl;
}

function getWidth() {
    return $.webcam.width;
}

function getHeight() {
    return $.webcam.height;
}

function getStatus() {
    return $.webcam.status;
}

function playbackEnded() {
    $.webcam.onPlaybackEnded();
    $.webcam.status = 'stop';
}

function movieName() {
    return $.webcam.videoName;
}
