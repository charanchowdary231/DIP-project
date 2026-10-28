// Tab switching logic
function switchTab(tabId) {
  const tabs = document.querySelectorAll('.tab-content');
  const buttons = document.querySelectorAll('.tab-btn');

  tabs.forEach(tab => tab.classList.remove('active'));
  buttons.forEach(btn => btn.classList.remove('active'));

  const activeTab = document.getElementById(`tab-${tabId}`);
  if (activeTab) {
    activeTab.classList.add('active');
  }

  // Highlight button
  const currentBtn = Array.from(buttons).find(btn => btn.getAttribute('onclick').includes(tabId));
  if (currentBtn) {
    currentBtn.classList.add('active');
  }
}

// Stage selection descriptions
const stageDescriptions = {
  "fig3_original.png": {
    title: "1. Original RGB Input (Fig. 3)",
    desc: "Acquired high-density urban satellite scene showing road grid, dense high-rise commercial structures, water bodies along edges, and green park clusters."
  },
  "grayscale.png": {
    title: "2. Preprocessed Grayscale (rgb2gray)",
    desc: "Intensity representation converted using the standard formula Y = 0.2989 R + 0.5870 G + 0.1140 B. Spatial details are preserved while simplifying computation."
  },
  "enhanced.png": {
    title: "3. Contrast-Enhanced (adapthisteq CLAHE)",
    desc: "Contrast-Limited Adaptive Histogram Equalization operates on local 8x8 tiles with contrast clipping, preventing noise amplification while revealing subtle street grids."
  },
  "filtered.png": {
    title: "4. 2D Median Filtered (medfilt2 [3 3])",
    desc: "3x3 spatial median filter replaces each pixel with the neighborhood median, successfully eliminating salt-and-pepper transmission noise while preserving sharp road boundaries."
  },
  "edges.png": {
    title: "5. Canny Boundary Map (edge 'canny')",
    desc: "Calculates gradient magnitudes and directions, performs non-maximum suppression, and applies hysteresis double thresholding to trace continuous structural borders."
  },
  "binary.png": {
    title: "6. Otsu Binary Segmentation (imbinarize)",
    desc: "Global intensity thresholding at optimal threshold T* = 115, determined by maximizing the between-class variance sigma_B^2(T)."
  },
  "fig4_channel_separation.png": {
    title: "7. Channel Separation R, G, B (Fig. 4)",
    desc: "Displays the Red, Green, and Blue bands as individual grayscale representations. Variations in spectral reflectance across surface types become visually apparent."
  },
  "fig5_binary_maps.png": {
    title: "8. Multi-Class Region Maps (Fig. 5)",
    desc: "Binary classification maps: Vegetation (left, 11.88%), Water regions (centre, 18.54%), and Built-up structures (right, 28.99%). White indicates selected class pixels."
  },
  "composite_landcover.png": {
    title: "9. Colour-Coded Composite (Fig. 6)",
    desc: "Composite overlay mapping Vegetation to Green [0, 204, 0], Water to Blue [0, 102, 238], Built-Up to Orange-Red [238, 85, 34], and Soil/Base to muted dark gray."
  },
  "pipeline_overview.png": {
    title: "10. Full Pipeline Overview Montage",
    desc: "Comparative 6-panel overview illustrating all primary stages side-by-side for presentation and visual inspection."
  }
};

function changeStage(imgFileName) {
  const viewerImg = document.getElementById('viewer-img');
  const titleElem = document.getElementById('display-title');
  const descElem = document.getElementById('display-desc');

  viewerImg.src = `../outputs/${imgFileName}`;

  const info = stageDescriptions[imgFileName] || {
    title: "Stage View",
    desc: "Viewing intermediate pipeline stage output."
  };

  titleElem.innerText = info.title;
  descElem.innerText = info.desc;
}

// Render KaTeX math on load if KaTeX is available
window.addEventListener('DOMContentLoaded', () => {
  if (window.katex) {
    document.querySelectorAll('.formula-box').forEach(el => {
      // already readable, can enhance dynamically
    });
  }
});

