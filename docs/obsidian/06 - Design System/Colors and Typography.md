---
tags: [lifelevel, design]
aliases: [Color Palette, AppColors, Typography]
---
# Colors and Typography

> Dark-theme, high-contrast design language. All color tokens are defined in `lib/core/constants/app_colors.dart` and referenced as `AppColors.X` throughout the app.

## Phone frame

**390 × 844** (iPhone 14). All mockups in `design-mockup/` are sized to this frame.

## Color tokens

### Backgrounds
| Token | Hex | Use |
|-------|-----|-----|
| `background` | `#040810` | Main app background (almost black) |
| `backgroundAlt` | `#080e14` | Home feed base |
| `shellBackground` | `#090d1a` | Bottom nav background |

### Surfaces
| Token | Hex | Use |
|-------|-----|-----|
| `surface` | `#161b22` | Card surfaces (base) |
| `surfaceElevated` | `#1e2632` | Elevated cards |
| `surfaceSuccess` | `#1a2d1a` | Completed quest tint |
| `surfaceDisabled` | `#1a1a1a` | Disabled / expired tint |

### Text
| Token | Hex | Use |
|-------|-----|-----|
| `textPrimary` | `#e6edf3` | Primary text (light) |
| `textSecondary` | `#8b949e` | Secondary text (muted) |
| `textMuted` | `#4d5b6b` | De-emphasized numbers |

### Accents
| Token | Hex | Use |
|-------|-----|-----|
| `blue` | `#4f9eff` | Primary action, active states, cardio |
| `purple` | `#a371f7` | Secondary, magic, rare items, class identity |
| `orange` | `#f5a623` | Premium, rewards, epic items |
| `red` | `#f85149` | Boss, danger, legendary items |
| `redDark` | `#c0392b` | Gradient end for boss HP bars |
| `green` | `#3fb950` | Success, completion, common items |

### UI
| Token | Hex | Use |
|-------|-----|-----|
| `border` | `#30363d` | Card / input borders |

## Rarity → Color map

| Rarity | Token |
|--------|-------|
| Common | `green` |
| Uncommon | `blue` (distinct from primary blue in UI context) |
| Rare | `purple` |
| Epic | `orange` |
| Legendary | `red` |

## Typography

```css
font-family: Inter, -apple-system, sans-serif;
```

### Type scale
| Use | Size | Weight |
|-----|------|--------|
| Hero headings | 28px | 700 |
| Section headings | 22–26px | 700 |
| Card titles | 18–20px | 600 |
| Body | 14–16px | 400 |
| Labels | 9–10px | 600 (letter-spacing 0.05em) |
| Numbers (XP, HP) | Varies | 700 |

## Navigation style

- **Bottom tab bar**: 4 items, 82px tall
- **FAB**: centred above nav bar, 62px circle
- **Radial menu**: 6 items orbiting at 130px radius, 54px per item
- All tab/ring items combine a large emoji + a small all-caps label

## Related
- [[UI Patterns]]
- [[Core Infrastructure]] (AppColors source file)
- [[Screen Inventory]]
