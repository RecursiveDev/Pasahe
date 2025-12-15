# WCAG Accessibility Contrast Audit Report

**Generated:** 2025-12-16T01:26:06.631803

**Tool:** `dart run tool/wcag_contrast_checker.dart`

---

## WCAG 2.1 Contrast Requirements

| Level | Normal Text | Large Text / UI |
|-------|-------------|-----------------|
| **AA (minimum)** | 4.5:1 | 3:1 |
| **AAA (enhanced)** | 7:1 | 4.5:1 |

> **Large text** = 18pt+ (24px) or 14pt+ bold (18.67px bold)

---

## Summary

| Metric | Count |
|--------|-------|
| Total checks | 49 |
| ✅ Passed | 49 |
| ❌ Failed | 0 |
| Pass rate | 100.0% |

---

## Light Theme Results

| Context | Foreground | Background | Ratio | Required | Status |
|---------|------------|------------|-------|----------|--------|
| onSurface on surface (primary text) | #1A1C1E | #FFFFFF | 17.09:1 | 4.5:1 | ✅ PASS |
| onSurface on background (body text) | #1A1C1E | #F8F9FA | 16.21:1 | 4.5:1 | ✅ PASS |
| primary on surface (buttons, links) | #0038A8 | #FFFFFF | 9.85:1 | 3.0:1 | ✅ PASS |
| onPrimary on primary (button text) | #FFFFFF | #0038A8 | 9.85:1 | 4.5:1 | ✅ PASS |
| error on surface (error messages) | #BA1A1A | #FFFFFF | 6.46:1 | 4.5:1 | ✅ PASS |
| onError on error (error button text) | #FFFFFF | #BA1A1A | 6.46:1 | 4.5:1 | ✅ PASS |
| outline on surface (borders) | #74777F | #FFFFFF | 4.48:1 | 3.0:1 | ✅ PASS |
| onSurfaceVariant on surfaceContainer | #44474E | #EEEFF2 | 8.09:1 | 4.5:1 | ✅ PASS |
| lrt1 (Darker Green) on surface | #2E7D32 | #FFFFFF | 5.13:1 | 3.0:1 | ✅ PASS |
| lrt1 (Darker Green) on surfaceContainer | #2E7D32 | #EEEFF2 | 4.46:1 | 3.0:1 | ✅ PASS |
| lrt2 (Purple) on surface | #7B1FA2 | #FFFFFF | 8.20:1 | 3.0:1 | ✅ PASS |
| lrt2 (Purple) on surfaceContainer | #7B1FA2 | #EEEFF2 | 7.13:1 | 3.0:1 | ✅ PASS |
| mrt3 (Darker Blue) on surface | #1565C0 | #FFFFFF | 5.75:1 | 3.0:1 | ✅ PASS |
| mrt3 (Darker Blue) on surfaceContainer | #1565C0 | #EEEFF2 | 5.00:1 | 3.0:1 | ✅ PASS |
| mrt7 (Darker Orange) on surface | #E65100 | #FFFFFF | 3.79:1 | 3.0:1 | ✅ PASS |
| mrt7 (Darker Orange) on surfaceContainer | #E65100 | #EEEFF2 | 3.30:1 | 3.0:1 | ✅ PASS |
| pnr (Brown) on surface | #795548 | #FFFFFF | 6.55:1 | 3.0:1 | ✅ PASS |
| pnr (Brown) on surfaceContainer | #795548 | #EEEFF2 | 5.70:1 | 3.0:1 | ✅ PASS |
| jeep (Teal) on surface | #00695C | #FFFFFF | 6.61:1 | 3.0:1 | ✅ PASS |
| jeep (Teal) on surfaceContainer | #00695C | #EEEFF2 | 5.75:1 | 3.0:1 | ✅ PASS |
| bus (Red) on surface | #C62828 | #FFFFFF | 5.62:1 | 3.0:1 | ✅ PASS |
| bus (Red) on surfaceContainer | #C62828 | #EEEFF2 | 4.89:1 | 3.0:1 | ✅ PASS |
| discountBadgeText on discountBadge | #1B5E20 | #A5D6A7 | 4.79:1 | 4.5:1 | ✅ PASS |

---

## Dark Theme Results

| Context | Foreground | Background | Ratio | Required | Status |
|---------|------------|------------|-------|----------|--------|
| onSurface on surface (primary text) | #E6E0E9 | #141218 | 14.35:1 | 4.5:1 | ✅ PASS |
| onSurface on background (body text) | #E6E0E9 | #0F0D13 | 14.90:1 | 4.5:1 | ✅ PASS |
| primary on surface (buttons, links) | #B8C9FF | #141218 | 11.37:1 | 3.0:1 | ✅ PASS |
| onPrimary on primary (button text) | #002C71 | #B8C9FF | 8.03:1 | 4.5:1 | ✅ PASS |
| error on surface (error messages) | #F2B8B5 | #141218 | 10.89:1 | 4.5:1 | ✅ PASS |
| onError on error (error button text) | #601410 | #F2B8B5 | 7.66:1 | 4.5:1 | ✅ PASS |
| outline on surface (borders) | #938F99 | #141218 | 5.87:1 | 3.0:1 | ✅ PASS |
| onSurfaceVariant on surfaceContainerHigh | #CAC4D0 | #2B2930 | 8.42:1 | 4.5:1 | ✅ PASS |
| lrt1 (Pastel Green) on surface | #A8D5AA | #141218 | 11.30:1 | 3.0:1 | ✅ PASS |
| lrt1 (Pastel Green) on surfaceContainer | #A8D5AA | #211F26 | 9.90:1 | 3.0:1 | ✅ PASS |
| lrt2 (Pastel Purple) on surface | #D4B8E0 | #141218 | 10.39:1 | 3.0:1 | ✅ PASS |
| lrt2 (Pastel Purple) on surfaceContainer | #D4B8E0 | #211F26 | 9.10:1 | 3.0:1 | ✅ PASS |
| mrt3 (Pastel Blue) on surface | #ABC8E8 | #141218 | 10.76:1 | 3.0:1 | ✅ PASS |
| mrt3 (Pastel Blue) on surfaceContainer | #ABC8E8 | #211F26 | 9.44:1 | 3.0:1 | ✅ PASS |
| mrt7 (Pastel Orange) on surface | #E8CFA8 | #141218 | 12.33:1 | 3.0:1 | ✅ PASS |
| mrt7 (Pastel Orange) on surfaceContainer | #E8CFA8 | #211F26 | 10.80:1 | 3.0:1 | ✅ PASS |
| pnr (Pastel Brown) on surface | #C4B5AD | #141218 | 9.35:1 | 3.0:1 | ✅ PASS |
| pnr (Pastel Brown) on surfaceContainer | #C4B5AD | #211F26 | 8.19:1 | 3.0:1 | ✅ PASS |
| jeep (Pastel Teal) on surface | #9DCDC6 | #141218 | 10.61:1 | 3.0:1 | ✅ PASS |
| jeep (Pastel Teal) on surfaceContainer | #9DCDC6 | #211F26 | 9.30:1 | 3.0:1 | ✅ PASS |
| bus (Pastel Red) on surface | #E8AEAB | #141218 | 9.80:1 | 3.0:1 | ✅ PASS |
| bus (Pastel Red) on surfaceContainer | #E8AEAB | #211F26 | 8.59:1 | 3.0:1 | ✅ PASS |
| discountBadgeText on discountBadge | #1B3D1D | #A8D5AA | 7.37:1 | 4.5:1 | ✅ PASS |
| onSurfaceVariant on surfaceContainer | #CAC4D0 | #211F26 | 9.56:1 | 4.5:1 | ✅ PASS |
| secondary on surface | #E5C54C | #141218 | 11.00:1 | 3.0:1 | ✅ PASS |
| tertiary on surface | #FFB4AB | #141218 | 10.95:1 | 3.0:1 | ✅ PASS |

---

## ✅ All Checks Passed

All color combinations meet WCAG 2.1 AA minimum contrast requirements.

---

## Technical Notes

### Relative Luminance Formula (sRGB)

```
L = 0.2126 * R + 0.7152 * G + 0.0722 * B
```

Where R, G, B are linearized values:
```
if sRGB <= 0.03928:
    linear = sRGB / 12.92
else:
    linear = ((sRGB + 0.055) / 1.055) ^ 2.4
```

### Contrast Ratio Formula

```
ratio = (L1 + 0.05) / (L2 + 0.05)
```

Where L1 is the luminance of the lighter color and L2 is the luminance of the darker color.
