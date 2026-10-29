# Eccelerators.Matrix

`Eccelerators.Matrix` provides reusable matrix-display components for Livt FPGA
applications: RGB888 drawing, bitmap sources, composable color conversion and
animation pacing. Its first hardware backend drives binary-address HUB75 panels
with double buffering and RGB444 or RGB666 output.

Applications own their pictures, animation state and controls. Board projects
own clock/reset bindings, pin constraints and vendor integration. The drawing
API can also be used with another display implementation.

## 📦 Package

Add the package to your project:

```toml
[dependencies]
"Eccelerators.Matrix" = "1.0.0"
```

`Eccelerators.Matrix` version `1.0.0` depends on `Livt.Math 1.4.0`.

```livt
using Eccelerators.Matrix
using Eccelerators.Matrix.Hub75
```

## 📚 Namespaces

`Eccelerators.Matrix` contains the portable drawing and color APIs:

| Component or interface | Purpose |
|---|---|
| `IMatrixDisplay` | Scheduled pixel drawing and complete-image presentation |
| `IMatrixLayout` | Logical panel-grid geometry independent of cable order |
| `IMatrixBitmap` | Read-only RGB888 pixels and image dimensions |
| `IMatrixRenderer` | Complete-image rendering and presentation contract |
| `MatrixRenderer<FRAME_TIME>` | Clear, convert, draw, optionally pace and present |
| `MatrixPainter` | Portable bitmap drawing, clipping and optional conversion |
| `IColorConverter` | Interchangeable RGB888-to-RGB888 conversion |
| `ColorPipeline` | Ordered composition of two borrowed converters |
| `IdentityColorConverter` | Preserve pixel values |
| `GammaColorConverter` | Bypass, sRGB decoding or power-2.2 conversion |
| `WhiteBalanceColorConverter` | Independent channel gains from 0 to 100 percent |
| `BrightnessColorConverter` | Overall gain from 0 to 100 percent |
| `MatrixColor` | Static RGB packing and fixed-format conversion helpers |
| `MatrixFramePacer` | Context-derived frame deadlines |
| `MatrixPictureSequence` | Picture selection with a timed hold after presentation |

`Eccelerators.Matrix.Hub75` contains the configurable `Hub75Display` drawing facade,
`Hub75Controller` scan engine and `Hub75Framebuffer` image storage. Most consumers
only need the facade. `Hub75ChainOrder` maps logical tiles to a physical serial
chain. Per-panel RGB gain compensates small panel-to-panel color differences.
`ColorGain` is a converter implementation helper.

## 🔌 Common Drawing API

One scheduled client owns the drawing transaction. Pixel coordinates start at
the top left; colors are packed as `0xRRGGBB`.

```livt
// Inside the application's sole drawing process:
display.Clear(MatrixColor.Rgb(0, 0, 0))
display.SetPixel(10, 20, MatrixColor.Rgb(255, 128, 32))
display.Present()
```

For reusable frame rendering, own a `MatrixRenderer<80ms>` and call
`Render(display, bitmap, converter)` from a scheduled frame function, as in the
gradient example. It clears, clips and converts the image,
waits for a frame deadline and returns the result of presentation. The default
`0ns` disables pacing. Use `IdentityColorConverter` for unchanged colors.
`RenderTiled` repeats a bitmap over the logical canvas, while `RenderPanel`
targets one panel tile. `IMatrixRenderer` lets a consumer substitute another
renderer with the same complete-image contract. Animation selection stays with
the application.

For a bitmap, `MatrixPainter.ShowBitmap(display, bitmap)` clears the back image,
draws the source at the origin with clipping, and presents it. Use
`ShowConvertedBitmap(display, bitmap, converter)` to apply a color pipeline.
Both return whether presentation succeeded.

See [docs/usage.md](docs/usage.md) for the complete buildable gradient example,
custom image sources, conversion and animation. See
[docs/hardware-notes.md](docs/hardware-notes.md) for ownership, timing and storage.
For multiple panels, see [docs/panel-chains.md](docs/panel-chains.md), including
the logical-to-physical mapping diagram and two-panel example.

## 📐 Contracts and Limits

- All scheduled calls use one serialized client in the shared clock/reset
  context. Calls may take multiple cycles; drawing is not a concurrent API.
- Start every image with `Clear`. `Present` rejects an uninitialized image and
  otherwise waits for a safe presentation boundary. The new back bank is not a
  copy of the visible image. Reset cancels pending work and blanks the HUB75 panel.
- `SetPixel` returns false outside the display bounds without writing. Bitmap
  implementations return black outside their bounds. Dimensions are positive.
- Keep bitmap selection and converter settings stable throughout an image.
  Pipelines borrow converters whose owners keep them alive. Use one conversion
  access path per instance; do not mix direct and borrowed Convert calls.
- HUB75 panel width is 2..256 pixels and panel height is a power of two in
  4..64. A facade owns a grid of up to 16 identical panels and shifts at most
  1024 pixel pairs per row. The logical canvas is `PANELS_X * PANEL_WIDTH` by
  `PANELS_Y * PANEL_HEIGHT`. The facade
  accepts RGB888 and outputs RGB444 or RGB666 by truncating channel low bits.
  Gamma, brightness and white balance are explicit converters, not implicit effects.
- HUB75 uses binary row selection and paired RGB lanes. Panels requiring special
  initialization, different scan mapping or other protocols need a compatible
  backend. Implement `IMatrixDisplay` to use another display technology.
- Framebuffer storage requests block RAM; physical mapping depends on synthesis.
  Configurable storage latency, register/distributed backing and RGB888 physical
  PWM are not currently exposed by this backend.

## 🧪 Build and Test

```sh
livt sync
livt test
livt build --release
livt build --project examples/gradient --release
```

The registered tests cover converter arithmetic and configuration, borrowed
composition, portable drawing, clipping, framebuffer swaps, RGB444/RGB666 PWM,
geometry and pacing at 50/75/100 MHz. The gradient example compiles separately
against the package. Scene assets, CLI tests and board timing checks belong to
the consuming application and board projects.

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
Package changes are recorded in
[CHANGELOG.md](CHANGELOG.md).
