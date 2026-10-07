# LabVIEW MCP

This repository is wired to the [Zuehlke/labview-mcp](https://github.com/Zuehlke/labview-mcp) server, which
lets an AI assistant read, generate and run LabVIEW code through LabVIEW's embedded AI gRPC service.

## Configuration in this repository

| File | Client |
|---|---|
| `.vscode/mcp.json` | VS Code / GitHub Copilot (`servers` schema) |
| `.mcp.json` | Claude Code and other clients (`mcpServers` schema) |

Both start `C:\Tools\labview-mcp\bin\LabVIEWMCP.exe` over stdio. Adjust the path if you install the server
elsewhere (install instructions: the upstream repository's `docs/guide/install.md`).

## Requirements

- Windows x64, LabVIEW 2026 Q3, LabVIEW running with its AI gRPC service (starts with NIGEL, the LabVIEW
  AI assistant) before the tools are used. `lvai_status` shows whether the connection works.
- The upstream project is research grade and uses an unpublished NI interface; read its `safety.md` first.

## How this project was generated with it

| Task | Tools |
|---|---|
| Read the template VIs | `lvai_convert_vis_to_aixml`, `lvai_describe_class`, `lvai_describe_ctl` |
| Signal engine, configuration, acquisition, shutdown, UI VIs | AIXML written by hand, `lvai_generate_vi` / `lvai_generate_vis` |
| Put the VIs into the library | `lvai_add_to_library` |
| Replace `Measurement Logic.vi` in the plug-in class | `lvai_add_class_method`, `lvai_bind_pane_typedef` |
| Check the result | `lvai_exec_state`, `lvai_run_vi_as_top_level`, `lvai_describe_project` |
| Build the UI packed library | `lvai_build_from_build_specification` |

## Lessons learned (worth knowing before editing)

- **Typedefs that belong to a class lose their link when regenerated.** `lvai_create_typedef` writes a
  `.ctl` without the owning-library link, so LabVIEW reports "Missing typedef". The two typedefs in
  `Signal Simulator Plug-In/` were regenerated and then given back their class link by patching the
  library-name and library-link blocks with pylabview.
- **Re-adding a class member under the same name can fail with error 56003** while an old copy of that name is
  still loaded in the running LabVIEW. Adding the VI under a temporary name, closing the project, renaming
  the file and the `.lvclass` entry avoids it without restarting LabVIEW.
- **AIXML cannot express an Event Structure.** `Measurement UI.vi` was therefore regenerated with a
  dequeue-driven loop (the same `Initialize` / `Post UI Update` / `Exit` messages) and without the template's
  `Panel Close?` event case.
