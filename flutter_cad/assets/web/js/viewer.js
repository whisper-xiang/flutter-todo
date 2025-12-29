console.log('viewer.js loaded ✅');

function initViewer() {
  console.log('initViewer start');
  console.log('window size', {
    w: window.innerWidth,
    h: window.innerHeight
  });

  document.getElementById('viewer').innerText = 'Viewer Ready';
}

window.onload = initViewer;