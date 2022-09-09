class ScratchLink {

    constructor(url) {
        if (!url.startsWith('wss://device-manager.scratch.mit.edu:20110/scratch/')) {
            return new ScratchLink.WebSocket(url);
        }

        this.url = url;
        this._open();
    }

    _open() {
        this.socketId = ScratchLink.socketId;
        ScratchLink.sockets.set(ScratchLink.socketId, this);
        ScratchLink.socketId++;

        this._postMessage({
            method: 'open',
            socketId: this.socketId,
            url: this.url
        });

        setTimeout(() => {
            this.onopen();
        }, 100);
    }

    close() {
        this._postMessage({
            method: 'close',
            socketId: this.socketId
        });

        if (this.onclose) {
            this.onclose();
        }

        ScratchLink.sockets.delete(this.socketId);
    }

    send(message) {
        this._postMessage({
            method: 'send',
            socketId: this.socketId,
            jsonrpc: message
        });
    }

    _postMessage(message) {
        webkit.messageHandlers.scratchLink.postMessage(JSON.stringify(message));
    }

    handleMessage(message) {
        this.onmessage({
            data: message
        });
    }
}

ScratchLink.socketId = 0;
ScratchLink.sockets = new Map();

ScratchLink.CONNECTING = window.WebSocket.CONNECTING;
ScratchLink.OPEN = window.WebSocket.OPEN;
ScratchLink.CLOSING = window.WebSocket.CLOSING;
ScratchLink.CLOSED = window.WebSocket.CLOSED;

ScratchLink.WebSocket = window.WebSocket;
window.WebSocket = ScratchLink;
