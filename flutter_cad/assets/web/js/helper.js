function getGlobalObject(scriptUrl, objName) {
  return new Promise((resolve, reject) => {
    const tag = document.getElementsByTagName("script");
    for (const i of tag) {
      if (i.src.includes(scriptUrl)) {
        return resolve(window[objName]);
      }
    }
    const script = document.createElement("script");
    const baseUrl = "./";
    script.type = "text/javascript";
    script.src = `${baseUrl}${scriptUrl}`;
    script.onerror = reject;
    document.body.appendChild(script);
    script.onload = () => {
      resolve(window[objName]);
    };
  });
}
