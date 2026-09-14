# LED PCB Documentation

A complete design, simulation, and manufacturing documentation for a simple 5V LED circuit with custom SPICE models.

**Project Goal:** Demonstrate professional circuit design workflow from calculations to simulation and PCB layout.

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

1. Open `kicad/Simple LED.kicad_sch` 
2. The SPICE model is already embedded in the schematic
3. Simulate to verify results
4. Expected: LED current ~14.3 mA, voltage drop ~1.84V ✓

### 3. Design PCB in KiCad

1. Open `kicad/Simple LED.kicad_pcb` (PCB layout completed)
2. View the routed design with ground plane
3. Export Gerber files for manufacturing

## Circuit Design

**Topology:** 5V Supply → 220Ω Resistor → Red LED → Ground

| Component | Value | Purpose |
|-----------|-------|---------|
| V1 | 5V DC | Power supply |
| R1 | 220Ω | Current limiting resistor (E12 standard) |
| D1 | red_led | Red LED (custom SPICE model) |

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
→ More conservative, safer for LED
```

**Actual simulation results (with custom SPICE model):**
```
LED voltage drop: 1.84V (red LED characteristic)
LED current: 14.35 mA
Resistor dissipation: 45.3 mW (well within limits)
```

## Project Structure

```
LED-PCB-DOCUMENTATION/
├── simulation/
│   ├── python/
│   │   └── led_model.py        → Run from repo root
│   └── matlab/
│       └── led_model.m         → Alternative (educational only)
├── models/
│   ├── red_led.lib
│   ├── blue_led.lib
│   └── workdir/                → Measured LED data
│       ├── led_red.dat
│       └── led_blue.dat
├── kicad/
│   ├── Simple LED.kicad_sch    → Schematic with embedded model
│   └── Simple LED.kicad_pcb    → PCB layout (completed)
├── README.md                   → This file
└── LICENSE                     → MIT License
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
SPICE model (embedded in schematic)
        ↓
Simulate with actual model
        ↓
Verify voltage drops & current
        ↓
Confirm safe operation
```

**Expected Results:**
```
V(LED) = 1.84V      ✓ Actual red LED behavior
I(LED) = 14.35mA    ✓ Safe (within typical max 20mA)
```

### Step 3: Verified Design → PCB Layout

```
Verified component values & currents
        ↓
KiCad schematic with 220Ω resistor + embedded SPICE model
        ↓
PCB layout with proper traces (10-15 mil width) & vias
        ↓
Ground plane on bottom layer
        ↓
Design complete, ready for manufacturing
```

**Design Features:**
- Trace width: 15 mil (0.4mm) - safe for 14mA
- Ground plane: Yes (bottom layer)
- Vias: 4 total (one per component connection)
- Design rule check: PASS ✓

## Key Design Decisions

### Why Custom SPICE Models?

LTspice's built-in 1N4148 diode model is for signal diodes (~0.7V drop), not LEDs (~1.8-2.0V drop).

**Without custom model:**
```
Wrong model (1N4148): Vd=0.73V, Id=21.3mA  ✗ (risky)
```

**With custom model:**
```
Measured model (led_red): Vd=1.84V, Id=14.35mA ✓ (safe)
```

### Why 220Ω?

- 200Ω is standard (E24 series resistor)
- But 220Ω (E12 series) is more commonly available
- Running at slightly lower current improves LED lifespan
- Actual result: 14.35mA (safe, well below typical 20mA max)

### Python vs MATLAB

| Aspect | Python | MATLAB |
|--------|--------|--------|
| Stability | Excellent ✓ | Has numerical issues |
| Algorithm | Levenberg-Marquardt | Nelder-Mead (less stable) |
| Results | Accurate | Can fail with small datasets |
| Recommended | YES ✓ | Educational reference only |

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

**Input:** `workdir/` with `.dat` files (current, voltage pairs)

**Output:** Prints SPICE model to console. Copy manually to use in other tools.

### LTspice Simulation

The SPICE model is **already embedded** in the KiCad schematic file as a `.lib` component.

### KiCad PCB Design

**Requirements:** KiCad 9.0+

**Files:**
- Schematic: `kicad/Simple LED.kicad_sch`
- PCB Layout: `kicad/Simple LED.kicad_pcb` (completed)

The PCB includes:
- ✓ All components placed
- ✓ Traces routed (15 mil width)
- ✓ Ground plane on bottom layer
- ✓ 4 vias for connections
- ✓ Design rules verified

## LED Specifications

**Test LED Characteristics:**
- Type: Standard 5mm red LED
- Forward voltage (Vf): ~1.84V (at 14mA, from SPICE model)
- Max continuous current: ~20mA (typical specification)
- Operating range: 10-20mA recommended

**Design headroom:**
- Operating current: 14.35mA
- Max typical current: 20mA
- Safety margin: ~29% (good for reliability)

**Note:** For different LED types or higher accuracy, provide actual LED datasheet.

## Simulation Results

**LTspice Operating Bias Point:**
```
V(5V_rail)     = 5.00V      ✓ Supply
V(LED)         = 1.84V      ✓ Matches measured model
V(GND)         = 0.00V      ✓ Reference
I(LED)         = 14.35mA    ✓ Safe
I(Resistor)    = -14.35mA   ✓ Same current (series)
P(R220Ω)       = 45.3mW     ✓ Well within limits
```

## Tools & Versions

- **KiCad 9.0** - Schematic & PCB design
- **LTspice 17.2.4** - Circuit simulation
- **Python 3.7+** - SPICE model fitting
- **scipy/numpy** - Numerical computation

## Verification Checklist

- [x] Custom SPICE models generated from measured data
- [x] Circuit simulated and verified in LTspice
- [x] LED current confirmed safe (14.35mA < 20mA typical max)
- [x] LED voltage drop realistic (~1.84V for red)
- [x] Resistor value uses manufactured standard (220Ω E12)
- [x] KiCad schematic complete with embedded model
- [x] KiCad PCB layout complete
- [x] Traces properly sized (15 mil for 14mA)
- [x] Ground plane implemented
- [x] Design rules passed
- [x] Ready for manufacturing

## Known Limitations

### MATLAB Implementation

The MATLAB version (`simulation/matlab/led_model.m`) uses the Nelder-Mead optimization algorithm, which can produce unreliable results with small datasets (5 data points). The Python version uses Levenberg-Marquardt algorithm, which is more stable for this problem.

**Status:** Educational reference only. Use Python for actual design work.

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

MIT License - See LICENSE file for details.

---

**Status:** PCB design and verification complete. Ready for manufacturing.