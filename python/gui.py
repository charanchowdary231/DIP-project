"""
Interactive Desktop GUI for Satellite Image Analysis (Python Tkinter)
====================================================================
Features:
- Image loading (PNG, JPG, BMP)
- Interactive parameter sliders (CLAHE ClipLimit, Median Kernel, Canny thresholds)
- Interactive stage visualizer (Original, Grayscale, Enhanced, Filtered, Edges, Otsu, Regions, Composite, Channels)
- Live quantitative metrics display
- Export all stages to disk
"""

import os
import sys
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from PIL import Image, ImageTk
import numpy as np

script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)

from pipeline import SatellitePipeline
from metrics import calculate_mse, calculate_rmse, calculate_psnr, calculate_ssim

class SatelliteAnalysisApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Satellite Image Analysis - DIP Project (VIT-AP)")
        self.root.geometry("1200x760")
        self.root.configure(bg="#1a1d24")

        self.pipeline = SatellitePipeline()
        self.image_path = None
        self.clean_ref = None
        self.current_display_img = None

        self._build_ui()
        self._load_default_image()

    def _build_ui(self):
        # Left sidebar for controls
        sidebar = tk.Frame(self.root, bg="#222630", width=340, padx=12, pady=12)
        sidebar.pack(side=tk.LEFT, fill=tk.Y, padx=8, pady=8)
        sidebar.pack_propagate(False)

        # Title
        tk.Label(sidebar, text="DIP CONTROL PANEL", font=("Segoe UI", 12, "bold"),
                 bg="#222630", fg="#4ba3e3").pack(anchor="w", pady=(0, 10))

        # File load button
        btn_load = tk.Button(sidebar, text="📁  Load Satellite Image", font=("Segoe UI", 9, "bold"),
                             bg="#2b6cb0", fg="white", activebackground="#3182ce", activeforeground="white",
                             relief=tk.FLAT, command=self._on_load_file)
        btn_load.pack(fill=tk.X, pady=(0, 6))

        self.lbl_file = tk.Label(sidebar, text="Default: satellite.jpg", font=("Segoe UI", 8),
                                 bg="#222630", fg="#a0aec0", wraplength=310)
        self.lbl_file.pack(anchor="w", pady=(0, 12))

        # Stage dropdown
        tk.Label(sidebar, text="Visualizer Stage:", font=("Segoe UI", 9, "bold"),
                 bg="#222630", fg="#e2e8f0").pack(anchor="w")

        self.stages = [
            "1. Original RGB Input",
            "2. Grayscale Preprocessed",
            "3. CLAHE Enhanced",
            "4. 2D Median Filtered",
            "5. Canny Boundary Map",
            "6. Otsu Binary Segmentation",
            "7. Colour Channels (R, G, B)",
            "8. Multi-Class Region Maps",
            "9. Colour-Coded Composite",
            "10. Multispectral NDVI / NDWI"
        ]
        self.stage_var = tk.StringVar(value=self.stages[0])
        self.dd_stage = ttk.Combobox(sidebar, textvariable=self.stage_var, values=self.stages, state="readonly")
        self.dd_stage.pack(fill=tk.X, pady=(4, 14))
        self.dd_stage.bind("<<ComboboxSelected>>", lambda e: self._update_display())

        # Parameters header
        tk.Label(sidebar, text="Processing Parameters:", font=("Segoe UI", 9, "bold"),
                 bg="#222630", fg="#63b3ed").pack(anchor="w", pady=(0, 6))

        # CLAHE Clip Limit
        tk.Label(sidebar, text="CLAHE Clip Limit:", font=("Segoe UI", 8), bg="#222630", fg="#cbd5e0").pack(anchor="w")
        self.slider_clip = tk.Scale(sidebar, from_=1.0, to=5.0, resolution=0.2, orient=tk.HORIZONTAL,
                                    bg="#222630", fg="#e2e8f0", highlightthickness=0, troughcolor="#4a5568")
        self.slider_clip.set(2.0)
        self.slider_clip.pack(fill=tk.X, pady=(0, 6))

        # Median Kernel
        tk.Label(sidebar, text="Median Kernel Size:", font=("Segoe UI", 8), bg="#222630", fg="#cbd5e0").pack(anchor="w")
        self.kernel_var = tk.IntVar(value=3)
        kernel_frame = tk.Frame(sidebar, bg="#222630")
        kernel_frame.pack(fill=tk.X, pady=(0, 6))
        for k in [3, 5, 7]:
            tk.Radiobutton(kernel_frame, text=f"{k}x{k}", variable=self.kernel_var, value=k,
                           bg="#222630", fg="#e2e8f0", selectcolor="#2b6cb0", activebackground="#222630").pack(side=tk.LEFT, padx=8)

        # Canny Low / High
        tk.Label(sidebar, text="Canny Edge Low / High Threshold:", font=("Segoe UI", 8), bg="#222630", fg="#cbd5e0").pack(anchor="w")
        self.slider_canny_low = tk.Scale(sidebar, from_=10, to=120, orient=tk.HORIZONTAL,
                                         bg="#222630", fg="#e2e8f0", highlightthickness=0, troughcolor="#4a5568")
        self.slider_canny_low.set(50)
        self.slider_canny_low.pack(fill=tk.X)

        self.slider_canny_high = tk.Scale(sidebar, from_=60, to=240, orient=tk.HORIZONTAL,
                                          bg="#222630", fg="#e2e8f0", highlightthickness=0, troughcolor="#4a5568")
        self.slider_canny_high.set(150)
        self.slider_canny_high.pack(fill=tk.X, pady=(0, 10))

        # Run button
        btn_run = tk.Button(sidebar, text="▶  Run Complete Pipeline", font=("Segoe UI", 10, "bold"),
                            bg="#2f855a", fg="white", activebackground="#38a169", activeforeground="white",
                            relief=tk.FLAT, command=self._execute_pipeline)
        btn_run.pack(fill=tk.X, pady=(0, 6))

        btn_export = tk.Button(sidebar, text="💾  Export All Images & CSV", font=("Segoe UI", 9, "bold"),
                               bg="#c05621", fg="white", activebackground="#dd6b20", activeforeground="white",
                               relief=tk.FLAT, command=self._export_outputs)
        btn_export.pack(fill=tk.X, pady=(0, 14))

        # Metrics box
        metrics_frame = tk.LabelFrame(sidebar, text=" Quality Metrics (Sec. VI) ", font=("Segoe UI", 8, "bold"),
                                      bg="#1a1d24", fg="#f6e05e", padx=8, pady=8)
        metrics_frame.pack(fill=tk.BOTH, expand=True)

        self.lbl_metrics = tk.Label(metrics_frame, text="MSE:  ---\nRMSE: ---\nPSNR: ---\nSSIM: ---",
                                    font=("Consolas", 9), justify=tk.LEFT, bg="#1a1d24", fg="#9ae6b4")
        self.lbl_metrics.pack(anchor="w")

        # Right display area
        display_frame = tk.Frame(self.root, bg="#14171d")
        display_frame.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True, padx=8, pady=8)

        self.lbl_stage_title = tk.Label(display_frame, text="Satellite Image Viewer", font=("Segoe UI", 12, "bold"),
                                        bg="#14171d", fg="#ffffff")
        self.lbl_stage_title.pack(anchor="w", pady=(4, 8), padx=8)

        self.canvas = tk.Label(display_frame, bg="#0d0f12")
        self.canvas.pack(fill=tk.BOTH, expand=True, padx=8, pady=8)

    def _load_default_image(self):
        default_path = os.path.abspath(os.path.join(script_dir, "..", "data", "satellite.jpg"))
        if not os.path.exists(default_path):
            default_path = os.path.abspath(os.path.join(script_dir, "satellite.jpg"))

        if os.path.exists(default_path):
            self.image_path = default_path
            self.lbl_file.config(text=f"Loaded: {os.path.basename(default_path)}")
            clean_path = os.path.join(os.path.dirname(default_path), "satellite_clean.png")
            if os.path.exists(clean_path):
                self.clean_ref = np.array(Image.open(clean_path).convert('L'))
            self.pipeline.load_image(self.image_path)
            self._execute_pipeline()

    def _on_load_file(self):
        path = filedialog.askopenfilename(filetypes=[("Image Files", "*.jpg;*.jpeg;*.png;*.bmp;*.tif")])
        if path:
            self.image_path = path
            self.lbl_file.config(text=f"Loaded: {os.path.basename(path)}")
            self.pipeline.load_image(self.image_path)
            clean_candidate = os.path.join(os.path.dirname(path), "satellite_clean.png")
            if os.path.exists(clean_candidate):
                self.clean_ref = np.array(Image.open(clean_candidate).convert('L'))
            self._execute_pipeline()

    def _execute_pipeline(self):
        if self.pipeline.rgb is None:
            return

        clip = float(self.slider_clip.get())
        ksize = int(self.kernel_var.get())
        low = int(self.slider_canny_low.get())
        high = int(self.slider_canny_high.get())

        self.pipeline.enhance_contrast(clip_limit=clip)
        self.pipeline.reduce_noise(ksize=ksize)
        self.pipeline.detect_edges(method="canny", low_thresh=low, high_thresh=high)
        self.pipeline.segment_regions()
        self.pipeline.separate_channels()
        self.pipeline.compute_spectral_indices()

        # Update metrics
        ref = self.clean_ref if self.clean_ref is not None else self.pipeline.gray
        target = self.pipeline.filtered
        mse = calculate_mse(ref, target)
        rmse = calculate_rmse(ref, target)
        psnr = calculate_psnr(ref, target)
        ssim = calculate_ssim(ref, target)

        self.lbl_metrics.config(text=f"MSE:  {mse:7.3f}\nRMSE: {rmse:7.3f}\nPSNR: {psnr:6.2f} dB\nSSIM: {ssim:7.4f}")
        self._update_display()

    def _update_display(self):
        if self.pipeline.rgb is None:
            return

        choice = self.stage_var.get()
        self.lbl_stage_title.config(text=choice)

        if "1. Original" in choice:
            img = Image.fromarray(self.pipeline.rgb)
        elif "2. Grayscale" in choice:
            img = Image.fromarray(self.pipeline.gray)
        elif "3. CLAHE" in choice:
            img = Image.fromarray(self.pipeline.enhanced)
        elif "4. 2D Median" in choice:
            img = Image.fromarray(self.pipeline.filtered)
        elif "5. Canny" in choice:
            img = Image.fromarray(self.pipeline.edges)
        elif "6. Otsu" in choice:
            img = Image.fromarray(self.pipeline.binary_otsu)
        elif "7. Colour Channels" in choice:
            r = self.pipeline.channels["red"]
            g = self.pipeline.channels["green"]
            b = self.pipeline.channels["blue"]
            montage = np.concatenate([r, g, b], axis=1)
            img = Image.fromarray(montage)
        elif "8. Multi-Class" in choice:
            v = self.pipeline.masks["vegetation"]
            w = self.pipeline.masks["water"]
            b = self.pipeline.masks["builtup"]
            montage = np.concatenate([v, w, b], axis=1)
            img = Image.fromarray(montage)
        elif "9. Colour-Coded" in choice:
            img = Image.fromarray(self.pipeline.composite)
        elif "10. Multispectral" in choice:
            ndvi = ((self.pipeline.indices["NDVI"] + 1.0) * 127.5).astype(np.uint8)
            ndwi = ((self.pipeline.indices["NDWI"] + 1.0) * 127.5).astype(np.uint8)
            montage = np.concatenate([ndvi, ndwi], axis=1)
            img = Image.fromarray(montage)
        else:
            img = Image.fromarray(self.pipeline.rgb)

        # Resize to fit window while keeping aspect ratio
        canvas_w = max(400, self.root.winfo_width() - 380)
        canvas_h = max(300, self.root.winfo_height() - 100)
        img.thumbnail((canvas_w, canvas_h), Image.Resampling.LANCZOS)

        photo = ImageTk.PhotoImage(img)
        self.canvas.config(image=photo)
        self.canvas.image = photo

    def _export_outputs(self):
        out_dir = os.path.abspath(os.path.join(script_dir, "..", "outputs"))
        os.makedirs(out_dir, exist_ok=True)

        Image.fromarray(self.pipeline.rgb).save(os.path.join(out_dir, "fig3_original.png"))
        Image.fromarray(self.pipeline.gray).save(os.path.join(out_dir, "grayscale.png"))
        Image.fromarray(self.pipeline.enhanced).save(os.path.join(out_dir, "enhanced.png"))
        Image.fromarray(self.pipeline.filtered).save(os.path.join(out_dir, "filtered.png"))
        Image.fromarray(self.pipeline.edges).save(os.path.join(out_dir, "edges.png"))
        Image.fromarray(self.pipeline.binary_otsu).save(os.path.join(out_dir, "binary.png"))
        Image.fromarray(self.pipeline.composite).save(os.path.join(out_dir, "composite_landcover.png"))

        messagebox.showinfo("Export Complete", f"Successfully saved pipeline images to:\n{out_dir}")

def main():
    root = tk.Tk()
    app = SatelliteAnalysisApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()

