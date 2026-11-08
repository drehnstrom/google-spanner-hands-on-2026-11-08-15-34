# SVG Craft (ROI Alt Theme)

**Course Generator and Course Graphics Designer must read this file before
creating or replacing an SVG.** A weak diagram costs more than no diagram: a
human will delete it and redo the slide.

A graphic earns its place if an instructor could **mute the bullets for five
seconds** and the picture would still carry the idea.

---

## 1. When to draw at all

Draw only if a **spatial, mechanical, or contrast** picture teaches better than
type: a grid becoming a vector, a sealed test pile, a signal running backward,
quantity shown as size.

Do **not** draw because “this section needs a visual.”

If the idea is parallel options or a thesis list, use `2-column` / `3-column` /
`card-layout` and skip the SVG. A strong text layout beats a weak picture.

**Gate:** if you can describe the file as “boxes containing the slide’s words,”
do not ship it.

---

## 2. Canvas and type

- **Transparent canvas.** No full-`viewBox` fill rect (`#f4f6f8`, `#f4f8fc`,
  white, or similar). The slide is already the background.
- **No duplicate heading.** No `<text>` title that restates the slide `#`.
  Captions belong on the slide. Markdown alt text is enough for accessibility.
- **Type:** `Inter, system-ui, sans-serif`. Few words. Labels name **parts**
  (`train`, `.grad`, `64`), not slogans (“Features In, Label Out”).
- Put words in SVG `<text>`, never in a generated bitmap.
- No raw `&` in SVG text; write `and` or a proper XML entity.
- Self-contained: no font CDN required for the labels to appear.

---

## 3. ROI Alt palette only

Copy these stops from the viewer theme. Do not invent orange, generic navy, or
PowerPoint gray.

| Role | Hex |
| :--- | :--- |
| Navy (structure, dark fills) | `#082445` |
| Accent blue | `#1e71d6` |
| Gradient / emphasis | `#1e71d6`, `#6a55e4`, `#bd35c2` |
| Muted labels | `#495f7a` |
| Body | `#1c1d1f` |
| Type on a dark fill | `#ffffff` |

**Do not use:** `#c45c26` (orange), `#1f4b99`, `#334155`, `#2c4a6e`, random
card-gray fills behind the whole graphic.

Use the gradient for motion, emphasis, or a filled result, not as wallpaper.

---

## 4. Encode the concept

Rectangles are allowed as **parts of the thing** (a layer, a batch, a pixel
cell), not as word containers.

Prefer:

- The actual object: pixel grid, tape of ops, sealed stack, weight band
- Before and after in **one** frame
- Motion of a signal (forward path, reverse wash)
- Size that means quantity

The picture is the argument. Labels are ticks on that picture.

---

## 5. Reject list (fail the graphic)

- Full-viewBox gray or white background
- Title in the SVG that matches or paraphrases the slide heading
- Three-to-five rounded cards plus triangle arrows
- Slide bullets copied into shapes
- Decorative icons with no argument
- Generated bitmap with fake UI or misspelled labels
- Palette colors that are not in §3

---

## 6. Self-check before save

1. Hide the slide title. Does this still teach? If no, redraw or delete.
2. Is the canvas transparent?
3. Are only ROI Alt colors used?
4. Could `2-column` or `card-layout` have done this better?

---

## 7. Reject this (do not copy)

Three labeled boxes on a gray field, plus a slogan. This is the failure mode.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800" role="img" aria-label="Plan apply loop">
  <rect width="800" height="800" fill="#f5f7fa"/>
  <rect x="80" y="160" width="200" height="120" rx="16" fill="#1f4b99"/>
  <rect x="300" y="160" width="200" height="120" rx="16" fill="#1f4b99"/>
  <rect x="520" y="160" width="200" height="120" rx="16" fill="#1f4b99"/>
  <text x="400" y="420" text-anchor="middle" fill="#334155" font-family="Arial, Helvetica, sans-serif" font-size="32">Safe team loop</text>
</svg>
```

Same failure: `X` card, `f(X)` card, `y` card with orange arrows, or two cards
titled Train and Test filled with the slide’s bullets.

---

## 8. Accept this shape of idea (copy the approach)

The picture **is** the mapping: an 8-by-8 grid flattens into 64 cells, then a
weight band lights one of ten class slots. Labels are `64` and `10`. No banner
title. Transparent canvas. ROI Alt colors.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 240" role="img" aria-label="Eight by eight pixels flatten to 64 values, then a weight band lights one of ten classes">
  <defs>
    <linearGradient id="band" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#1e71d6"/>
      <stop offset="0.5" stop-color="#6a55e4"/>
      <stop offset="1" stop-color="#bd35c2"/>
    </linearGradient>
  </defs>
  <!-- 8x8 pixel grid (the thing, not a caption box) -->
  <g transform="translate(8,40)">
    <!-- cells drawn as the image; one example row shown in the real file -->
    <rect x="0" y="0" width="16" height="16" fill="#082445"/>
    <rect x="16" y="0" width="16" height="16" fill="#1e71d6"/>
    <rect x="32" y="0" width="16" height="16" fill="#495f7a"/>
    <rect x="0" y="16" width="16" height="16" fill="#6a55e4"/>
    <rect x="16" y="16" width="16" height="16" fill="#082445"/>
    <rect x="32" y="16" width="16" height="16" fill="#bd35c2"/>
  </g>
  <text x="72" y="200" text-anchor="middle" fill="#495f7a" font-family="Inter, system-ui, sans-serif" font-size="14">8 x 8</text>
  <!-- flattened strip of 64 (abbreviated) -->
  <rect x="160" y="108" width="256" height="16" fill="url(#band)"/>
  <text x="288" y="200" text-anchor="middle" fill="#495f7a" font-family="Inter, system-ui, sans-serif" font-size="14">64</text>
  <!-- ten class slots; one lit -->
  <g transform="translate(448,96)">
    <rect x="0" y="0" width="14" height="40" fill="none" stroke="#495f7a" stroke-width="2"/>
    <rect x="18" y="0" width="14" height="40" fill="none" stroke="#495f7a" stroke-width="2"/>
    <rect x="36" y="0" width="14" height="40" fill="#bd35c2"/>
    <rect x="54" y="0" width="14" height="40" fill="none" stroke="#495f7a" stroke-width="2"/>
    <rect x="72" y="0" width="14" height="40" fill="none" stroke="#495f7a" stroke-width="2"/>
  </g>
  <text x="520" y="200" text-anchor="middle" fill="#495f7a" font-family="Inter, system-ui, sans-serif" font-size="14">10</text>
</svg>
```

Complete the grid in a real asset (all 64 cells). The point is: **draw the
data, not a box labeled “X.”**

Other accept patterns:

- **Train vs test:** a visible pile of examples feeding the fit; a sealed stack
  that is not touched until a score mark appears. Do not paste bullets into two
  cards.
- **Autograd:** a short forward chain of ops with a reverse color wash filling
  `.grad` on `w`. No banner that repeats the slide title.

---

## 9. File hygiene

- Save under the course `images/` folder with a descriptive name:
  `ch01-digits-grid-to-classes.svg`, not `image1.svg`.
- `viewBox` matches placement: square beside bullets; wide under content or as
  `title-image`; 16:9 when the image is the stage.
- Markdown: `![Eight by eight pixels flatten to a class score](images/…)` with
  alt that describes the picture, not the slide title.
