# Eccelerators.Matrix design

## Ownership and layers

An application owns a concrete display, its bitmaps, optional converters and a
`MatrixRenderer` or `MatrixPainter`. One scheduled drawing client calls them in the same inherited
clock/reset context. `IMatrixDisplay`, `IMatrixBitmap` and `IColorConverter` are
the portable contracts. Implementing a different display does not require HUB75
signals or framebuffer layout.

`Hub75Display` owns `Hub75Controller` and `Hub75Framebuffer`. The controller owns
scan timing and panel outputs; the framebuffer owns RAM access and bank swaps.
Scenes, animation content, CLI dispatch, UART transport and board constraints
belong to the consuming application. `ColorGain` is an implementation helper,
not an intended application entry point, despite being importable.

## Rendering policy

IMatrixRenderer defines complete-image transactions with explicit display,
bitmap and converter operands. MatrixRenderer owns a frame pacer and performs
clear, clipped pixel conversion, optional deadline waiting and presentation.
Render targets one canvas, RenderTiled repeats a source, and RenderPanel uses an
IMatrixLayout to address one tile while leaving the remaining canvas black.
The application selects and advances image sources outside that transaction.
Use IdentityColorConverter when conversion is not needed. Return values propagate
the display's presentation result. The renderer uses the borrowed operands
directly, avoiding another scheduled forwarding layer in the pixel loop.

## Drawing and presentation

Call `Clear`, draw pixels or bitmaps, then `Present`. All operations are scheduled
and may take multiple clock cycles. A successful `SetPixel` means the write has
completed; out-of-range coordinates return false without writing. `Present`
returns false before initialization, otherwise waits for the safe presentation
boundary. In the HUB75 backend, this is a complete PWM-frame boundary. There is
no timeout: the clock and scan engine must continue running.

After a swap the old front bank becomes the back bank; it is not a copy of the
visible image. Begin every new image with `Clear`. Reset invalidates both banks,
blanks output and cancels pending work through the shared context. RAM contents
are not reset or assumed to be zero. Concurrent drawing clients and independent
clock domains are outside this contract.

`MatrixPainter` clips to the display. Its Show methods clear uncovered pixels to
black and return the result of Present. The HUB75 convenience drawing methods
retain equivalent behavior, but portable consumers should use MatrixPainter.

## Color conversion

The interchange format is RGB888, packed as `0xRRGGBB`. Packing alone does not
specify a transfer function. Gamma conversion decodes encoded image values to
linear-light values; brightness and white balance scale the current values.
A usual pipeline is gamma, white balance, then brightness. Configuration remains
stable for the entire image. Invalid percentage configuration leaves the active
settings unchanged. Each stage rounds to RGB888, so composition can lose more
precision than a fused converter.

ColorPipeline borrows its stages; their owner keeps them alive. Use one Convert access path per instance. Configuration may
use the concrete instance, but do not mix direct and borrowed conversion calls.
The HUB75 facade then truncates to the upper four or six bits per channel; it
does not apply gamma or dithering implicitly. Optional per-panel 8.8 gains run
after RGB888 conversion and before truncation. Clear applies the selected gain
to every panel, including uncovered pixels.

## Storage and timing

The framebuffer has separate upper/lower lane memories, each containing two
image banks in physical chain order. Explicit block-memory attributes request BRAM mapping without
binding to vendor IP. Capacity and access latency are part of this backend;
selecting distributed RAM or register storage is not currently a public option.
Physical allocation must be checked in the target synthesis report.

The scanner derives ticks from the inherited clock context. A phase must span
at least five clocks for the pixel pipeline. Binary row addressing and weighted
bitplanes support the geometry and color depths documented in ../README.md;
panels requiring special initialization or other scan mappings need a suitable
backend. The low-level controller supports one through six bits per channel;
the application-facing Hub75Display deliberately supports four or six.

MatrixFramePacer maintains deadlines while rendering; missed deadlines coalesce.
MatrixPictureSequence instead waits after presentation before advancing its
index. Neither guarantees a frame rate faster than rendering and presentation
can complete. Reset restarts their state. The pacer's finite epoch counter can
wrap after 2^32 deadlines; clients should not leave it unobserved that long.

## Verification

The library tests cover converter arithmetic and invalid settings, borrowed
pipeline composition, geometry, clipping, presentation, framebuffer swaps,
RGB444/RGB666 scanning, exact chained-row length, panel mapping and calibration,
picture pacing and 50/75/100 MHz contexts. MemoryDisplay
provides a non-HUB75 test implementation of the drawing contract. Application
scene/CLI tests and board pin/timing checks remain separate integration layers.

The previous full application build verifies one concrete Tang Mega target,
not every panel geometry or FPGA family. Its resource totals include the CLI
and scene ROMs; they are not standalone library utilization figures.
