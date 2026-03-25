"""
FPGA UART Interface — Professional Serial Monitor
"""

import serial
import tkinter as tk
from tkinter import ttk
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk
from collections import deque
import csv
import base64
import io
try:
    from PIL import Image, ImageTk
    _PIL_OK = True
except ImportError:
    _PIL_OK = False

# Fs        |  Fclk_gen |   Fi

# 500kHz    |   8e6     |   99.915 kHz  x
# 1Mhz      |   16e6    |   99.976 kHz  x
# 2Mhz      |   32e6    |   99.854 kHz  x
# 3Mhz      |   48e6    |   99.976 kHz  x
# 4Mhz      |   64e6    |   100.098 kHz
# 5Mhz      |   80e6    |   99.487 kHz  x

# 6Mhz      |   96e6    |   98.877 kHz
# 7Mhz      |   112e6   |   99.976 kHz
# 8Mhz      |   128e6   |   98.633 kHz
# 9Mhz      |   144e6   |   99.976 kHz
# 10Mhz     |   160e6   |   98.877 kHz



CLK_GEN_F = 80e6
BAUD_MATCH_MULT = 8
FS = CLK_GEN_F / 16

# ── Configuration ────────────────────────────────────────────────────────────
PORT                 = '/dev/ttyUSB2'
BAUDRATE             = (CLK_GEN_F / 16) / BAUD_MATCH_MULT
BUFFER_SIZE          = 4096
RAMP_FALL_THRESHOLD  = 200    # minimum drop (0–255) to count as a sawtooth reset

# ── WPI Palette ───────────────────────────────────────────────────────────────
CLR = {
    "bg":        "#ffffff",
    "panel":     "#f5f5f5",
    "border":    "#6d6d6d",
    "accent":    "#ab162b",
    "accent2":   "#002e6d",
    "warn":      "#ab162b",
    "text":      "#272626",
    "muted":     "#6d6d6d",
    "entry_bg":  "#ffffff",
    "plot_bg":   "#ffffff",
    "grid":      "#e8e8e8",
    "line":      "#002e6d",
    "dot":       "#ab162b",
    "green":     "#5e7361",
    "brown":     "#7c6569",
    "pink":      "#c78aa1",
    "yellow":    "#c78a3d",
}

FONT_MONO  = ("Courier New", 10)
FONT_LABEL = ("Courier New", 9, "bold")
FONT_TITLE = ("Courier New", 11, "bold")

# ── Embedded WPI logo (base64 PNG, 160px wide) ────────────────────────────────
WPI_LOGO_B64 = "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"


# ── Theme helpers ─────────────────────────────────────────────────────────────

def apply_theme(style: ttk.Style) -> None:
    style.theme_use("clam")

    style.configure(".",
        background=CLR["bg"],
        foreground=CLR["text"],
        font=FONT_MONO,
        borderwidth=0,
        focuscolor=CLR["accent"],
    )
    style.configure("TFrame",       background=CLR["bg"])
    style.configure("Panel.TFrame", background=CLR["panel"],
                    relief="flat",  borderwidth=1)
    style.configure("TLabel",       background=CLR["bg"],
                    foreground=CLR["muted"], font=FONT_LABEL)
    style.configure("Title.TLabel", foreground=CLR["accent"],
                    font=FONT_TITLE, background=CLR["panel"])
    style.configure("Value.TLabel", foreground=CLR["text"],
                    font=FONT_MONO, background=CLR["panel"])

    style.configure("TButton",
        background=CLR["panel"],
        foreground=CLR["text"],
        relief="flat",
        padding=(10, 6),
        font=FONT_LABEL,
        borderwidth=1,
    )
    style.map("TButton",
        background=[("active", CLR["border"]), ("pressed", CLR["accent"])],
        foreground=[("active", "#ffffff"), ("pressed", "#ffffff")],
    )
    style.configure("Accent.TButton",
        background=CLR["accent"],
        foreground="#ffffff",
    )
    style.map("Accent.TButton",
        background=[("active", "#c41e35"), ("pressed", "#8a1022")],
    )
    style.configure("Warn.TButton",
        background=CLR["accent2"],
        foreground="#ffffff",
    )
    style.map("Warn.TButton",
        background=[("active", "#003d8f"), ("pressed", "#001e4d")],
    )
    style.configure("Ramp.TButton",
        background=CLR["green"],
        foreground="#ffffff",
    )
    style.map("Ramp.TButton",
        background=[("active", "#6e8371"), ("pressed", "#4e6351")],
    )

    style.configure("TEntry",
        fieldbackground=CLR["entry_bg"],
        foreground=CLR["text"],
        insertcolor=CLR["accent"],
        borderwidth=1,
        relief="sunken",
    )
    style.configure("TCombobox",
        fieldbackground=CLR["entry_bg"],
        background=CLR["entry_bg"],
        foreground=CLR["text"],
        arrowcolor=CLR["accent"],
        selectbackground=CLR["accent"],
        selectforeground="#ffffff",
    )
    style.map("TCombobox",
        fieldbackground=[("readonly", CLR["entry_bg"])],
        foreground=[("readonly", CLR["text"])],
    )
    style.configure("TSeparator", background=CLR["border"])


def style_plot(fig, ax) -> None:
    fig.patch.set_facecolor(CLR["plot_bg"])
    ax.set_facecolor(CLR["plot_bg"])
    for spine in ax.spines.values():
        spine.set_edgecolor(CLR["border"])
    ax.tick_params(colors=CLR["muted"], labelsize=8)
    ax.xaxis.label.set_color(CLR["muted"])
    ax.yaxis.label.set_color(CLR["muted"])
    ax.grid(True, color=CLR["grid"], linewidth=0.8, linestyle="--", alpha=0.9)
    ax.set_ylim(0, 255)
    ax.set_xlim(0, BUFFER_SIZE)
    ax.yaxis.set_major_locator(ticker.MultipleLocator(32))
    ax.set_ylabel("ADC Value", fontsize=8, color=CLR["muted"])
    ax.set_xlabel("Sample Index", fontsize=8, color=CLR["muted"])
    fig.tight_layout(pad=1.2)


def labelled(parent, label_text, widget_fn, **kw):
    frame = ttk.Frame(parent)
    ttk.Label(frame, text=label_text).pack(anchor="w", pady=(0, 2))
    w = widget_fn(frame, **kw)
    w.pack(anchor="w")
    return frame, w


def separator(parent):
    ttk.Separator(parent, orient="horizontal").pack(fill="x", pady=8)


# ── Stdout redirector ─────────────────────────────────────────────────────────

class _StatusRedirect:
    def __init__(self, callback):
        import sys
        self._callback = callback
        self._real     = sys.__stdout__

    def write(self, message: str):
        self._real.write(message)
        if message.strip():
            self._callback(message)

    def flush(self):
        self._real.flush()


# ── Main Application ──────────────────────────────────────────────────────────

class SerialGUI:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("FPGA UART Interface — WPI")
        self.root.configure(bg=CLR["bg"])
        self.root.minsize(900, 600)

        # State
        self.running           = True
        self.resizing          = False
        self.after_id          = None
        self.update_counter    = 0
        self._ramp_search      = False
        self._ramp_prev        = None
        self._ramp_capture     = []
        self._ramp_target_size = 0
        self._ramp_buf_size    = 0

        # Data
        self.buffer = deque([0] * BUFFER_SIZE, maxlen=BUFFER_SIZE)
        self.x      = list(range(BUFFER_SIZE))

        # Serial
        self.ser = serial.Serial(port=PORT, baudrate=BAUDRATE, timeout=0)

        # CSV (streaming)
        self.csv_file   = open(f"data_{BAUDRATE}.csv", "w", newline="")
        self.csv_writer = csv.writer(self.csv_file)

        # Build UI
        style = ttk.Style(root)
        apply_theme(style)
        self._build_ui()

        # Start loop
        self.update_serial()

    # ── UI Layout ────────────────────────────────────────────────────────────

    def _build_ui(self):
        self._build_statusbar(self.root)

        content = ttk.Frame(self.root)
        content.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

        sidebar = ttk.Frame(content, style="Panel.TFrame", width=220)
        sidebar.pack(side=tk.LEFT, fill=tk.Y, padx=(10, 4), pady=10)
        sidebar.pack_propagate(False)
        self._build_sidebar(sidebar)

        main = ttk.Frame(content)
        main.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(4, 10), pady=10)
        self._build_plot(main)

        import sys
        sys.stdout = _StatusRedirect(self._log_status)

    def _build_statusbar(self, parent):
        bar = tk.Frame(parent, bg=CLR["panel"], bd=0)
        bar.pack(side=tk.BOTTOM, fill=tk.X)

        tk.Frame(bar, bg=CLR["accent"], height=2).pack(fill="x")

        inner = tk.Frame(bar, bg=CLR["panel"])
        inner.pack(fill="x", padx=8, pady=3)

        tk.Label(inner, text="LOG", bg=CLR["panel"],
                 fg=CLR["muted"], font=("Courier New", 7, "bold")
                 ).pack(side=tk.LEFT, padx=(0, 8))

        tk.Label(inner, text="F.M.", bg=CLR["panel"],
                 fg=CLR["yellow"], font=("Courier New", 9, "bold")
                 ).pack(side=tk.RIGHT, padx=(8, 0))

        self.statusbar_var = tk.StringVar(value="ready")
        tk.Label(inner, textvariable=self.statusbar_var,
                 bg=CLR["panel"], fg=CLR["text"],
                 font=("Courier New", 9), anchor="w"
                 ).pack(side=tk.LEFT, fill=tk.X, expand=True)

    def _log_status(self, message: str):
        self.statusbar_var.set(message.rstrip("\n"))

    def _build_sidebar(self, parent):
        header_bar = tk.Frame(parent, bg=CLR["accent"], height=4)
        header_bar.pack(fill="x")

        ttk.Label(parent, text="FPGA UART MONITOR", style="Title.TLabel",
                  background=CLR["panel"]
                  ).pack(anchor="w", padx=14, pady=(12, 2))
        ttk.Label(parent, text=f"{PORT}  ·  {BAUDRATE:,} baud",
                  foreground=CLR["muted"], background=CLR["panel"],
                  font=("Courier New", 8)
                  ).pack(anchor="w", padx=14, pady=(0, 8))

        ttk.Separator(parent, orient="horizontal").pack(fill="x", padx=10, pady=4)

        # ── Command entry ────────────────────────────────────────────────────
        ttk.Label(parent, text="COMMAND (hex)",
                  background=CLR["panel"], foreground=CLR["muted"],
                  font=FONT_LABEL).pack(anchor="w", padx=14, pady=(8, 2))

        self.entry = ttk.Entry(parent, width=22)
        self.entry.insert(0, "00 00 00")
        self.entry.pack(anchor="w", padx=14, pady=(0, 6))
        self.entry.bind("<Return>", lambda _: self.send_command())

        btn_row = ttk.Frame(parent, style="Panel.TFrame")
        btn_row.pack(fill="x", padx=14, pady=(0, 4))

        ttk.Button(btn_row, text="Send", style="Accent.TButton",
                   command=self.send_command).pack(side=tk.LEFT, padx=(0, 4))
        ttk.Button(btn_row, text="Trigger", style="Warn.TButton",
                   command=self.send_trigger).pack(side=tk.LEFT)

        ttk.Button(parent, text="⬇  RAMP TRIG", style="Ramp.TButton",
                   command=self.send_ramp_trigger
                   ).pack(anchor="w", padx=14, pady=(4, 0))

        ttk.Separator(parent, orient="horizontal").pack(fill="x", padx=10, pady=8)

        # ── Buffer size ──────────────────────────────────────────────────────
        ttk.Label(parent, text="BUFFER SIZE",
                  background=CLR["panel"], foreground=CLR["muted"],
                  font=FONT_LABEL).pack(anchor="w", padx=14, pady=(4, 2))

        self.size_var = tk.StringVar(value=str(BUFFER_SIZE))
        size_combo = ttk.Combobox(parent, textvariable=self.size_var,
                                  values=["1024", "2048", "4096", "8192", "16384"],
                                  state="readonly", width=14)
        size_combo.pack(anchor="w", padx=14, pady=(0, 6))
        size_combo.bind("<<ComboboxSelected>>", self.change_buffer_size)

        ttk.Separator(parent, orient="horizontal").pack(fill="x", padx=10, pady=8)

        # ── Sampling Rate (CE only) ──────────────────────────────────────────
        ce_lim_list = list(range(1, 500))
        sample_rate_combo_options = [f"CE={ce}" for ce in ce_lim_list]

        ttk.Label(parent, text = f"SAMPLING RATE = {FS/1e6:.3g}M" if FS >= 1e6 else f"SAMPLING RATE = {FS/1e3:.3g}k" if FS >= 1e3 else f"SAMPLING RATE = {FS}",
                  background=CLR["panel"], foreground=CLR["muted"],
                  font=FONT_LABEL).pack(anchor="w", padx=14, pady=(4, 2))

        # self.sample_rate_var = tk.StringVar(value=sample_rate_combo_options[0])
        # sample_rate_combo = ttk.Combobox(parent,
        #     textvariable=self.sample_rate_var,
        #     values=sample_rate_combo_options,
        #     state="readonly", width=20)
        # sample_rate_combo.pack(anchor="w", padx=14, pady=(0, 6))
        # sample_rate_combo.bind("<<ComboboxSelected>>", self.change_clock_speed)

        ttk.Separator(parent, orient="horizontal").pack(fill="x", padx=10, pady=8)

        # ── Reference voltages ───────────────────────────────────────────────
        voltages = [f"{v/10:.1f}" for v in range(0, 34)]

        ttk.Label(parent, text="REF VOLTAGES",
                  background=CLR["panel"], foreground=CLR["muted"],
                  font=FONT_LABEL).pack(anchor="w", padx=14, pady=(4, 6))

        ttk.Label(parent, text="HI  (V)",
                  background=CLR["panel"], foreground=CLR["accent"],
                  font=("Courier New", 9)).pack(anchor="w", padx=14)
        self.ref_hi_var = tk.StringVar(value="2.0")
        self.ref_hi_menu = ttk.Combobox(parent, textvariable=self.ref_hi_var,
                                        values=voltages, state="readonly", width=14)
        self.ref_hi_menu.pack(anchor="w", padx=14, pady=(2, 8))
        self.ref_hi_menu.bind("<<ComboboxSelected>>", self.update_ref_hi)

        ttk.Label(parent, text="LO  (V)",
                  background=CLR["panel"], foreground=CLR["accent2"],
                  font=("Courier New", 9)).pack(anchor="w", padx=14)
        self.ref_lo_var = tk.StringVar(value="1.0")
        self.ref_lo_menu = ttk.Combobox(parent, textvariable=self.ref_lo_var,
                                        values=voltages, state="readonly", width=14)
        self.ref_lo_menu.pack(anchor="w", padx=14, pady=(2, 8))
        self.ref_lo_menu.bind("<<ComboboxSelected>>", self.update_ref_lo)

        ttk.Separator(parent, orient="horizontal").pack(fill="x", padx=10, pady=8)

        # ── Save CSV ─────────────────────────────────────────────────────────
        ttk.Button(parent, text="⬇  Export CSV", command=self.save_csv_popup
                   ).pack(anchor="w", padx=14, pady=4)

        # ── Status ────────────────────────────────────────────────────────────
        self.status_var = tk.StringVar(value="● CONNECTED")
        ttk.Label(parent, textvariable=self.status_var,
                  background=CLR["panel"], foreground=CLR["green"],
                  font=("Courier New", 8)).pack(anchor="w", padx=14, pady=(8, 4))

        self._add_logo(parent)

    def _add_logo(self, parent):
        if not _PIL_OK:
            tk.Label(parent, text="WPI", bg=CLR["panel"],
                     fg=CLR["accent"], font=("Georgia", 14, "bold")
                     ).pack(side=tk.BOTTOM, pady=10)
            return
        try:
            raw = base64.b64decode(WPI_LOGO_B64)
            img = Image.open(io.BytesIO(raw))
            img.thumbnail((160, 80), Image.LANCZOS)
            self._logo_img = ImageTk.PhotoImage(img)
            tk.Label(parent, image=self._logo_img,
                     bg=CLR["panel"], bd=0
                     ).pack(side=tk.BOTTOM, pady=10)
        except Exception as e:
            print("Logo load failed:", e)

    def _build_plot(self, parent):
        header = ttk.Frame(parent)
        header.pack(fill="x", pady=(0, 6))
        ttk.Label(header, text="WAVEFORM MONITOR",
                  foreground=CLR["accent"], font=FONT_TITLE).pack(side=tk.LEFT)
        self.sample_label = ttk.Label(header, text="",
                                      foreground=CLR["muted"],
                                      font=("Courier New", 8))
        self.sample_label.pack(side=tk.RIGHT)

        self.fig, self.ax = plt.subplots(figsize=(9, 4.5))
        style_plot(self.fig, self.ax)

        self.line, = self.ax.plot(self.x, self.buffer,
                                  linestyle="-", linewidth=0.8,
                                  color=CLR["line"], alpha=0.85)
        self.dots, = self.ax.plot(self.x, self.buffer,
                                  linestyle="None", marker="o",
                                  markersize=2.2, color=CLR["dot"], alpha=0.7)

        plot_frame = ttk.Frame(parent)
        plot_frame.pack(fill=tk.BOTH, expand=True)

        self.canvas = FigureCanvasTkAgg(self.fig, master=plot_frame)
        self.canvas.get_tk_widget().configure(bg=CLR["bg"], highlightthickness=0)
        self.canvas.draw()

        toolbar_frame = ttk.Frame(plot_frame)
        toolbar_frame.pack(fill="x")
        self.toolbar = NavigationToolbar2Tk(self.canvas, toolbar_frame)
        self.toolbar.configure(background=CLR["panel"])
        self.toolbar.update()

        self.canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    # ── Serial loop ──────────────────────────────────────────────────────────

    def update_serial(self):
        if not self.running:
            return
        try:
            while self.ser.in_waiting > 0:
                byte = self.ser.read(1)[0]
                self.csv_writer.writerow([byte])
                self.buffer.append(byte)

            self.update_counter += 1
            if self.update_counter >= 5:
                if not self.toolbar.mode and not self.resizing:
                    self.line.set_data(self.x, self.buffer)
                    self.dots.set_data(self.x, self.buffer)
                    self.canvas.draw_idle()
                    n = len(self.buffer)
                    self.sample_label.configure(
                        text=f"samples: {n:,}  |  buf: {BUFFER_SIZE:,}")
                self.update_counter = 0

        except Exception as e:
            if self.running:
                print("Serial error:", e)
                self.status_var.set("● ERROR")

        self.after_id = self.root.after(1, self.update_serial)

    # ── Buffer resize ────────────────────────────────────────────────────────

    def change_buffer_size(self, _event=None):
        try:
            self.resizing  = True
            new_size       = int(self.size_var.get())
            self.buffer    = deque(self.buffer, maxlen=new_size)
            self.x         = list(range(new_size))

            self.line.set_data(self.x, self.buffer)
            self.dots.set_data(self.x, self.buffer)
            self.ax.set_xlim(0, new_size)
            self.canvas.draw_idle()

            msb, lsb = (new_size >> 8) & 0xFF, new_size & 0xFF
            self.ser.write(bytes([0x03, msb, lsb]))
            print(f"Buffer → {new_size}")
        except Exception as e:
            print("Resize error:", e)
        finally:
            self.resizing = False

    # ── Clock speed ──────────────────────────────────────────────────────────

    def change_clock_speed(self, _event=None):
        try:
            selected = self.sample_rate_var.get()   # e.g. "CE=3"
            ce_lim   = int(selected.split("CE=")[1])

            msb = (ce_lim >> 8) & 0xFF
            lsb =  ce_lim & 0xFF

            self.ser.write(bytes([0x01, msb, lsb]))
            print(f"Sampling rate → CE_LIM={ce_lim}  (01 {msb:02X} {lsb:02X})")
        except Exception as e:
            print("Clock speed error:", e)

    # ── Commands ─────────────────────────────────────────────────────────────

    def send_command(self):
        try:
            parts = self.entry.get().split()
            data  = [int(p, 16) for p in parts[:3]]
            data += [0] * (3 - len(data))
            self.ser.write(bytes(data))
        except Exception:
            print("Invalid hex input")

    def send_trigger(self):
        self.ser.write(bytes([0x02, 0x00, 0x00]))

    def send_ramp_trigger(self):
        buf_size    = int(self.size_var.get())
        double_size = buf_size * 2

        print(f"RAMP TRIG: capturing {double_size} samples...")

        msb = (double_size >> 8) & 0xFF
        lsb =  double_size & 0xFF
        self.ser.write(bytes([0x03, msb, lsb]))
        self.ser.write(bytes([0x02, 0x00, 0x00]))

        self._ramp_search      = True
        self._ramp_capture     = []
        self._ramp_target_size = double_size
        self._ramp_buf_size    = buf_size
        self._ramp_collect()

    def _ramp_collect(self):
        if not self._ramp_search:
            return

        try:
            while self.ser.in_waiting > 0:
                byte = self.ser.read(1)[0]
                self.csv_writer.writerow([byte])
                self._ramp_capture.append(byte)
        except Exception as e:
            print(f"RAMP TRIG error: {e}")
            self._ramp_search  = False
            self._ramp_capture = []
            return

        if len(self._ramp_capture) < self._ramp_target_size:
            self.root.after(1, self._ramp_collect)
            return

        edge_idx = self._find_falling_edge(self._ramp_capture)

        if edge_idx is not None:
            after_edge = self._ramp_capture[edge_idx:]

            if len(after_edge) >= self._ramp_buf_size:
                aligned = after_edge[:self._ramp_buf_size]
                self.buffer = deque(aligned, maxlen=self._ramp_buf_size)
                self.x      = list(range(self._ramp_buf_size))

                self.line.set_data(self.x, self.buffer)
                self.dots.set_data(self.x, self.buffer)
                self.ax.set_xlim(0, self._ramp_buf_size)
                self.canvas.draw_idle()

                drop = self._ramp_capture[edge_idx - 1] - self._ramp_capture[edge_idx]
                print(f"RAMP TRIG: locked — edge at raw index {edge_idx}, drop={drop}")
            else:
                print(f"RAMP TRIG: edge too close to end "
                      f"({len(after_edge)} samples after edge, need {self._ramp_buf_size}). "
                      f"Try again.")
        else:
            print(f"RAMP TRIG: no falling edge found in {self._ramp_target_size} samples. "
                  f"Check RAMP_FALL_THRESHOLD={RAMP_FALL_THRESHOLD}.")

        msb = (self._ramp_buf_size >> 8) & 0xFF
        lsb =  self._ramp_buf_size & 0xFF
        self.ser.write(bytes([0x03, msb, lsb]))

        self._ramp_search  = False
        self._ramp_capture = []

    def _find_falling_edge(self, data: list) -> int | None:
        for i in range(1, len(data)):
            drop = data[i - 1] - data[i]
            if drop > RAMP_FALL_THRESHOLD:
                return i
        return None

    # ── DAC helpers ──────────────────────────────────────────────────────────

    def voltage_to_code(self, voltage: float) -> int:
        val = int(round((voltage / 3.3) * 1024))
        return max(0, min(1023, val))

    def send_dac_command(self, cmd: int, value: int) -> None:
        msb, lsb = (value >> 8) & 0x03, value & 0xFF
        self.ser.write(bytes([cmd, msb, lsb]))
        self.ser.write(bytes([0x06, 0x00, 0x00]))
        print(f"DAC cmd={cmd:02X} value={value} ({msb:02X} {lsb:02X})")

    def update_ref_hi(self, _event=None):
        try:
            hi = float(self.ref_hi_var.get())
            lo = float(self.ref_lo_var.get())
            if hi < lo:
                hi = lo
                self.ref_hi_var.set(f"{hi:.1f}")
            self.send_dac_command(0x05, self.voltage_to_code(hi))
        except Exception as e:
            print("REF HI error:", e)

    def update_ref_lo(self, _event=None):
        try:
            hi = float(self.ref_hi_var.get())
            lo = float(self.ref_lo_var.get())
            if lo > hi:
                lo = hi
                self.ref_lo_var.set(f"{lo:.1f}")
            self.send_dac_command(0x04, self.voltage_to_code(lo))
        except Exception as e:
            print("REF LO error:", e)

    # ── CSV save ─────────────────────────────────────────────────────────────

    def _default_filename(self) -> str:
        buf = self.size_var.get()
        try:
            ce = self.sample_rate_var.get().split("CE=")[1]
        except Exception:
            ce = "?"
        hi = self.ref_hi_var.get()
        lo = self.ref_lo_var.get()
        return f"buf{buf}_ce{ce}_hi{hi}V_lo{lo}V.csv"

    def save_csv_popup(self):
        popup = tk.Toplevel(self.root)
        popup.title("Save Buffer")
        popup.configure(bg=CLR["bg"])
        popup.resizable(False, False)
        popup.transient(self.root)
        popup.grab_set()
        self.root.update_idletasks()

        rx, ry = self.root.winfo_x(), self.root.winfo_y()
        rw, rh = self.root.winfo_width(), self.root.winfo_height()
        popup.update_idletasks()
        pw, ph = popup.winfo_reqwidth(), popup.winfo_reqheight()
        popup.geometry(f"+{rx + (rw - pw) // 2}+{ry + (rh - ph) // 2}")

        ttk.Label(popup, text="EXPORT FILENAME",
                  font=FONT_LABEL, foreground=CLR["muted"]
                  ).pack(padx=20, pady=(16, 4), anchor="w")

        entry = ttk.Entry(popup, width=36)
        entry.pack(padx=20, pady=(0, 10))
        entry.insert(0, self._default_filename())

        btn_row = ttk.Frame(popup)
        btn_row.pack(padx=20, pady=(0, 16))

        def save_and_close():
            filename = entry.get().strip()
            if not filename:
                return
            if not filename.endswith(".csv"):
                filename += ".csv"
            self.save_current_buffer(filename)
            popup.destroy()

        ttk.Button(btn_row, text="Save", style="Accent.TButton",
                   command=save_and_close).pack(side=tk.LEFT, padx=(0, 6))
        ttk.Button(btn_row, text="Cancel",
                   command=popup.destroy).pack(side=tk.LEFT)

    def save_current_buffer(self, filename: str) -> None:
        try:
            data = list(self.buffer)
            with open(filename, "w", newline="") as f:
                writer = csv.writer(f)
                writer.writerow(["Index", "Value"])
                writer.writerows(enumerate(data))
            print(f"Saved {len(data)} samples → {filename}")
        except Exception as e:
            print("Save failed:", e)

    # ── Shutdown ─────────────────────────────────────────────────────────────

    def close(self):
        print("Shutting down...")
        self.running = False
        if self.after_id:
            try: self.root.after_cancel(self.after_id)
            except Exception: pass
        for obj in (self.ser, self.csv_file):
            try: obj.close()
            except Exception: pass
        import sys
        sys.stdout = sys.__stdout__
        self.root.quit()
        self.root.destroy()


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    root = tk.Tk()
    app  = SerialGUI(root)
    root.protocol("WM_DELETE_WINDOW", app.close)
    root.mainloop()


if __name__ == "__main__":
    main()