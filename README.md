# LED PCB Documentation

A complete design, simulation, and manufacturing documentation for a simple 5V LED circuit with custom SPICE models.

**Project Goal:** Demonstrate professional circuit design workflow from simulation through PCB layout.

## Quick Start

### 1. Generate LED SPICE Models

From the repository root:

```bash
python3 simulation/python/led_model.py
```

**Note:** The script prints the SPICE model to the console. Copy the output manually:

```
.MODEL led_red D(Is=1.768568e-04,
+               n=8.539763e+00,
+               Rs=6.054497e+01)
```

### 2. Verify Circuit in LTspice

1. Open `simulation/ltspice/led_circuit.asc` in LTspice
2. The SPICE `.MODEL` directive is embedded in the schematic file
3. Simulate to verify results
4. **Predicted (from model):** LED current ~14.35 mA, voltage drop ~1.84V

### 3. Design PCB in KiCad

1. Open the project: `kicad/Simple LED.kicad_pro`
2. View schematic: `kicad/Simple LED.kicad_sch`
3. View PCB layout: `kicad/Simple LED.kicad_pcb`
4. Use the manufacturing files supplied in `kicad/gerbers.zip` (includes Gerbers and drills)

## Circuit Design

**Topology:** 5V Supply → 220Ω Resistor (R2) → Red LED (D1) → Ground

| Component | Value | Purpose |
|-----------|-------|---------|
| V1 (LTspice) | 5V DC | Power supply |
| R1 (LTspice) / R2 (KiCad) | 220Ω | Current limiting resistor (E12 standard) |
| D1 | led_red | Red LED (custom SPICE model) |

### Design Calculations

**Theoretical estimate (assuming 2V LED drop):**
```
Supply: 5V
LED drop: ~2.0V (estimated)
Resistor drop: 3.0V
Target current: 15mA

R_theoretical = 3.0V / 15mA = 200Ω
```

**Actual manufactured value:**
```
200Ω is a standard resistor (E24 series)
220Ω chosen (E12 series) to reduce current slightly
```

**Model predictions (from custom SPICE model):**
```
LED voltage drop: 1.84267V (led_red model prediction)
LED current: 14.3515 mA (model prediction)
Resistor dissipation: 45.31 mW (calculated from model)
```

## Project Structure

```
LED-PCB-DOCUMENTATION/
├── simulation/
│   ├── python/
│   │   └── led_model.py
│   ├── matlab/
│   │   └── led_model.m
│   └── ltspice/
│       ├── led_circuit.asc       → Run from LTspice (contains .MODEL)
│       └── led_circuit.log
├── models/
│   ├── red_led.lib
│   └── blue_led.lib
├── workdir/                      → Measured LED I-V data (at repository root)
│   ├── led_red.dat
│   └── led_blue.dat
├── kicad/
│   ├── Simple LED.kicad_pro      → Open this to load the project
│   ├── Simple LED.kicad_sch      → Schematic (R2, D1, J1)
│   ├── Simple LED.kicad_pcb      → PCB layout (completed)
│   └── gerbers.zip               → Gerber and drill files for manufacturing
├── README.md
└── LICENSE
```

## The Workflow

### Step 1: Measured Data → SPICE Model

```
LED I-V measurements (current vs voltage)
        ↓
Python curve fitting (Levenberg-Marquardt algorithm)
        ↓
Extract diode parameters (Is, n, Rs)
        ↓
Generate SPICE model output
```

**Files involved:**
- Input: `workdir/led_red.dat`, `workdir/led_blue.dat`
- Script: `simulation/python/led_model.py`
- Output: Model parameters (printed to console)

### Step 2: SPICE Model → Circuit Simulation

```
SPICE model (embedded in LTspice .asc file)
        ↓
Simulate circuit
        ↓
Generate predicted voltage and current
        ↓
Compare with theoretical estimates
```

**Model predictions:**
```
LED voltage drop: 1.84267V (from led_red model)
Circuit current: 14.3515 mA (from led_red model)
```

### Step 3: Verified Design → PCB Layout

```
Component values & model predictions
        ↓
KiCad schematic: R2 220Ω + D1 + J1 2-pin header
        ↓
PCB layout with proper traces & component pads
        ↓
Ground plane on bottom layer
        ↓
Design rule check: PASS
        ↓
Generate Gerber and drill files for manufacturing
```

**PCB Specifications:**
- Trace width: 0.4 mm (~15.75 mil) — safe for predicted 14.35mA
- Vias: 0 (design uses plated through-hole pads)
- Plated through-hole pads: 6 (component connections)
- Ground plane: Yes (bottom layer)

## Key Design Decisions

### Why Custom SPICE Models?

LTspice's built-in 1N4148 diode model is for signal diodes (~0.7V drop), not LEDs.

**Comparison (at 5V supply, 220Ω resistor):**
```
1N4148 at 0.7V:  → 19.55 mA through circuit
1N4148 at 0.73V: → 19.41 mA through circuit
led_red model:   → 14.3515 mA through circuit
```

The 1N4148 predictions result in much higher currents. Custom LED models provide realistic behavior.

### Why 220Ω?

- 200Ω is standard (E24 series resistor)
- 220Ω (E12 series) is more commonly stocked
- Both result in safe currents for typical LEDs

### Python vs MATLAB Implementation

**Python (`led_model.py`):**
- Uses scipy's Levenberg-Marquardt curve_fit
- Produced model output: `Is=1.768568e-04, n=8.539763e+00, Rs=6.054497e+01`
- Fit error (RMSE): ~0.0595 V (√sum of squared voltage residuals, in volts)

**MATLAB (`led_model.m`):**
- Uses fminsearch (Nelder-Mead algorithm)
- With the current implementation, produces `Is` clamped at 1e-18, `n=12`, `Rs=40`
- Earlier testing showed unphysical results
- Status: Educational reference only; do not use for design

## Installation & Usage

### Python SPICE Fitter

**Requirements:**
```bash
pip3 install scipy numpy
```

**Run from repository root:**
```bash
python3 simulation/python/led_model.py
```

**Input:** `workdir/` folder with `.dat` files  
Each `.dat` file has two columns: current (Amps), voltage (Volts)

**Output:** Prints SPICE `.MODEL` directive to console. Copy manually to use.

### LTspice Simulation

**File:** `simulation/ltspice/led_circuit.asc`

The circuit schematic contains:
- V1: 5V DC source
- R1: 220Ω resistor
- D1: LED (references `led_red` model)
- `.MODEL led_red D(...)` directive (embedded)

**To simulate:**
1. Open `.asc` file in LTspice
2. Click Run
3. LTspice uses embedded model to calculate operating point

### KiCad PCB Design

**Requirements:** KiCad 9.0+

**To open the project:**
1. Open `kicad/Simple LED.kicad_pro`
2. This loads both the schematic and PCB layout

**Files:**
- Project: `kicad/Simple LED.kicad_pro`
- Schematic: `kicad/Simple LED.kicad_sch`
- PCB Layout: `kicad/Simple LED.kicad_pcb`
- Manufacturing: `kicad/gerbers.zip` (includes Gerber and drill files)

The PCB layout is complete with:
- All components placed and routed
- Proper trace widths (0.4mm / 15.75mil)
- Ground plane on bottom layer
- Design rules verified (0 errors)

## LED Model Predictions vs. Reality

**Important:** Results shown below are model predictions based on measured I-V data. They represent the mathematical model's estimate of LED behavior, not verified specifications.

**Model predictions at 14.3515 mA:**
- LED voltage drop: 1.84267V
- Resistor dissipation: 45.31 mW

**To verify in actual circuit:**
- Build the PCB with the actual selected LED
- Measure voltage across LED and resistor with multimeter
- Compare measured values to model predictions
- Verify LED brightness and temperature are acceptable

**Safety note:** Use the selected LED's official datasheet to confirm:
- Maximum continuous forward current
- Maximum junction temperature
- Operating voltage range

Do not rely solely on model predictions without datasheet verification.

## Simulation Results

**LTspice Operating Point (predicted by led_red model):**

| Quantity | Value | Notes |
|----------|-------|-------|
| Supply voltage | 5.00000 V | Input |
| LED anode voltage (vs. ground) | 1.84267 V | Voltage at LED positive terminal |
| LED cathode voltage (vs. ground) | 0 V | Connected to GND reference |
| **Voltage across resistor** | 3.15733 V | 5V − 1.84267V |
| Circuit current magnitude | 14.3515 mA | Same through all series elements |
| Resistor dissipation | 45.31 mW | I²R = (0.0143515)² × 220 |

## Tools & Versions

- **KiCad 9.0** — Schematic & PCB design
- **LTspice 17.2.4** — Circuit simulation (uses embedded `.MODEL` in .asc file)
- **Python 3.7+** — SPICE model fitting script
- **scipy 1.17.1 / numpy 2.4.4** — Numerical computation

## Verification Checklist

- [x] Custom SPICE models generated from measured data
- [x] Circuit simulated in LTspice using embedded model
- [x] Model predictions: LED 14.3515 mA, 1.84267V drop (qualification: model-based, not measured)
- [x] Resistor value uses manufactured standard (220Ω E12)
- [x] KiCad project file created and working
- [x] KiCad schematic complete (R2, D1, J1)
- [x] KiCad PCB layout complete
- [x] Traces properly sized (0.4 mm for model prediction)
- [x] Ground plane implemented (bottom layer)
- [x] No vias required (uses plated through-hole pads)
- [x] Design rules passed
- [x] Gerber and drill files generated for manufacturing

## Known Limitations & Assumptions

### Model Accuracy

- Model based on 5 measured data points (typical for hobbyist measurement)
- More data points (10+) would improve accuracy
- Model parameters valid only for tested LED type and temperature
- Real circuit behavior depends on actual selected LED and test conditions

### MATLAB Implementation

The MATLAB version uses Nelder-Mead algorithm (fminsearch). Earlier testing produced unphysical results. The current implementation clamps parameters but does not produce reliable fits. Do not use for design work.

### LED Specifications

The design uses model predictions and theoretical estimates. Actual performance depends on:
- The specific LED selected (different manufacturer, color, or brightness)
- Measured I-V characteristics of the chosen LED
- Operating temperature and ambient conditions
- Power supply stability and voltage

**Always verify against the LED's official datasheet before building.**

## Credits

**LED SPICE Modeling Methodology:**
Based on Ted Yapo's LED modeling project:
- Hackaday.io: https://hackaday.io/project/12874
- GitHub: https://github.com/tedyapo/led-modeling
- Project Log: https://hackaday.io/project/12874/log/48368-estimating-spice-diode-models

**References:**
- Shockley Diode Equation: https://en.wikipedia.org/wiki/Shockley_diode_equation
- LTspice: https://www.analog.com/en/design-center/design-tools-and-calculators/ltspice-simulator.html
- KiCad: https://www.kicad.org/

## License

MIT License — See LICENSE file for details.

---

**Status:** Schematic verified, PCB layout completed, ready for manufacturing with actual LED datasheet verification.