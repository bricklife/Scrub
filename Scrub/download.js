(function () {
    function arrayBufferToBase64(buffer) {
        let binary = '';
        let bytes = new Uint8Array(buffer);
        let len = bytes.byteLength;
        for (let i = 0; i < len; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return window.btoa(binary);
    }

    document.body.querySelectorAll('a').forEach((el) => {
        let url = el.getAttribute('href');
        if (url.indexOf('blob:') === 0) {
            let filename = el.getAttribute('download');
            let filetype = el.getAttribute('type');
            fetch(url)
                .then(response => response.blob())
                .then(function (blob) {
                    let filereader = new FileReader();
                    filereader.onload = function (e) {
                        let data = arrayBufferToBase64(e.target.result);
                        let json = { filename: filename, filetype: filetype, data: data }
                        webkit.messageHandlers.download.postMessage(JSON.stringify(json));
                    }
                    filereader.readAsArrayBuffer(blob);
                });
        }
    });
})();