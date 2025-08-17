# Before/After Carousel – Flutter

A polished, endlessly auto-scrolling carousel of “before/after” image cards with a single global vertical slider that controls the reveal across all cards.
Each card has one animated label that switches between Before and After based on the slider position.


# Features

One global slider (divider + handle) across the whole carousel
Drag anywhere to move it; every card reveals left/right accordingly.

Endless auto-scroll to the left with adjustable speed.

Full-bleed images inside each card with rounded corners.

Single per-card label that cross-fades between “Before” and “After”.

Smooth animations and spacing that matches a typical gallery layout.

No per-card sliders (exactly one slider globally, as requested).



# How it Works

The carousel is a horizontal ListView.builder that repeats your image pairs.

A global slider is drawn on top with Stack + Positioned.
Its X-position in the viewport is converted to a local fraction t ∈ [0,1]
for each card:
t = (globalX - cardLeftEdge) / cardWidth.

Each card shows:

After image (fills the card).

Before image (clipped to a left-side rectangle based on t).

Bottom label using AnimatedSwitcher to flip text & colors at the midpoint.


# Controls

Drag anywhere on the carousel to move the global slider.

Tap to jump the slider to a point.

Auto-scroll runs continuously; adjust autoScrollSpeedPxPerSec as needed.