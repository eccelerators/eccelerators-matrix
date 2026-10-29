# Changelog

All notable changes to this package are documented here.

## 1.0.0

### Added

- Logical panel grids through `IMatrixLayout` and `Hub75Display<PANELS_X,
  PANELS_Y, PANEL_WIDTH, PANEL_HEIGHT, CHAIN_ORDER, ...>`.
- Row-major, reversed and serpentine mappings for HUB75 serial chains.
- Full-canvas, tiled and single-panel rendering operations on `IMatrixRenderer`.
- Per-panel RGB gain for compensating small color differences between panels.
- A two-panel scan test and panel-chain wiring documentation with a Mermaid
  architecture diagram.

### Changed

- `Hub75Controller` and `Hub75Framebuffer` now accept an exact shift-column
  count, allowing chained widths that are not powers of two.
- `Hub75Display` presents a panel grid as one logical canvas and stores pixels
  in physical scan order.
- The default facade uses one 64 by 64 RGB666 panel. `Hub75Display<2, 1>` creates
  a 128 by 64 canvas from two chained panels.
- The package now depends on `Livt.Math 1.4.0`.

### Compatibility

- The `Hub75Display`, `Hub75Controller` and `Hub75Framebuffer` generic parameter
  lists changed. Update explicit instantiations to the new geometry model.
- Implementations of `IMatrixRenderer` must provide `RenderTiled` and
  `RenderPanel` in addition to `Render`.

## 0.1.0

### Added

- Add IMatrixRenderer and MatrixRenderer with optional frame pacing and explicit color conversion.
- Extract reusable matrix display components from livt-matrix-app into
  Eccelerators.Matrix, with the hardware backend in Eccelerators.Matrix.Hub75.
- Provide display, bitmap and color-converter interfaces, portable bitmap
  painting, composable color conversion and context-derived animation pacing.
- Provide a double-buffered binary-address HUB75 backend with RGB888 input and
  RGB444/RGB666 output; rename its storage component to Hub75Framebuffer.
- Separate 17 library tests from the application's scene and CLI tests.
- Document ownership, presentation, storage and timing contracts.
- Align source and test layout with the Livt design guidelines.
- Validate generic timing parameters at component scope.
- Add a standalone gradient example and consumer usage documentation.
- Use the same MIT license as the Eccelerators CLI and Livt base packages.
