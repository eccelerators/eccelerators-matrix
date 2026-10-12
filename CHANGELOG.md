# Changelog

All notable changes to this package are documented here.

## 0.1.0

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
