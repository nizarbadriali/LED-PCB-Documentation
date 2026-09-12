#!/usr/bin/env python3

import glob
import sys
from typing import Tuple
import numpy as np
from scipy.optimize import curve_fit

# Color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

DAT_FILES_PATTERN = 'workdir/*.dat'

def diode_model(Is: float, n: float, Rs: float, current: np.ndarray, Vt: float = 26e-3) -> np.ndarray:
    """
    Full SPICE diode model with series resistance.
    
    V = n*Vt*ln(I/Is + 1) + I*Rs
    
    Args:
        Is: Reverse saturation current
        n: Ideality factor
        Rs: Series resistance
        current: Current array
        Vt: Thermal voltage (default ~26mV at room temp)
    
    Returns:
        Voltage array
    """
    return n * Vt * np.log(current / Is + 1) + current * Rs

def auto_fit_diode_model(current: np.ndarray, voltage: np.ndarray, Vt: float = 26e-3) -> Tuple:
    """
    Automatically fit diode model by trying multiple initialization points.
    Returns the fit with lowest error.
    
    Args:
        current: Measured current array
        voltage: Measured voltage array
        Vt: Thermal voltage
    
    Returns:
        Tuple: (Is, n, Rs, error, residual_model_points, diode_model_points)
    """
    least_err = np.inf
    found_solution = False
    
    for i in range(2, current.size):
        try:
            Is, n, Rs, err, r_pts, d_pts = fit_diode_model(current, voltage, i, Vt)
        except Exception as e:
            continue
        
        found_solution = True
        
        if err < least_err:
            best_Is = Is
            best_n = n
            best_Rs = Rs
            best_r_pts = r_pts
            best_d_pts = d_pts
            least_err = err
    
    if found_solution:
        return best_Is, best_n, best_Rs, least_err, best_r_pts, best_d_pts
    else:
        raise RuntimeError('No valid solution found after trying all initial conditions')

def fit_diode_model(current: np.ndarray, voltage: np.ndarray, initial_points: int = 1e6, 
                    Vt: float = 26e-3, n_guess: float = 1.5) -> Tuple:
    """
    Three-stage diode model fitting algorithm.
    
    Stage 1: Linear fit on high-current points -> Rs and Vd
    Stage 2: Non-linear fit on low-current points -> Is and n
    Stage 3: Full non-linear fit on all points -> final Is, n, Rs
    
    Args:
        current: Measured current array
        voltage: Measured voltage array
        initial_points: Number of initial data points to use
        Vt: Thermal voltage
        n_guess: Initial guess for ideality factor
    
    Returns:
        Tuple: (Is, n, Rs, error, residual_model_points, diode_model_points)
    """
    N = min(current.size // 2, int(initial_points))
    M = min(current.size // 2, int(initial_points))
    
    # ===== STAGE 1: High-current linear model =====
    # For high currents, voltage ≈ I*Rs (dominates over exponential term)
    Pv = np.polyfit(current[-N:], voltage[-N:], 1)
    Rs = Pv[0]
    Vd = Pv[1]
    
    r_model_points = np.polyval(Pv, current)
    
    # ===== STAGE 2: Low-current exponential model =====
    # Fit n*Vt*ln(I/Is + 1) to low-current data
    b_scale_simple = n_guess * Vt
    c_scale_simple = np.log((np.exp(Vd / (n_guess * Vt)) - 1) / current[-N])
    
    def simple_diode(current, b, c):
        return b * b_scale_simple * np.log(np.exp(c * c_scale_simple) * current + 1)
    
    p_guess = [1, 1]
    
    try:
        p_opt, p_cov = curve_fit(simple_diode, current[0:M], voltage[0:M], p0=p_guess)
    except Exception as e:
        raise RuntimeError('Initial diode fit failed')
    
    d_model_points = simple_diode(current, *p_opt)
    
    # ===== STAGE 3: Full model optimization =====
    # Fit all three parameters (Is, n, Rs) simultaneously
    def full_diode(current, b, c, a):
        return b * b_scale * np.log(c * c_scale * current + 1) + a * a_scale * current
    
    a_scale = Rs
    b_scale = p_opt[0] * b_scale_simple
    c_scale = np.exp(p_opt[1] * c_scale_simple)
    p_guess = [1, 1, 1]
    
    try:
        p_opt, p_cov = curve_fit(full_diode, current, voltage, p0=p_guess)
    except Exception as e:
        raise RuntimeError('Final diode fit failed')
    
    # Calculate error
    err = np.sqrt(np.sum(np.square(voltage - full_diode(current, *p_opt))))
    
    # Extract final parameters
    Rs = p_opt[2] * a_scale
    n = p_opt[0] * b_scale / Vt
    Is = 1 / (p_opt[1] * c_scale)
    
    return Is, n, Rs, err, r_model_points, d_model_points

def main():
    """Main entry point - processes all .dat files and generates SPICE models."""
    
    print(f"\n{Colors.BOLD}{Colors.CYAN}╔══════════════════════════════════════╗")
    print(f"║   LED SPICE Model Fitter              ║")
    print(f"║   Based on Ted Yapo's LED Modeling    ║")
    print(f"╚══════════════════════════════════════╝{Colors.ENDC}\n")
    
    datFiles = glob.glob(DAT_FILES_PATTERN)
    
    if not datFiles:
        print(f"{Colors.RED}✗ No data files found matching: \"{DAT_FILES_PATTERN}\"{Colors.ENDC}")
        print(f"  Make sure .dat files are in: workdir/")
        sys.exit(1)
    
    print(f"{Colors.GREEN}✓ Found {len(datFiles)} data file(s){Colors.ENDC}\n")
    
    for datFile in datFiles:
        print(f"{Colors.BLUE}Processing:{Colors.ENDC} {datFile}")
        
        try:
            data = np.loadtxt(datFile)
            currents = data[:, 0]
            voltages = data[:, 1]
            
            print(f"  Data points: {len(currents)}")
            print(f"  Current range: {currents.min():.3e} to {currents.max():.3e} A")
            print(f"  Voltage range: {voltages.min():.3f} to {voltages.max():.3f} V")
            
            # Fit the model
            Is, n, Rs, err, r_pts, d_pts = auto_fit_diode_model(currents, voltages)
            
            # Extract filename for model name
            model_name = datFile.split('/')[-1].replace('.dat', '').replace(' ', '_').lower()
            
            print(f"\n{Colors.GREEN}✓ Fit successful!{Colors.ENDC}")
            print(f"  Fit error: {err:.6e}")
            print(f"\n{Colors.BOLD}SPICE Model:{Colors.ENDC}")
            print(f"{Colors.CYAN}.MODEL {model_name} D(Is={Is:.6e},")
            print(f"+                    n={n:.6e},")
            print(f"+                    Rs={Rs:.6e}){Colors.ENDC}")
            print()
        
        except Exception as e:
            print(f"{Colors.RED}✗ Error processing {datFile}: {str(e)}{Colors.ENDC}\n")
            continue

if __name__ == '__main__':
    main()