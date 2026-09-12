# LED PCB Documentation

A complete design, simulation, and manufacturing documentation for a simple 5V LED circuit with custom SPICE models.

**Project Goal:** Demonstrate professional circuit design workflow from simulation through PCB layout.

## Quick Start

### 1. Generate LED SPICE Models

```bash
cd simulation/python
python3 led_model.py
```

Output: Custom SPICE models (`red_led.lib`, `blue_led.lib`) based on measured LED data.

### 2. Verify Circuit in LTspice

1. Open `simulation/ltspice/led_circuit.asc` in LTspice
2. Add SPICE model directive with your LED model
3. Click Run to simulate
4. Verify: LED current ~15mA, voltage drop ~2V ✓

### 3. Design PCB in KiCad

1. Open `kicad/led_pcb.kicad_sch` 
2. Design schematic with verified values
3. Layout PCB with 220Ω resistor and red LED
4. Export Gerber files for manufacturing

## Circuit Design

**Topology:** 5V Supply → 220Ω Resistor → Red LED → Ground

| Component | Value | Purpose |
|-----------|-------|---------|
| V1 | 5V DC | Power supply |
| R1 | 220Ω | Current limiting resistor |
| D1 | led_red | Red LED (custom SPICE model) |

**Design Calculations:**
```
Supply: 5V
LED drop: ~2.0V
Resistor drop: 3.0V
Target current: 15mA (safe)
R = 3.0V / 15mA = 200Ω → Use 220Ω (standard value)
Actual current: 13.6mA ✓ Safe
```

## Project Structure

```
LED-PCB-DOCUMENTATION/
├── simulation/
│   ├── python/          → LED SPICE model fitter
│   │   ├── led_model.py
│   │   └── README.md
│   ├── matlab/          → Alternative implementation (educational)
│   │   ├── led_model.m
│   │   └── README.md
│   └── ltspice/         → Circuit simulation files
│       ├── led_circuit.asc
│       ├── led_circuit.log
│       └── README.md
├── models/              → Generated SPICE models
│   ├── red_led.lib
│   ├── blue_led.lib
│   └── workdir/         → Measured LED data
│       ├── led_red.dat
│       └── led_blue.dat
├── kicad/               → PCB design files
│   ├── led_pcb.kicad_sch
│   └── led_pcb.kicad_pcb
├── README.md            → This file
└── LICENSE              → MIT License
```

## Tools Used

- **Python** - SPICE model fitting (recommended)
- **MATLAB** - Alternative fitting algorithm (educational)
- **LTspice** - Circuit simulation & verification
- **KiCad** - PCB schematic & layout design

## The Workflow

### Step 1: Measured Data → SPICE Model

```
LED I-V measurements (current vs voltage)
        ↓
Python/MATLAB curve fitting
        ↓
Extract diode parameters (Is, n, Rs)
        ↓
Generate .lib SPICE model
```

**Files involved:**
- Input: `workdir/led_red.dat`, `workdir/led_blue.dat`
- Script: `simulation/python/led_model.py`
- Output: `models/red_led.lib`, `models/blue_led.lib`

### Step 2: SPICE Model → Circuit Simulation

```
SPICE model (.lib)
        ↓
LTspice schematic with model
        ↓
Run simulation
        ↓
Verify voltage drops & current
```

**Files involved:**
- Input: `models/red_led.lib`
- Circuit: `simulation/ltspice/led_circuit.asc`
- Output: `simulation/ltspice/led_circuit.log`

**Expected Results:**
```
V(LED) ≈ 1.92V      ✓ Matches red LED spec
I(LED) ≈ 15.4mA     ✓ Safe (max typically 20-30mA)
```

### Step 3: Verified Design → PCB Layout

```
Verified component values & currents
        ↓
KiCad schematic with 220Ω resistor
        ↓
PCB layout with proper traces & vias
        ↓
Generate Gerber files
        ↓
Send to PCB manufacturer
```

**Files involved:**
- Input: Simulation results + verified values
- Design: `kicad/led_pcb.kicad_sch` + `kicad/led_pcb.kicad_pcb`
- Output: Gerber files for manufacturing

## Key Design Decisions

### Why Custom SPICE Models?

LTspice's built-in 1N4148 diode model is for signal diodes (~0.7V drop), not LEDs (~2.0V drop).

**Problem:** Using wrong model
```
Wrong model (1N4148):  Vd=0.73V, Id=21.3mA  ✗
Correct model (led_red): Vd=1.92V, Id=15.4mA ✓
```

### Why Python Over MATLAB?

Both implement the same algorithm (3-stage Levenberg-Marquardt fitting), but:

| Aspect | Python | MATLAB |
|--------|--------|--------|
| Stability | Excellent | Fair (numerical issues) |
| Results | Accurate ✓ | Can fail with small datasets |
| Dependencies | scipy, numpy | MATLAB license required |
| Portability | All platforms | Limited |
| Recommended | YES ✓ | Educational only |

For this project: **Use Python**

### Why 220Ω?

Theoretical calculation gives 200Ω, but:
- 200Ω is not a standard manufactured resistor value
- 220Ω is the nearest standard E12 series resistor
- Actual current with 220Ω: 13.6mA (still safe, within 10-20mA target)

## Installation & Usage

### Python SPICE Fitter

**Requirements:**
```bash
pip3 install scipy numpy
```

**Run:**
```bash
cd simulation/python
python3 led_model.py
```

**Input:** `.dat` files with 2 columns (current, voltage)
**Output:** `.MODEL` SPICE directives for LTspice

See `simulation/python/README.md` for detailed guide.

### LTspice Simulation

**Requirements:** LTspice installed

**Steps:**
1. Open `simulation/ltspice/led_circuit.asc`
2. Add SPICE model: `.MODEL led_red D(Is=1.768568e-04, n=8.539763e+00, Rs=6.054497e+01)`
3. Click Run
4. Verify results in Command Window

See `simulation/ltspice/README.md` for detailed guide.

### KiCad PCB Design

**Requirements:** KiCad 6.0+

**Steps:**
1. Open `kicad/led_pcb.kicad_sch`
2. Create schematic with verified component values
3. Switch to PCB layout view
4. Place components and route traces
5. Create ground plane
6. Export Gerber files

Coming soon: Full KiCad tutorial.

## Documentation

- **SPICE Modeling Theory:** See `simulation/python/README.md`
- **Circuit Simulation Details:** See `simulation/ltspice/README.md`
- **MATLAB Implementation:** See `simulation/matlab/README.md` (known limitations explained)

## Verification Checklist

- [x] Custom SPICE models generated from measured data
- [x] Circuit simulated and verified in LTspice
- [x] LED current confirmed safe (15.4mA < 30mA max)
- [x] LED voltage drop realistic (~2V for red)
- [x] Resistor value uses standard manufactured value (220Ω)
- [ ] KiCad PCB layout complete
- [ ] Gerber files exported
- [ ] Ready for manufacturing

## Credits

**LED SPICE Modeling Algorithm:**
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

**Status:** Simulation & verification complete. Ready for PCB design phase.