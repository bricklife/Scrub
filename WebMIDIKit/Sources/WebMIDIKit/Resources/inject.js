class MIDIInputMap extends Map { }

class MIDIOutputMap extends Map { }

class MIDIAccess extends EventTarget {

    #onstatechange = null;

    constructor(sysexEnabled) {
        super();
        this.sysexEnabled = sysexEnabled;
        this.allPorts = new Map();
    }

    get inputs() {
        return new MIDIInputMap([...this.allPorts].filter(([id, port]) => {
            return port.type == 'input' && port.state == 'connected'
        }));
    }

    get outputs() {
        return new MIDIOutputMap([...this.allPorts].filter(([id, port]) => {
            return port.type == 'output' && port.state == 'connected'
        }));
    }

    set onstatechange(value) {
        this.#onstatechange = value;
    }

    get onstatechange() {
        return this.#onstatechange;
    }

    dispatchEvent(evt) {
        super.dispatchEvent(evt);

        if (evt.type === 'statechange') {
            if (typeof this.#onstatechange == 'function') {
                this.#onstatechange(evt);
            }
        }
    }
}

class MIDIPort extends EventTarget {

    #onstatechange = null;

    constructor(properties) {
        super();
        this.id = properties.id;
        this.manufacturer = properties.manufacturer ?? null;
        this.name = properties.name ?? null;
        this.type = properties.type ?? null;
        this.version = null;
        this.state = properties.state ?? 'disconnected';
        this.connection = properties.connection ?? 'closed';
    }

    set onstatechange(value) {
        this.#onstatechange = value;
    }

    get onstatechange() {
        return this.#onstatechange;
    }

    dispatchEvent(evt) {
        super.dispatchEvent(evt);

        if (evt.type === 'statechange') {
            if (typeof this.#onstatechange == 'function') {
                this.#onstatechange(evt);
            }
        }
    }

    _openDevice() { }

    open() {
        if (this.connection == 'open') {
            return Promise.resolve(this);
        }

        if (this.connection == 'pending') {
            return Promise.resolve(this);
        }

        if (this.state == 'disconnected') {
            this.connection = 'pending';
            this.dispatchEvent(new MIDIConnectionEvent(this));
            return Promise.resolve(this);
        }

        this._openDevice();

        this.connection = 'open';
        this.dispatchEvent(new MIDIConnectionEvent(this));
        return Promise.resolve(this);
    }

    _closeDevice() { }

    close() {
        if (this.connection == 'closed') {
            return Promise.resolve(this);
        }

        this._closeDevice();

        this.connection = 'closed`';
        this.dispatchEvent(new MIDIConnectionEvent(this));
        return Promise.resolve(this);
    }
}

class MIDIInput extends MIDIPort {

    #onmidimessage = null;

    constructor(properties) {
        super(properties);

        this.type = 'input';
    }

    set onmidimessage(value) {
        this.#onmidimessage = value;
        this.open();
    }

    get onmidimessage() {
        return this.#onmidimessage;
    }

    addEventListener(type, listener, options = null) {
        if (options) {
            super.addEventListener(type, listener, options);
        } else {
            super.addEventListener(type, listener);
        }

        if (type == 'midimessage') {
            this.open();
        }
    }

    dispatchEvent(evt) {
        super.dispatchEvent(evt);

        if (evt.type === 'midimessage') {
            if (typeof this.#onmidimessage == 'function') {
                this.#onmidimessage(evt);
            }
        }
    }

    _openDevice() {
        webkit.messageHandlers.connectMIDIInput.postMessage({ id: this.id });
    }

}

class MIDIOutput extends MIDIPort {

    constructor(properties) {
        super(properties);

        this.type = 'output';
    }

    _closeDevice() {
        this.clear();
    }

    send(data, timestamp = null) {
        if (this.state == 'disconnected') {
            throw new DOMException('', 'InvalidStateError');
        }

        if (this.connection == 'closed') {
            this.open();
        }

        webkit.messageHandlers.sendMIDIMessage.postMessage({ id: this.id, data: Array.from(data), timeStamp: timestamp, now: window.performance.now() });
    }

    clear() {
        webkit.messageHandlers.clearMIDIOutput.postMessage({ id: this.id });
    }
}

class MIDIMessageEvent extends Event {

    constructor(data) {
        super('midimessage');
        this.data = data;
    }
}

class MIDIConnectionEvent extends Event {

    constructor(port) {
        super('statechange');
        this.port = port;
    }
}

class WebMIDIKit {

    static coordinator = new class extends EventTarget {

        #requestId = 0;
        #requests = new Map();

        requestMIDIAccess() {
            const requestId = this.#requestId;
            this.#requestId += 1;

            const promise = new Promise((resolve) => {
                this.#requests.set(requestId, resolve);
            });
            webkit.messageHandlers.requestMIDIAccess.postMessage({ requestId: requestId });

            return promise;
        }

        responseMIDIAccess(requestId, inputs, outputs) {
            const resolve = this.#requests.get(requestId);
            if (resolve) {
                this.#requests.delete(requestId);

                const midiAccess = new MIDIAccess(true);

                for (const properties of inputs) {
                    const input = new MIDIInput(properties);
                    this._setupMIDIPort(input, midiAccess);
                    midiAccess.allPorts.set(input.id, input);
                }
                for (const properties of outputs) {
                    const output = new MIDIOutput(properties);
                    this._setupMIDIPort(output, midiAccess);
                    midiAccess.allPorts.set(output.id, output);
                }

                const weakMidiAccess = new WeakRef(midiAccess);
                this.addEventListener('receiveMIDIConnection', (event) => {
                    const midiAccess = weakMidiAccess.deref();
                    if (midiAccess === undefined) { return }
                    let port = event.port;
                    if (!midiAccess.allPorts.has(port.id)) {
                        this._setupMIDIPort(port, midiAccess);
                        midiAccess.allPorts.set(port.id, port);
                        port.dispatchEvent(new MIDIConnectionEvent(port));
                    }
                });

                resolve(midiAccess);
            }
        }

        _setupMIDIPort(port, midiAccess) {
            const weakMidiAccess = new WeakRef(midiAccess);
            port.addEventListener('statechange', (event) => {
                setTimeout(() => {
                    weakMidiAccess.deref()?.dispatchEvent(event);
                }, 0);
            });

            const weakPort = new WeakRef(port);
            this.addEventListener('receiveMIDIConnection', (event) => {
                const port = weakPort.deref();
                if (port && port.id == event.port.id) {
                    if (event.port.state == 'disconnected' && port.connection == 'open') {
                        port.connection = 'pending';
                    }
                    if (event.port.state == 'connected' && port.connection == 'pending') {
                        port.connection = 'open';
                    }
                    port.state = event.port.state;
                    port.dispatchEvent(new MIDIConnectionEvent(port));
                }
            });

            if (port.type == 'input') {
                this.addEventListener('receiveMIDIMessage', (event) => {
                    const input = weakPort.deref();
                    if (input && input.id == event.id && input.connection == 'open') {
                        input.dispatchEvent(new MIDIMessageEvent(event.data));
                    }
                });
            }
        }

        receiveMIDIConnection(properties) {
            if (properties.type == 'input') {
                const event = new Event('receiveMIDIConnection');
                event.port = new MIDIInput(properties);
                this.dispatchEvent(event);
            }
            if (properties.type == 'output') {
                const event = new Event('receiveMIDIConnection');
                event.port = new MIDIOutput(properties);
                this.dispatchEvent(event);
            }
        }

        receiveMIDIMessage(id, data, delay) {
            const event = new Event('receiveMIDIMessage');
            event.id = id;
            event.data = Uint8Array.from(data);
            if (delay) {
                event.timeStamp = window.performance.now() + delay;
            }
            this.dispatchEvent(event);
        }
    }();
}

window.navigator.requestMIDIAccess = (options) => {
    return WebMIDIKit.coordinator.requestMIDIAccess();
};
