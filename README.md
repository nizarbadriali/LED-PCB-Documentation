# LED-PCB-Documentation
A simple intro level printed circuit board, fully documented to nurture my deep understanding of circuits. 

## Why Create This?

I know, seems like a lot for a simple led pcb, however while LTSpice includes a 
built-in diode model (1N4148), it's designed for signal diodes with a forward 
voltage of ~0.7V. Real LEDs drop significantly more voltage (~2.0V for red, 
~3.2V for blue), so using the default diode model produces inaccurate simulations.

This project creates **custom SPICE models** for your specific LEDs by:
1. Measuring or obtaining I-V (current-voltage) characteristics
2. Fitting those measurements to a diode model using Python
3. Generating accurate .lib files for LTSpice

With proper LED models, you can:
- ✓ Simulate realistic voltage drops
- ✓ Calculate correct resistor values
- ✓ Verify circuit design before manufacturing
- ✓ Document the design process with real data

## Credits

This project includes modified code based on Ted Yapo's LED modeling work:
- Original: https://hackaday.io/project/12874/log/48368-estimating-spice-diode-models
- GitHub: https://github.com/tedyapo/led-modeling
- Author: Ted Yapo from https://hackaday.io/project/12874-automated-ledlaser-diode-analysis-and-modeling/log/48368-estimating-spice-diode-models 

## Modifications Made

The LED SPICE model fitter script is based on **Ted Yapo's LED modeling project** 
([Hackaday.io](https://hackaday.io/project/12874) | [GitHub](https://github.com/tedyapo/led-modeling)).

### Enhancements to Original Code:

- **Improved Documentation**
  - Added comprehensive docstrings for all functions
  - Included type hints for better code clarity
  - Added detailed comments explaining the 3-stage fitting algorithm

- **Better Code Organization**
  - Cleaner variable naming and structure
  - Enhanced error handling with descriptive messages
  - Added progress tracking during execution

- **Color Terminal Output**
  - Added ANSI color codes for improved readability
  - Success indicators (✓) and error indicators (✗)
  - Formatted header box for clear visual hierarchy
  - Blue/cyan colored results for easy scanning

- **Same Core Algorithm**
  - No changes to the mathematical fitting process
  - Maintains accuracy and reliability of original implementation
  - Compatible output format for LTspice

### Original Algorithm Credit

The three-stage fitting methodology remains unchanged:
1. High-current linear fit → estimate Rs and Vd
2. Low-current non-linear fit → estimate Is and n  
3. Full model optimization → finalize all three parameters

This approach is described in detail in [Ted Yapo's project log](https://hackaday.io/project/12874/log/48368-estimating-spice-diode-models).


## SPICE Models

Generated models are available in the `spice_models/` folder:
- `led_red.lib` - Red LED model
- `led_blue.lib` - Blue LED model

## Results

**Red LED:**

.MODEL led_red D(Is=1.768568e-04,
+               n=8.539763e+00,
+               Rs=6.054497e+01)


**Blue LED:** 

.MODEL led_blue D(Is=7.052100e-07,
+                n=7.539818e+00,
+                Rs=6.277661e+01)

## Simulation Results 


**Circuit:** 5V source → 200Ω resistor → Red LED → GND

Raw data from the run: 



Using the custom red LED SPICE model:

| Parameter | Value |
|-----------|-------|
| LED Forward Voltage (Vd) | 1.92V |
| LED Current (Id) | 15.4 mA |
| Supply Voltage | 5V |
| Resistor Value | 200Ω |

**Conclusion:** The circuit operates safely within the LED's rated specifications.


