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
"Eccelerators.Matrix" = "0.1.0"
```

`Eccelerators.Matrix` version `0.1.0` depends on `Livt.Math 1.3.0`.

```livt
using Eccelerators.Matrix
using Eccelerators.Matrix.Hub75
```

## 📚 Namespaces

`Eccelerators.Matrix` contains the portable drawing and color APIs:

| Component or interface | Purpose |
|---|---|
| `IMatrixDisplay` | Scheduled pixel drawing and complete-image presentation |
| `IMatrixBitmap` | Read-only RGB888 pixels and image dimensions |
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

`Eccelerators.Matrix.Hub75` contains the `Hub75Display` drawing facade,
`Hub75Controller` scan engine and `Hub75Framebuffer` image storage. Most consumers
only need the facade. `ColorGain` is a converter implementation helper.

## 🔌 Common Drawing API

One scheduled client owns the drawing transaction. Pixel coordinates start at
the top left; colors are packed as `0xRRGGBB`.

```livt
// Inside the application's sole drawing process:
this.display.Clear(MatrixColor.Rgb(0, 0, 0))
this.display.SetPixel(10, 20, MatrixColor.Rgb(255, 128, 32))
this.display.Present()
```

For a bitmap, `MatrixPainter.ShowBitmap(display, bitmap)` clears the back image,
draws the source at the origin with clipping, and presents it. Use
`ShowConvertedBitmap(display, bitmap, converter)` to apply a color pipeline.
Both return whether presentation succeeded.

See [docs/usage.md](docs/usage.md) for the complete buildable gradient example,
custom image sources, conversion and animation. See
[docs/hardware-notes.md](docs/hardware-notes.md) for ownership, timing and storage.

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
- HUB75 width must be a power of two in 2..256 and height in 4..64. The facade
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
livt validate
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
