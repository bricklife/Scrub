class ScratchLinkKit {

    static coordinator = new class {

        #socketId = 0;
        #sockets = new Map();

        addSocket(socket) {
            const socketId = this.#socketId;
            this.#sockets.set(socketId, socket);
            this.#socketId += 1;
            return socketId;
        }

        deleteSocket(socketId) {
            this.#sockets.delete(socketId);
        }

        handleMessage(socketId, message) {
            const socket = this.#sockets.get(socketId);
            if (socket) {
                socket.handleMessage(message);
            }
        }
    }();

    static Socket = class {

        #type = null;
        #id = null;

        #onOpen = null;
        #onClose = null;
        #onError = null;
        #handleMessage = null;

        static isSafariHelperCompatible() {
            return true;
        }

        constructor(type) {
            this.#type = type;
        }

        _postMessage(message) {
            webkit.messageHandlers.scratchLink.postMessage(JSON.stringify(message));
        }

        open() {
            this.#id = ScratchLinkKit.coordinator.addSocket(this);

            this._postMessage({
                method: 'open',
                socketId: this.#id,
                type: this.#type
            });

            setTimeout(() => {
                this.#onOpen();
            }, 100);
        }

        isOpen() {
            return this.#id != null;
        }

        close() {
            if (this.isOpen()) {
                this._postMessage({
                    method: 'close',
                    socketId: this.#id
                });

                this.#onClose(new CloseEvent('close'));
                this.#id = null;

                ScratchLinkKit.coordinator.deleteSocket(this.#id);
            }
        }

        sendMessage(messageObject) {
            if (this.isOpen()) {
                this._postMessage({
                    method: 'send',
                    socketId: this.#id,
                    jsonrpc: JSON.stringify(messageObject)
                });
            }
        }

        setOnOpen(callback) {
            this.#onOpen = callback;
        }

        setOnClose(callback) {
            this.#onClose = callback;
        }

        setOnError(callback) {
            this.#onError = callback;
        }

        setHandleMessage(callback) {
            this.#handleMessage = callback;
        }

        handleMessage(message) {
            this.#handleMessage(JSON.parse(message));
        }
    };
}

if (document.getElementById('scratch-link-extension-script')) {
    self.Scratch = self.Scratch || {};
    self.Scratch.ScratchLinkSafariSocket = ScratchLinkKit.Socket;
}
