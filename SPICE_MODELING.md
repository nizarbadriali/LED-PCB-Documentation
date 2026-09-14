# SPICE Model Fitting Methodology

## Scope and Data Provenance

The Python script fits a static diode equation with series resistance to supplied I–V data. The source, LED part number, equipment, date, and measurement temperature are not documented. Consequently, these results demonstrate fitting and circuit simulation; they do not independently validate a physical LED.

The red dataset in [workdir/led_red.dat](workdir/led_red.dat) contains:

| Current (mA) | Voltage (V) |
|--------------|-------------|
| 1 | 0.5 |
| 5 | 1.0 |
| 10 | 1.5 |
| 15 | 2.0 |
| 20 | 2.2 |

File currents are expressed in amperes. The 0.5 V at 1 mA point is unusual for a conventional visible red LED and should be verified before using the data to represent a selected component. A blue dataset is also supplied in [workdir/led_blue.dat](workdir/led_blue.dat).

## Model Equation

```text
V = n · Vt · ln(1 + I/Is) + I · Rs
```

| Symbol | Meaning |
|--------|---------|
| V, I | Terminal voltage and current |
| Is | Saturation-current model parameter, amperes |
| n | Ideality-factor model parameter |
| Rs | Series-resistance model parameter, ohms |
| Vt | Thermal voltage; fixed at 0.026 V by the fitter |

The saved LTspice log uses 27°C. The fitter's fixed thermal voltage does not establish the measurement temperature. No temperature sweep, reverse-bias behavior, or transient response has been validated.

## Python Fitting Procedure

Source: [simulation/python/led_model.py](simulation/python/led_model.py).

1. **High-current linear approximation:** Fit `V ≈ I · Rs + Voffset`, including an intercept, to the selected highest-current points. This initializes the model; it does not prove that the junction contribution is negligible.
2. **Low-current fit:** Fit the logarithmic diode-voltage expression `V = n · Vt · ln(1 + I/Is)` to the selected lowest-current points. The Stage 1 offset initializes the fitting scale; it is not subtracted from the dataset.
3. **Full-model fit:** Refine scaled parameters corresponding to Is, n, and Rs with SciPy's unconstrained `curve_fit` using its Levenberg–Marquardt method. The objective is the sum of squared voltage residuals over all supplied points.

With five points, the initialization stages each use two points. The automatic initial-point loop selects the same subsets for this dataset, so it should not be described as demonstrating robustness across different starting conditions. The reviewed run emitted a covariance-estimation warning in the low-current fit.

## Red Model and Fit Quality

```spice
.MODEL led_red D(Is=1.768568e-04,
+               n=8.539763e+00,
+               Rs=6.054497e+01)
```

| Metric | Approximate value | Definition |
|--------|-------------------|------------|
| Script-reported error | 0.1331 V | Square root of the sum of squared voltage residuals |
| RMSE | 0.0595 V | Square root of the mean of squared voltage residuals |
| Largest absolute residual | 0.1033 V | Largest absolute voltage difference at a supplied point |

These errors were evaluated using the red reference model and Vt = 0.026 V. The fit approximates the data; it does not pass through every point. RMSE is neither mean absolute error nor a ±60 mV bound. Fit residuals describe agreement with the input data, not independent measurement accuracy or uncertainty in future predictions.

The parameters are empirical fitting results. Their numerical convergence alone does not establish physically representative parameters for a real LED. Predictions beyond the supplied 1–20 mA current range, and at other temperatures, are unvalidated. Additional reliable, well-distributed measurements can improve the model assessment.

## LTspice Operating Point

The [LTspice schematic](simulation/ltspice/led_circuit.asc) includes a 5 V source, 220 Ω resistor, diode referencing `led_red`, and the complete model directive.

| Quantity | Saved or calculated result |
|----------|----------------------------|
| LED anode voltage relative to ground | 1.84267 V |
| LED cathode voltage relative to ground | 0 V |
| Resistor voltage drop | 3.15733 V |
| Circuit current magnitude | 14.3515 mA |
| Resistor dissipation | 45.31 mW |

See [led_circuit.log](simulation/ltspice/led_circuit.log). The log's negative resistor/source currents reflect reference directions; the series-current magnitude is 14.3515 mA.

A fixed 0.7 V diode-drop assumption would give `(5 - 0.7)/220 = 19.55 mA`. This is an illustrative calculation, not a recorded 1N4148 simulation. The 1N4148 models a silicon signal diode, not a red LED; its actual forward voltage depends on operating conditions.

## Running and Reusing the Model

From the repository root:

```bash
python3 simulation/python/led_model.py
```

The script reads `workdir/*.dat` and prints model directives. Save model text manually if needed. To reuse the red model, copy the complete three-line directive above into an LTspice SPICE directive and set the diode's model name to `led_red`.

The [reference library](models/red_led.lib) and model embedded in the `.asc` file are separate copies. Update both deliberately when changing the model. The KiCad schematic does not have this custom SPICE model attached.

## MATLAB Implementation

[simulation/matlab/led_model.m](simulation/matlab/led_model.m) is retained as an educational implementation with reported fitting problems. It uses `fminsearch` (Nelder–Mead) and applies parameter clamps when extracting its outputs.

A clamp is not evidence that a particular run reached that bound. No saved MATLAB run is supplied here, so specific failed parameter values are not asserted. This implementation has not been established as a reliable alternative to the Python workflow. Any future failure analysis should include the input, MATLAB version, actual output, and residuals.

## References

- [Ted Yapo's LED modeling source](https://github.com/tedyapo/led-modeling)
- [LED modeling project](https://hackaday.io/project/12874)
- [Estimating SPICE diode models](https://hackaday.io/project/12874/log/48368-estimating-spice-diode-models)
- [SciPy curve_fit documentation](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.curve_fit.html)
- [MATLAB fminsearch documentation](https://www.mathworks.com/help/matlab/ref/fminsearch.html)

[Back to project overview](README.md)
