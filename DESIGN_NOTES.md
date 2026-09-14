# Design Notes and Verification

## Circuit and Component Choices

The circuit is `J1 pin 1 (+5V) → R2 (220 Ω) → D1 anode → D1 cathode → J1 pin 2 (GND)`.

For a 15 mA design target and an assumed 2 V LED drop, `(5 - 2)/0.015 = 200 Ω`. A 220 Ω E12 value was selected to reduce current slightly. The 200 Ω value is also a standard E24 value.

With 220 Ω and the assumed 2 V drop, current is approximately 13.64 mA. The fitted LTspice model predicts 14.3515 mA and a 1.84267 V LED drop. The difference follows from the different diode-voltage assumptions; it is not a physical measurement discrepancy.

Predicted resistor dissipation is approximately 45.31 mW, below the intended ¼ W rating at this nominal operating point. Final part selection must check body dimensions, lead diameter, tolerance, and datasheet derating. The LED's allowable current remains dependent on the selected part.

All three components use plated through-hole pads. There are six component pads and zero separate vias. A bottom external copper zone, B.Cu, provides a ground return alongside the routed front ground trace.

## Revisions Recorded During Review

### 1. Restore Standard Power Symbols and Add PWR_FLAGs

The +5V and GND symbols were originally configured as Power output. They were restored to the standard Power input configuration. One PWR_FLAG, with a Power output pin, was connected to each supply net to identify external power and its ground return.

Symbols were updated from the library to resolve symbol-mismatch warnings. The final uploaded ERC result reports zero errors and warnings under the configured checks. No unrecorded initial error count is asserted.

### 2. Assign and Refill the Ground Zone

The original back copper zone had no assigned net. It was assigned to GND and refilled. The saved fill has clearance openings around copper on other nets and thermal connections to J1 pin 2 and D1 pin 1. Supply-net names were synchronized between schematic and PCB.

These are CAD connectivity and geometry checks, not a physical continuity test.

### 3. Replace the Oversized Resistor Footprint and Repair Routing

The original resistor footprint used a 17 × 6 mm body and 20.32 mm pitch. It was replaced with:

`Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P7.62mm_Horizontal`

The affected routing was repaired for the 7.62 mm pad spacing. This footprint is intended for a compatible small axial resistor; a specific purchasable part has not yet been selected.

### 4. Synchronize Manufacturing Exports

Gerbers and Excellon drills were regenerated after changing the footprint. Old standalone drills with the previous resistor hole spacing were removed. The current package is [kicad/gerbers.zip](kicad/gerbers.zip), containing both Gerbers and drills.

The ZIP's resistor holes have 7.62 mm spacing and 0.8 mm diameter. LED holes are 0.9 mm; header holes are 1.0 mm. The NPTH file has no holes because this board contains no non-plated holes.

## PCB Geometry and Rules

| Item | Value | Meaning |
|------|-------|---------|
| Board outline | 100 × 60 mm | Closed rectangular Edge.Cuts outline |
| Board thickness | 1.6 mm | Intended fabrication specification |
| Copper thickness | 35 µm per side | Intended specification recorded in Gerber job file |
| Default netclass clearance | 0.2 mm | Spacing between copper on different nets |
| Ground-zone clearance | 0.5 mm | Zone clearance from copper on other nets |
| Minimum copper-to-edge clearance | 0.5 mm | Copper clearance from board perimeter |
| Actual routed trace width | 0.4 mm | Width used, not a claim about an enforced minimum |
| Thermal gap / spoke width | 0.5 mm / 0.5 mm | Ground-zone thermal connection settings |

| Routed connection | Length |
|-------------------|--------|
| J1 pin 1 to R2 | 35.93 mm |
| R2 to D1 anode | 51.58 mm |
| D1 cathode to J1 pin 2 | 77.79 mm |
| Total front trace length | 165.31 mm |

These low-current DC routes do not require length matching. The ground plane provides a parallel return path, so front trace lengths alone do not determine total circuit interconnect resistance.

The handwritten copper-loss estimate illustrates a 35 mm section using assumed 0.4 mm width and 35 µm copper. It is not total board dissipation. Using copper resistivity 1.68 × 10⁻⁸ Ω·m gives approximately 0.042 Ω; rounding to 0.05 Ω gives 11.25 µW at 15 mA. Resistor dissipation is a separate quantity. The handwritten description of 15 mA as necessary to keep an LED on should instead be understood as this project's selected design target.

## Verification Evidence

| Check | Recorded outcome | Evidence |
|-------|------------------|----------|
| ERC | Zero reported errors/warnings | [ERC screenshot](kicad/Screenshot%202026-09-13%20at%206.46.56%20PM.png) |
| DRC | Zero reported violations and unconnected items | [Final DRC/parity screenshot](kicad/Screenshot%202026-09-13%20at%207.38.18%20PM.png) |
| Schematic-to-PCB parity | Zero differences; test enabled | Same final DRC/parity screenshot |
| LTspice operating point | Converged; 14.3515 mA circuit current | [Simulation log](simulation/ltspice/led_circuit.log) |

The project records no individual ERC or DRC exclusions. Four ERC categories are ignored: footprint filters, four-way junctions, single global labels, and simulation-model issues. Five DRC categories are ignored: footprint-filter mismatch, footprint-type mismatch, missing courtyard, and plated/non-plated holes inside courtyards. Core checks for shorts, clearance, unconnected items, and thermal connections remain enabled.

During source-file review, all six PCB pads met their intended trace endpoints. The ZIP's front traces, pad positions/sizes, mask openings, back fill vertices, and drill coordinates were compared against the PCB and matched. This comparison supplements the uploaded KiCad results; it is not an independent native KiCad DRC run or a manufacturer acceptance test.

## Export Procedure

After any geometry change:

1. Update the PCB from the saved schematic, refill zones, save, and run DRC with schematic parity enabled.
2. In Plot, select Gerber format and F.Cu, B.Cu, F.Mask, B.Mask, F.Silkscreen, B.Silkscreen, and Edge.Cuts. Through-hole assembly does not require paste layers here.
3. Keep zone-fill checking enabled and plot the Gerbers.
4. Use Generate Drill Files to generate Excellon drills separately. Use the same output directory and consistent coordinate origin: absolute for both Gerbers and drills in this package.
5. Inspect copper, outline, masks, and hole alignment together in Gerber Viewer.
6. Replace the manufacturing ZIP with the newly generated set. Do not mix exports from different board revisions.

## Remaining Work

- Document I–V data provenance; the existing model does not establish real-LED performance.
- Select and document manufacturer part numbers and datasheets.
- Add +5V and GND silkscreen labels beside J1 before the next fabrication revision.
- Assemble and test the board, recording supply voltage, LED voltage, resistor voltage/resistance, and inferred current.
- Compare measured results with predictions and document any changes.

Physical assembly and bench testing are pending. The files demonstrate completed CAD and simulation work, not physical validation.

[Back to project overview](README.md) · [SPICE modeling details](SPICE_MODELING.md)
