(() => {
    if (navigator.bluetooth) {
        return;
    }
    if (typeof webkit === 'undefined' || !webkit.messageHandlers || !webkit.messageHandlers.webBluetooth) {
        return;
    }

    const assignedServices = {
        alert_notification: 0x1811,
        automation_io: 0x1815,
        battery_service: 0x180F,
        blood_pressure: 0x1810,
        body_composition: 0x181B,
        bond_management: 0x181E,
        continuous_glucose_monitoring: 0x181F,
        current_time: 0x1805,
        cycling_power: 0x1818,
        cycling_speed_and_cadence: 0x1816,
        device_information: 0x180A,
        environmental_sensing: 0x181A,
        fitness_machine: 0x1826,
        generic_access: 0x1800,
        generic_attribute: 0x1801,
        glucose: 0x1808,
        health_thermometer: 0x1809,
        heart_rate: 0x180D,
        http_proxy: 0x1823,
        human_interface_device: 0x1812,
        immediate_alert: 0x1802,
        indoor_positioning: 0x1821,
        internet_protocol_support: 0x1820,
        link_loss: 0x1803,
        location_and_navigation: 0x1819,
        mesh_provisioning: 0x1827,
        mesh_proxy: 0x1828,
        next_dst_change: 0x1807,
        object_transfer: 0x1825,
        phone_alert_status: 0x180E,
        pulse_oximeter: 0x1822,
        reconnection_configuration: 0x1829,
        reference_time_update: 0x1806,
        running_speed_and_cadence: 0x1814,
        scan_parameters: 0x1813,
        transport_discovery: 0x1824,
        tx_power: 0x1804,
        user_data: 0x181C,
        weight_scale: 0x181D
    };

    const assignedCharacteristics = {
        aerobic_heart_rate_lower_limit: 0x2A7E,
        aerobic_heart_rate_upper_limit: 0x2A84,
        aerobic_threshold: 0x2A7F,
        age: 0x2A80,
        aggregate: 0x2A5A,
        alert_category_id: 0x2A43,
        alert_category_id_bit_mask: 0x2A42,
        alert_level: 0x2A06,
        alert_notification_control_point: 0x2A44,
        alert_status: 0x2A3F,
        battery_level: 0x2A19,
        battery_level_state: 0x2A1B,
        battery_power_state: 0x2A1A,
        blood_pressure_feature: 0x2A49,
        blood_pressure_measurement: 0x2A35,
        body_sensor_location: 0x2A38,
        csc_feature: 0x2A5C,
        csc_measurement: 0x2A5B,
        current_time: 0x2A2B,
        firmware_revision_string: 0x2A26,
        'gap.appearance': 0x2A01,
        'gap.device_name': 0x2A00,
        'gatt.service_changed': 0x2A05,
        hardware_revision_string: 0x2A27,
        heart_rate_control_point: 0x2A39,
        heart_rate_measurement: 0x2A37,
        hid_control_point: 0x2A4C,
        hid_information: 0x2A4A,
        humidity: 0x2A6F,
        ieee_11073_20601_regulatory_certification_data_list: 0x2A2A,
        'ieee_11073-20601_regulatory_certification_data_list': 0x2A2A,
        manufacturer_name_string: 0x2A29,
        model_number_string: 0x2A24,
        pnp_id: 0x2A50,
        pressure: 0x2A6D,
        protocol_mode: 0x2A4E,
        report: 0x2A4D,
        report_map: 0x2A4B,
        rsc_feature: 0x2A54,
        rsc_measurement: 0x2A53,
        sensor_location: 0x2A5D,
        serial_number_string: 0x2A25,
        software_revision_string: 0x2A28,
        system_id: 0x2A23,
        temperature: 0x2A6E,
        temperature_measurement: 0x2A1C,
        temperature_type: 0x2A1D,
        tx_power_level: 0x2A07
    };

    const assignedDescriptors = {
        'gatt.characteristic_extended_properties': 0x2900,
        'gatt.characteristic_user_description': 0x2901,
        'gatt.client_characteristic_configuration': 0x2902,
        'gatt.server_characteristic_configuration': 0x2903,
        'gatt.characteristic_presentation_format': 0x2904,
        'gatt.characteristic_aggregate_format': 0x2905,
        valid_range: 0x2906,
        external_report_reference: 0x2907,
        report_reference: 0x2908
    };

    const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

    function canonicalUUID(alias) {
        const value = Number(alias);
        if (!Number.isInteger(value) || value < 0) {
            throw new TypeError('Invalid UUID alias');
        }
        const hex = value.toString(16).padStart(8, '0');
        return `${hex}-0000-1000-8000-00805f9b34fb`;
    }

    function resolveUUID(name, table) {
        if (typeof name === 'number') {
            return canonicalUUID(name);
        }
        if (typeof name !== 'string') {
            throw new TypeError('Invalid UUID');
        }
        const lowered = name.toLowerCase();
        if (uuidPattern.test(lowered)) {
            return lowered;
        }
        if (Object.prototype.hasOwnProperty.call(table, name)) {
            return canonicalUUID(table[name]);
        }
        throw new TypeError(`Invalid UUID name: ${name}`);
    }

    const BluetoothUUID = {
        canonicalUUID,
        getService(name) { return resolveUUID(name, assignedServices); },
        getCharacteristic(name) { return resolveUUID(name, assignedCharacteristics); },
        getDescriptor(name) { return resolveUUID(name, assignedDescriptors); }
    };

    function toByteArray(data) {
        if (data == null) {
            return [];
        }
        if (Array.isArray(data)) {
            return Array.from(data);
        }
        if (data instanceof ArrayBuffer) {
            return Array.from(new Uint8Array(data));
        }
        if (ArrayBuffer.isView(data)) {
            return Array.from(new Uint8Array(data.buffer, data.byteOffset, data.byteLength));
        }
        return Array.from(data);
    }

    function toDataView(bytes) {
        const array = Uint8Array.from(bytes || []);
        return new DataView(array.buffer, array.byteOffset, array.byteLength);
    }

    function serializeManufacturerData(entries) {
        if (!entries) {
            return undefined;
        }
        return Array.from(entries).map((entry) => {
            const serialized = { companyIdentifier: entry.companyIdentifier };
            if (entry.dataPrefix != null) {
                serialized.dataPrefix = toByteArray(entry.dataPrefix);
            }
            if (entry.mask != null) {
                serialized.mask = toByteArray(entry.mask);
            }
            return serialized;
        });
    }

    function nativeError(error) {
        if (error.name === 'TypeError') {
            return new TypeError(error.message);
        }
        return new DOMException(error.message, error.name);
    }

    function serializeOptions(options) {
        if (options == null) {
            return options;
        }
        const serialized = {};
        if (options.acceptAllDevices) {
            serialized.acceptAllDevices = true;
        }
        if (options.optionalServices) {
            serialized.optionalServices = Array.from(options.optionalServices);
        }
        if (options.filters) {
            serialized.filters = Array.from(options.filters).map((filter) => {
                const next = {};
                if (filter.name != null) {
                    next.name = String(filter.name);
                }
                if (filter.namePrefix != null) {
                    next.namePrefix = String(filter.namePrefix);
                }
                if (filter.services) {
                    next.services = Array.from(filter.services);
                }
                if (filter.manufacturerData) {
                    next.manufacturerData = serializeManufacturerData(filter.manufacturerData);
                }
                return next;
            });
        }
        return serialized;
    }

    class Coordinator extends EventTarget {
        #requestId = 0;
        #requests = new Map();

        send(method, params = {}) {
            const requestId = this.#requestId;
            this.#requestId += 1;
            const promise = new Promise((resolve, reject) => {
                this.#requests.set(requestId, { resolve, reject });
            });
            webkit.messageHandlers.webBluetooth.postMessage({ method, requestId, ...params });
            return promise;
        }

        handleNativeMessage(message) {
            switch (message.method) {
                case 'response':
                    this.#finish(message.requestId, message.result, message.error);
                    break;
                case 'gattserverdisconnected':
                    this.dispatchEvent(new CustomEvent('gattserverdisconnected', { detail: message }));
                    break;
                case 'characteristicvaluechanged':
                    this.dispatchEvent(new CustomEvent('characteristicvaluechanged', { detail: message }));
                    break;
                case 'availabilitychanged':
                    this.dispatchEvent(new CustomEvent('availabilitychanged', { detail: message }));
                    break;
                default:
                    break;
            }
        }

        #finish(requestId, result, error) {
            const request = this.#requests.get(requestId);
            if (!request) {
                return;
            }
            this.#requests.delete(requestId);
            if (error) {
                request.reject(nativeError(error));
            } else {
                request.resolve(result);
            }
        }
    }

    class WebBluetoothKit {
        static coordinator = new Coordinator();
    }

    const coordinator = WebBluetoothKit.coordinator;

    class BluetoothRemoteGATTCharacteristic extends EventTarget {
        #oncharacteristicvaluechanged = null;

        constructor(service, info) {
            super();
            this.service = service;
            this.uuid = info.uuid;
            this.properties = Object.freeze({
                broadcast: !!info.properties.broadcast,
                read: !!info.properties.read,
                writeWithoutResponse: !!info.properties.writeWithoutResponse,
                write: !!info.properties.write,
                notify: !!info.properties.notify,
                indicate: !!info.properties.indicate,
                authenticatedSignedWrites: !!info.properties.authenticatedSignedWrites,
                reliableWrite: !!info.properties.reliableWrite,
                writableAuxiliaries: !!info.properties.writableAuxiliaries
            });
            this.value = null;
            this._id = info.id;

            const weakThis = new WeakRef(this);
            coordinator.addEventListener('characteristicvaluechanged', (event) => {
                const characteristic = weakThis.deref();
                if (!characteristic || event.detail.characteristicId !== characteristic._id) {
                    return;
                }
                characteristic.value = toDataView(event.detail.value);
                characteristic.dispatchEvent(new Event('characteristicvaluechanged'));
            });
        }

        get oncharacteristicvaluechanged() {
            return this.#oncharacteristicvaluechanged;
        }

        set oncharacteristicvaluechanged(value) {
            this.#oncharacteristicvaluechanged = value;
        }

        dispatchEvent(event) {
            const result = super.dispatchEvent(event);
            if (event.type === 'characteristicvaluechanged' && typeof this.#oncharacteristicvaluechanged === 'function') {
                this.#oncharacteristicvaluechanged(event);
            }
            return result;
        }

        async readValue() {
            const value = await coordinator.send('readValue', { characteristicId: this._id });
            this.value = toDataView(value);
            return this.value;
        }

        writeValue(data) {
            if (this.properties.writeWithoutResponse) {
                return this.writeValueWithoutResponse(data);
            }
            return this.writeValueWithResponse(data);
        }

        writeValueWithResponse(data) {
            return coordinator.send('writeValue', {
                characteristicId: this._id,
                data: toByteArray(data),
                withResponse: true
            });
        }

        writeValueWithoutResponse(data) {
            return coordinator.send('writeValue', {
                characteristicId: this._id,
                data: toByteArray(data),
                withResponse: false
            });
        }

        async startNotifications() {
            await coordinator.send('setNotify', { characteristicId: this._id, enabled: true });
            return this;
        }

        async stopNotifications() {
            await coordinator.send('setNotify', { characteristicId: this._id, enabled: false });
            return this;
        }
    }

    class BluetoothRemoteGATTService {
        constructor(device, info) {
            this.device = device;
            this.uuid = info.uuid;
            this.isPrimary = !!info.isPrimary;
            this._id = info.id;
            this._characteristics = new Map();
        }

        async getCharacteristic(characteristic) {
            const characteristics = await this.getCharacteristics(characteristic);
            return characteristics[0];
        }

        async getCharacteristics(characteristic) {
            const params = { serviceId: this._id };
            if (characteristic !== undefined) {
                params.characteristic = characteristic;
            }
            const infos = await coordinator.send('getCharacteristics', params);
            return infos.map((info) => {
                let instance = this._characteristics.get(info.id);
                if (!instance) {
                    instance = new BluetoothRemoteGATTCharacteristic(this, info);
                    this._characteristics.set(info.id, instance);
                }
                return instance;
            });
        }
    }

    class BluetoothRemoteGATTServer {
        constructor(device) {
            this.device = device;
            this.connected = false;
            this._services = new Map();
        }

        async connect() {
            await coordinator.send('gattConnect', { deviceId: this.device.id });
            this.connected = true;
            return this;
        }

        disconnect() {
            this.connected = false;
            this._services.clear();
            coordinator.send('gattDisconnect', { deviceId: this.device.id });
        }

        async getPrimaryService(service) {
            const services = await this.getPrimaryServices(service);
            return services[0];
        }

        async getPrimaryServices(service) {
            if (!this.connected) {
                throw new DOMException('GATT Server is disconnected. Cannot retrieve services.', 'NetworkError');
            }
            const params = { deviceId: this.device.id };
            if (service !== undefined) {
                params.service = service;
            }
            const infos = await coordinator.send('getPrimaryServices', params);
            return infos.map((info) => {
                let instance = this._services.get(info.id);
                if (!instance) {
                    instance = new BluetoothRemoteGATTService(this.device, info);
                    this._services.set(info.id, instance);
                }
                return instance;
            });
        }
    }

    class BluetoothDevice extends EventTarget {
        #ongattserverdisconnected = null;

        constructor(info) {
            super();
            this.id = info.id;
            this.name = info.name ?? null;
            this.gatt = new BluetoothRemoteGATTServer(this);

            const weakThis = new WeakRef(this);
            coordinator.addEventListener('gattserverdisconnected', (event) => {
                const device = weakThis.deref();
                if (!device || event.detail.deviceId !== device.id) {
                    return;
                }
                device.gatt.connected = false;
                device.gatt._services.clear();
                device.dispatchEvent(new Event('gattserverdisconnected'));
            });
        }

        get ongattserverdisconnected() {
            return this.#ongattserverdisconnected;
        }

        set ongattserverdisconnected(value) {
            this.#ongattserverdisconnected = value;
        }

        dispatchEvent(event) {
            const result = super.dispatchEvent(event);
            if (event.type === 'gattserverdisconnected' && typeof this.#ongattserverdisconnected === 'function') {
                this.#ongattserverdisconnected(event);
            }
            return result;
        }
    }

    class Bluetooth extends EventTarget {
        #onavailabilitychanged = null;

        constructor() {
            super();
            const weakThis = new WeakRef(this);
            coordinator.addEventListener('availabilitychanged', (event) => {
                const bluetooth = weakThis.deref();
                if (!bluetooth) {
                    return;
                }
                const change = new Event('availabilitychanged');
                change.value = event.detail.available;
                bluetooth.dispatchEvent(change);
            });
        }

        get onavailabilitychanged() {
            return this.#onavailabilitychanged;
        }

        set onavailabilitychanged(value) {
            this.#onavailabilitychanged = value;
        }

        dispatchEvent(event) {
            const result = super.dispatchEvent(event);
            if (event.type === 'availabilitychanged' && typeof this.#onavailabilitychanged === 'function') {
                this.#onavailabilitychanged(event);
            }
            return result;
        }

        getAvailability() {
            return coordinator.send('getAvailability');
        }

        getDevices() {
            return Promise.resolve([]);
        }

        async requestDevice(options) {
            const info = await coordinator.send('requestDevice', { options: serializeOptions(options) });
            return new BluetoothDevice(info);
        }
    }

    window.BluetoothUUID = BluetoothUUID;
    window.WebBluetoothKit = WebBluetoothKit;
    WebBluetoothKit.toByteArray = toByteArray;
    WebBluetoothKit.serializeOptions = serializeOptions;
    WebBluetoothKit.nativeError = nativeError;
    Object.defineProperty(navigator, 'bluetooth', {
        configurable: true,
        enumerable: true,
        value: new Bluetooth()
    });
})();
