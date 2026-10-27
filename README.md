# Signal Simulator

<!-- labview-ci:dashboard -->
## LabVIEW CI

[![LabVIEW CI dashboard](https://img.shields.io/badge/LabVIEW%20CI-dashboard-2ea44f)](https://mipetrov-ni.github.io/Signal-Simulator/)

LabVIEW CI runs on every pull request. See the [**CI dashboard**](https://mipetrov-ni.github.io/Signal-Simulator/) for build status, VI Analyzer results, VI diffs, and mass-compile reports.

A hardware-free LabVIEW **Measurement Plug-In SDK** (MeasurementLink) plug-in that generates synthetic
a sine wave and streams it live to InstrumentStudio.

- **Signal:** sine wave
- **Configuration:** Amplitude, Frequency, Sample Rate, Number of Samples (per window), Update Interval
- **Live data:** a window of `Number of Samples` points is published every `Update Interval` ms with
  `Update Results`, so the InstrumentStudio XY graph scrolls until the measurement is stopped
- **Structure:** configuration, initialization, acquisition and shutdown are separate VIs in a reusable
  signal-generation library; the plug-in class only orchestrates them

## Documentation

| Document | Contents |
|---|---|
| [docs/architecture.md](docs/architecture.md) | UML-style architecture and sequence diagrams, staged components, signal definitions, key classes / APIs / VIs |
| [docs/instrumentstudio-discovery.md](docs/instrumentstudio-discovery.md) | How InstrumentStudio discovers, loads and runs the plug-in |
| [docs/labview-mcp.md](docs/labview-mcp.md) | Using the LabVIEW MCP server with this project |

## Quick start

1. Apply [Dependencies.vipc](Dependencies.vipc) in VIPM to LabVIEW 2026 Q3 (64-bit), then open
   `Signal Simulator.lvproj`. See [Dependencies and CI](#dependencies-and-ci) for the pinned packages.
2. Right-click **Build Specifications > Signal Simulator Plug-In UI** and choose **Build**. This creates
   `BuiltUI\Signal Simulator Plug-In UI.lvlibp`, which InstrumentStudio loads. Rebuild after every UI change.
3. Run `Signal Simulator Plug-In.lvclass : Run Service.vi`. The plug-in registers with the NI Discovery
   Service.
4. In InstrumentStudio open the **Measurement Plug-Ins** pane, add **Signal Simulator Plug-In**, set the amplitude, frequency and sample rate and press Run.

## Dependencies and CI

[Dependencies.vipc](Dependencies.vipc) pins the complete Measurement Plug-In SDK package set to the
versions installed on the development PC:

| VIPM package | Version |
|---|---|
| `ni_measurement_plugin_sdk` | 3.5.4.1 |
| `ni_measurement_plugin_sdk_examples` | 3.5.4.1 |
| `ni_measurement_plugin_sdk_generator` | 3.5.4.1 |
| `ni_measurement_plugin_sdk_service` | 3.5.4.1 |
| `ni_lib_labview_grpc_library` | 1.7.0.1 |
| `ni_lib_labview_grpc_servicer` | 1.7.0.1 |
| `ni_protobuf_types` | 1.0.0.1 |

The configuration targets LabVIEW **26.3 (64-bit)**. It includes the SDK's examples and generator
because they are dependencies of the full SDK package. Package binaries are not embedded; VIPM
downloads the exact versions from the public package repositories, so applying it requires network access.
Open the VIPC in VIPM to review or update the configuration.

The Windows image-build workflow discovers this root-level VIPC when no explicit
`config.container.vipc` list is configured. After adding or updating it, run **Build LabVIEW CI
Image** from GitHub Actions and wait for the repository's Windows worker image to finish building.
Then rerun mass compile, VI Analyzer, snapshots and unit tests against the desired source commit
using that rebuilt image. Merely pushing the VIPC does not update an existing worker image, and
automatic dependency rebuild monitoring is not enabled by this change. If an explicit VIPC list is
configured later, include `Dependencies.vipc` with monitoring enabled for the Windows worker.

LabVIEW and the relevant NI toolkits/licenses remain prerequisites outside this VIPC. InstrumentStudio
and NI Discovery Service are required for an end-to-end plug-in run, not installed by this configuration.
The VIPC has been checked against the installed package metadata and public dependency declarations.
The Windows dependency build has also successfully installed all seven project packages. The installer
verifies final installed versions of required project and test-tooling packages after all fallbacks;
a transient install error does not fail the build if the required versions are subsequently present.
Missing packages, version mismatches and inability to verify the installed set still fail the build.

Full plug-in CI is **Windows-only**: the SDK 3.5.4.1 packages explicitly declare
`Exclusive_OS="Windows x64"`. The Linux worker, build, analysis, snapshot and diff workflows are not
installed for this project. Ubuntu-hosted dashboard/report publishing jobs remain; they do not load
the plug-in into Linux LabVIEW. Keep the Windows-only OS selection when updating the CI tooling.

## Layout

| Folder | Purpose |
|---|---|
| `Signal Simulator Plug-In/` | Plug-in class (derived from the NI SDK), configuration / results typedefs, `Measurement Logic.vi`, `Signal Simulator.measui` (InstrumentStudio UI) |
| `Sine Generator/` | Signal generation engine library (no SDK dependency) |
| `Signal Simulator Plug-In UI/` | Front panel library built into the packed library |
| `docs/` | Documentation |

## Status

Verified in LabVIEW 2026 Q3: the project loads without missing items, every VI is executable, the sine engine
was run for amplitude, length, time axis and phase continuity, and the UI packed library builds into
`Signal Simulator Plug-In\BuiltUI\`. The end-to-end run through InstrumentStudio has not been exercised by the
author of the generator.
