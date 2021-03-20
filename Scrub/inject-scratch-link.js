class ScratchLink {

    constructor(url) {
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
        })

        this.onclose();

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
        webkit.messageHandlers.rpc.postMessage(JSON.stringify(message));
    }

    handleMessage(message) {
        this.onmessage({
            data: message
        });
    }
}

ScratchLink.socketId = 0;
ScratchLink.sockets = new Map();

window.WebSocket = ScratchLink;
