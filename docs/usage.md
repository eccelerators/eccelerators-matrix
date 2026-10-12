# Using Eccelerators.Matrix

## Complete example

The [gradient project](../examples/gradient/livt.toml) contains a complete
application component and bitmap source. Build from the package root:

```sh
livt build --project examples/gradient -R
```

The project uses a local package dependency. Its top component owns a 64x64
RGB666 display and maps an sRGB gradient through GammaColorConverter. A board
integration must supply the 50 MHz clock/reset context and map the HUB75 pins;
compiling this example does not program a board.

```livt
namespace Eccelerators.Matrix.Examples

using Eccelerators.Matrix
using Eccelerators.Matrix.Hub75

/**
 * Own a 64x64 RGB666 HUB75 display and an immutable gradient in a 50 MHz context.
 * One drawing process borrows the bitmap and converter. Reset blanks the panel
 * and restarts rendering; the board integration supplies clock, reset and pins.
 */
@Context(ClockFrequency = 50MHz)
component MatrixExample
{
	// Owned display, drawing client, image source and transfer converter.
	display: Hub75Display<64, 64, 50ms, 100ns, 6>
	painter: MatrixPainter
	bitmap: GradientBitmap
	gamma: GammaColorConverter

	/**
	 * Bind HUB75 pins and construct all dependencies in the inherited context.
	 */
	new(panelClock: out logic, latch: out logic, outputEnableN: out logic,
		row: out logic[5], rgbUpper: out logic[3], rgbLower: out logic[3])
	{
		this.display = new Hub75Display<64, 64, 50ms, 100ns, 6>(panelClock, latch, outputEnableN, row, rgbUpper, rgbLower)
		this.painter = new MatrixPainter()
		this.bitmap = new GradientBitmap()
		this.gamma = new GammaColorConverter()
	}

	/**
	 * Decode sRGB, render the gradient and wait for complete-image presentation.
	 */
	process Draw()
	{
		this.gamma.Configure(GammaColorConverter.SRGB)
		this.painter.ShowConvertedBitmap(this.display, this.bitmap, this.gamma)
	}
}
```

The corresponding [GradientBitmap](../examples/gradient/src/GradientBitmap.lvt)
implements GetWidth, GetHeight and GetPixel. Replace it with ROM, RAM or a
procedural source while retaining the `IMatrixBitmap` contract. RGB888 describes
the byte layout; choose the transfer function appropriate to the image data.

## Drawing operations

| Operation | Behavior |
|---|---|
| `display.Clear(rgb)` | Wait for the complete back image to be initialized |
| `display.SetPixel(x, y, rgb)` | Return true after a valid write completes; false out of bounds |
| `display.Present()` | Reject an uninitialized image; otherwise wait for presentation |
| `painter.DrawBitmap(display, bitmap, left, top)` | Clip at the offset without clearing or presenting |
| `painter.ShowBitmap(display, bitmap)` | Clear to black, draw at the origin, then present |
| `painter.ShowConvertedBitmap(display, bitmap, converter)` | Convert source pixels before drawing and presenting |

Begin with Clear even when drawing only a small region. To preserve a background,
redraw it into each new image before overlaying sprites. Uncovered pixels in Show
operations remain black. Hub75Display also provides DrawBitmap and ShowBitmap
convenience methods; use MatrixPainter for clients that can target other drivers.

## Color pipelines

The application constructs and owns the concrete stages, then binds
`ColorPipeline(first, second)`. Conversion runs first, then second. Nest two
pipelines for three stages, for example gamma, white balance, brightness.
Configure the concrete stages between images; borrow their Convert operations
through the pipeline only. Each stage rounds to RGB888.

GammaColorConverter accepts its named constants BYPASS, SRGB and GAMMA22; default
is BYPASS. Brightness and white balance default to 100 percent and accept 0..100.
Their Configure methods return false without changing settings for invalid input.
Use [ConvertedPainterTest](../tests/ConvertedPainterTest.lvt) as an executable
example of ownership and three-stage composition.

## Animation

Keep animation state in the application or bitmap source. Advance it only after
a complete image has been presented. For post-presentation holds,
`MatrixPictureSequence<80ms, 16>` exposes picture indices 0..15; call Next after
Present to wait and advance with wraparound. INTERVALS can repeat a hold interval
without requiring a larger single-duration representation.

For deadlines that run while rendering, own `MatrixFramePacer<80ms>` and perform:

```livt
this.display.Clear(0 as logic[24])
this.painter.DrawBitmap(this.display, this.bitmap, 0, 0)
this.pacer.WaitNext()
this.display.Present()
```

A zero pacer interval disables waiting. Missed deadlines coalesce; actual frame
rate is bounded by drawing and presentation time. ShowBitmap presents internally,
so use separate DrawBitmap and Present operations when pacing before presentation.

## HUB75 configuration

`Hub75Display<DISPLAY_WIDTH, DISPLAY_HEIGHT, STARTUP_TIME, PHASE_TIME, COLOR_BITS,
ROW_HOLD_TIME>` defaults to `<64, 64, 50ms, 100ns, 4, 150us>`.

PHASE_TIME must span at least five context clocks. Startup and row hold durations
must be positive; the divided PWM base dwell must span at least one clock.
The scanner derives tick counts from the inherited clock frequency. ROW_HOLD_TIME
is the enabled dwell budget per row pair, divided across weighted planes;
shifting and blanking add to the complete frame period.

Constructor outputs are panelClock, latch, active-low outputEnableN, binary row
address, rgbUpper and rgbLower. In each three-bit RGB lane, bit 2 is red, bit 1
green and bit 0 blue. The row width is Bits.RequiredFor(DISPLAY_HEIGHT / 2 - 1).
Use the facade unless you need to supply your own correctly timed scan source.
