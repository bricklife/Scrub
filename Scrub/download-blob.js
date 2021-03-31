// ref: https://stackoverflow.com/questions/61702414/wkwebview-how-to-handle-blob-url/61703086
// ref: https://luke-1220.github.io/post/webview-dl/

(function () {
    document.querySelectorAll('a').forEach(async (el) => {
        let url = el.getAttribute('href');
        if (url.indexOf('blob:') === 0) {
            let filename = el.getAttribute('download');
            let blob = await fetch(url).then(r => r.blob());
            let reader = new FileReader();
            reader.onload = function (e) {
                let json = { filename: filename, dataUri: e.target.result };
                webkit.messageHandlers.download.postMessage(JSON.stringify(json));
            };
            reader.readAsDataURL(blob);
        }
    });
})();
