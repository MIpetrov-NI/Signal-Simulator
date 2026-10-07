# Signal Simulator

A hardware-free LabVIEW **Measurement Plug-In SDK** (MeasurementLink) plug-in that generates synthetic
waveforms and streams them live to InstrumentStudio.

- **Signal types:** sine, square, frequency sweep (linear chirp)
- **Configuration:** Amplitude, Frequency, Sample Rate, Noise Level, Signal Type
- **Live data:** a block of about 100 ms is published every 100 ms with `Update Results`, so the
  InstrumentStudio XY graph keeps updating until the measurement is stopped
- **Structure:** configuration, initialization, acquisition and shutdown are separate VIs in a reusable
  signal-generation library; the plug-in class only orchestrates them

## Documentation

| Document | Contents |
|---|---|
| [docs/architecture.md](docs/architecture.md) | UML-style architecture and sequence diagrams, staged components, signal definitions, key classes / APIs / VIs |
| [docs/instrumentstudio-discovery.md](docs/instrumentstudio-discovery.md) | How InstrumentStudio discovers, loads and runs the plug-in |
| [docs/labview-mcp.md](docs/labview-mcp.md) | Using the LabVIEW MCP server with this project |

## Quick start

1. Open `Signal Simulator.lvproj` in LabVIEW 2026 (Measurement Plug-In SDK installed).
2. Right-click **Build Specifications > Signal Simulator Plug-In UI** and choose **Build**. This creates
   `BuiltUI\Signal Simulator Plug-In UI.lvlibp`, which InstrumentStudio loads. Rebuild after every UI change.
3. Run `Signal Simulator Plug-In.lvclass : Run Service.vi`. The plug-in registers with the NI Discovery
   Service.
4. In InstrumentStudio open the **Measurement Plug-Ins** pane, add **Signal Simulator Plug-In**, choose a
   signal type and press Run.

## Layout

| Folder | Purpose |
|---|---|
| `Signal Simulator Plug-In/` | Plug-in class (derived from the NI SDK), configuration / results typedefs, `Measurement Logic.vi`, `Signal Simulator.measui` (InstrumentStudio UI) |
| `Signal Generator/` | Signal generation engine library (no SDK dependency) |
| `Signal Simulator Plug-In UI/` | Front panel library built into the packed library |
| `docs/` | Documentation |

## Status

Verified in LabVIEW 2026 Q3: the project loads without missing items, every VI is executable, the signal
engine was run for all three signal types and noise (peak values, zero mean over whole cycles, block length, next start sample, noise level) and the
UI packed library builds. The end-to-end run through InstrumentStudio has not been exercised yet.


