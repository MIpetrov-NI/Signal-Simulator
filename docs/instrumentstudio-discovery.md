# How InstrumentStudio discovers and loads the plug-in

This describes the MeasurementLink flow used by every Measurement Plug-In SDK plug-in. The file and VI
names are the ones in this project.

## 1. The plug-in is a gRPC service that registers itself

1. A user (or the build's launcher) runs `Signal Simulator Plug-In.lvclass:Run Service.vi`. It opens its
   panel hidden and calls the SDK's `Run Service.vi`.
2. The SDK's `Create Measurement Services.vi` creates the **Measurement Service V1** (metadata) and
   **V2** (measure) gRPC servers on a free local port and dispatches to the plug-in class through
   dynamic dispatch.
3. `Register to Discovery Service.vi` calls `DiscoveryService.RegisterService` on the **NI Discovery
   Service** (`NI.Discovery.V1.Service`, a Windows background process installed with MeasurementLink /
   InstrumentStudio). The registration carries:
   - the host and port of the gRPC server,
   - the service interface names (`ni.measurementlink.measurement.v1/v2.MeasurementService`),
   - the **service descriptor** from `Get Service Descriptor.vi`: display name, version, description,
     description URL, annotations (collection, tags) and the unique **service class**
     (`Signal Simulator Plug-In_LabVIEW`).
4. The discovery service address is not hard-coded. Clients and plug-ins read it from
   `%ProgramData%\National Instruments\MeasurementLink\Discovery\v1\DiscoveryService.json`
   (`Get Discovery Service Address.vi` in the SDK).

## 2. InstrumentStudio finds it

1. InstrumentStudio reads the same `DiscoveryService.json`, connects to the discovery service and calls
   `EnumerateServices`. Every running plug-in that has registered appears in the **Measurement
   Plug-Ins** list, grouped by the *collection* annotation and searchable by its *tags*.
2. When the user adds the plug-in to a panel, InstrumentStudio connects to the registered port and calls
   `GetMetadata` (V1/V2). The response describes the measurement:
   - configuration parameters (names, types, defaults) from `Measurement Configuration.ctl`,
   - result parameters from `Measurement Results.ctl`,
   - type specializations from `Get Type Specializations.vi`,
   - the user-interface files from `Get User Interface Information.vi`.
   The parameter names are the labels of the typedef elements; this is why the UI labels must match.
3. Plug-ins that stop (or crash) unregister, or are removed once the discovery service can no longer
   reach them, and disappear from the list.

## 3. InstrumentStudio loads the user interface

`Get User Interface Information.vi` returns
`BuiltUI\Signal Simulator Plug-In UI.lvlibp\Measurement UI.vi`. A relative path is resolved against the folder of `Measurement Logic.vi`, so the build writes to `Signal Simulator Plug-In\BuiltUI\`. The UI VI must be reentrant (preallocated clone) or opening it fails with error 1096.
InstrumentStudio loads that VI from the **packed library**, which is why the packed library must be
rebuilt after every change to the UI (build specification *Signal Simulator Plug-In UI*, output
`BuiltUI\`). A `.measui` file made with the Measurement Plug-In UI Editor can be returned instead of or
in addition to the VI.

The framework writes configuration values into the controls and result values into the indicators **by
label**. It sends the messages `Initialize`, `Post UI Update` and `Exit` to a queue named after the UI
VI clone; `Measurement UI.vi` services that queue.

## 4. Running a measurement and live display

1. The user presses Run. InstrumentStudio calls `Measure` (V2, server-streaming) with the configuration.
2. The SDK calls the plug-in's `Measure.vi`, which converts the variant to the configuration typedef and
   calls `Measurement Logic.vi`.
3. Every time `Measurement Logic.vi` calls `Measure Call Context : Update Results.vi`, the SDK sends an
   intermediate response on the stream and InstrumentStudio refreshes the **Waveform** XY graph. This
   project does that about every 100 ms. InstrumentStudio keeps no history, so each update contains the
   complete current block.
4. The user presses Stop. The SDK marks the call cancelled, `Is Canceled.vi` returns true, the loop ends,
   `Shutdown Generator.vi` runs and the last block is returned as the final response, which completes the
   stream.

## Starting the plug-in

- **From the LabVIEW project:** build *Signal Simulator Plug-In UI* (Build Specifications), then run
  `Signal Simulator Plug-In.lvclass:Run Service.vi`. The service stays registered until the VI is
  stopped.
- **As an executable:** this project has no application build specification yet. The Measurement Plug-In
  SDK project template provides one; its `Post-Build Action.vi` (kept in `Signal Simulator Plug-In/Build Assets`)
  copies the UI next to the executable and writes the `.serviceconfig` file that lets the MeasurementLink
  service manager start the plug-in on demand.


