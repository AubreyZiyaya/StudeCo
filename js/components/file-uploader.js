// Generic file uploader UI helper (client-side pre-checks and progress monitoring)
export function createFileInput({ accept = '*/*', multiple = false }) {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = accept;
  input.multiple = multiple;
  return input;
}

export function showUploadProgress(container, percent) {
  let bar = container.querySelector('.upload-progress');
  if (!bar) {
    bar = document.createElement('div');
    bar.className = 'upload-progress';
    bar.style.height = '8px';
    bar.style.background = '#e6e9ff';
    bar.style.borderRadius = '6px';
    bar.style.overflow = 'hidden';
    container.appendChild(bar);
  }
  bar.style.width = '100%';
  bar.innerHTML = `<div style="height:100%; width:${percent}%; background: linear-gradient(90deg,#3b2d7d,#4d89ff); transition: width 200ms"></div>`;
}
