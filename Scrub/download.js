document.body.querySelectorAll('a').forEach((el) => {
    let url = el.getAttribute('href');
    if (url.indexOf('blob:') === 0) {
        let filename = el.getAttribute('download');
        let filetype = el.getAttribute('type');
        fetch(url)
            .then(response => response.blob())
            .then(function (blob) {
                console.log(blob);
                let filereader = new FileReader();
                filereader.onload = function (e) {
                    let base64 = btoa(String.fromCharCode(...new Uint8Array(e.target.result)));
                    let json = { filename: filename, filetype: filetype, data: base64 }
                    webkit.messageHandlers.download.postMessage(JSON.stringify(json));
                }
                filereader.readAsArrayBuffer(blob);
            });
    }
});
