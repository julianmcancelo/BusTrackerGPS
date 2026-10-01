# Guía y Motor de Proyección Cartográfica Isométrica (Web Mercator EPSG:3857)
## Solución al desfase y deformación entre Tiles Ráster (Mapbox/OSM) y Capas Vectoriales (PDF/SVG/Canvas)

> **Documento de Referencia Técnica y Arquitectura Multi-Stack**  
> Desarrollado para la Dirección General de Movilidad y Transporte · Subsecretaría de Planificación Urbana · Municipio de Lanús.  
> Diseñado para ser exportable e implementable en cualquier stack (Flutter/Dart, TypeScript/React/Node, Python/FastAPI/ReportLab).

---

## 1. El Problema: ¿Por qué se deforma la impresión y se desfasa la traza?

Cuando se genera un plano o mapa imprimible combinando una **capa base ráster** (ej. tiles de Mapbox o OpenStreetMap descargadas vía Static Map API o tile assembler) y una **capa vectorial** (ej. líneas de colectivo, paradas, límites comunales dibujados en PDF, SVG o HTML Canvas):

### Causa Raíz A: No linealidad de la latitud en Web Mercator (EPSG:3857)
La proyección Mercator es conforme (conserva ángulos y formas locales), pero **estira progresivamente la dimensión vertical (latitud)** a medida que nos alejamos del ecuador.
- Si se usa una interpolación lineal ingenua:
  $$\Delta Y = \frac{\text{lat} - \text{minLat}}{\text{maxLat} - \text{minLat}} \times H$$
  el resultado acumula un error no lineal de entre **15% y 25%** en latitudes como las de Buenos Aires ($\approx -34.7^\circ$). La traza vectorial parecerá más corta o corrida respecto de las calles del mapa base ráster.

### Causa Raíz B: Desajuste de Aspect Ratio (Relación de Aspecto)
Una hoja A0/A1/A3 o un viewport rectangular tiene un aspect ratio físico fijo (ej. horizontal $W / H \approx 1.414$).
Si el bounding box geográfico de los datos $(\Delta\text{lng}, \Delta\text{lat})$ tiene una proporción diferente (por ejemplo, una línea alargada norte-sur con ratio 0.5), ajustar ambos ejes independientemente provoca **anamorfosis** (deformación de círculos en óvalos, calles con ángulos falsos de 90° distorsionados).

---

## 2. El Modelo Matemático Canónico

Para lograr una coincidencia **pixel-perfect y submilimétrica** entre el mapa ráster y el vector, ambos sistemas deben someterse a la misma proyección esférica normalizada.

### 2.1 Coordenadas de Mundo Normalizadas $[0, 1]$

Dada una coordenada geográfica $(\phi = \text{latitud en radianes}, \lambda = \text{longitud en radianes})$:

1. **Longitud (Eje X):**
   $$x_{\text{world}} = \frac{\text{lng} + 180}{360}$$

2. **Latitud (Eje Y de Mercator):**
   $$y_{\text{world}} = \frac{1}{2} - \frac{\ln\left(\tan\left(\frac{\pi}{4} + \frac{\text{lat} \times \pi / 180}{2}\right)\right)}{2\pi}$$
   *(Nota: en Web Mercator, $y=0$ es el Polo Norte y $y=1$ es el Polo Sur).*

### 2.2 Bloqueo Isométrico del Viewport (Aspect Ratio Preservation)

Sean $W$ y $H$ el ancho y alto del contenedor gráfico (en puntos de PDF o píxeles):
$$\text{viewportRatio} = \frac{W}{H}$$

Calculamos el bounding box de la traza en coordenadas de mundo:
$$x_{\min} = \text{worldX}(\text{minLng}), \quad x_{\max} = \text{worldX}(\text{maxLng})$$
$$y_{\min} = \text{worldY}(\text{maxLat}), \quad y_{\max} = \text{worldY}(\text{minLat})$$
$$\Delta x = (x_{\max} - x_{\min}) \times (1 + 2 \times \text{padding})$$
$$\Delta y = (y_{\max} - y_{\min}) \times (1 + 2 \times \text{padding})$$

Ajustamos para igualar el aspect ratio del viewport:
$$\text{dataRatio} = \frac{\Delta x}{\Delta y}$$

- Si $\text{dataRatio} > \text{viewportRatio}$: la traza es más ancha que el viewport $\implies$ expandimos $\Delta y$:
  $$\Delta y_{\text{adj}} = \frac{\Delta x}{\text{viewportRatio}}$$
- Si $\text{dataRatio} < \text{viewportRatio}$: la traza es más alta que el viewport $\implies$ expandimos $\Delta x$:
  $$\Delta x_{\text{adj}} = \Delta y \times \text{viewportRatio}$$

El centro geográfico $(x_c, y_c)$ se mantiene inalterado y los nuevos límites de mundo son:
$$x_{0} = x_c - \frac{\Delta x_{\text{adj}}}{2}, \quad x_{1} = x_c + \frac{\Delta x_{\text{adj}}}{2}$$
$$y_{0} = y_c - \frac{\Delta y_{\text{adj}}}{2}, \quad y_{1} = y_c + \frac{\Delta y_{\text{adj}}}{2}$$

### 2.3 Proyección a Coordenadas de Salida (Canvas / PDF)

Para cualquier coordenada $(\text{lat}, \text{lng})$:
$$X = \left(\frac{\text{worldX}(\text{lng}) - x_0}{\Delta x_{\text{adj}}}\right) \times W$$
$$Y = \left(\frac{\text{worldY}(\text{lat}) - y_0}{\Delta y_{\text{adj}}}\right) \times H$$

Dado que $\frac{\Delta x_{\text{adj}}}{\Delta y_{\text{adj}}} = \frac{W}{H}$, la escala en X y en Y es **rigurosamente idéntica**:
$$\text{Scale}_X = \text{Scale}_Y = \frac{W}{\Delta x_{\text{adj}}} = \frac{H}{\Delta y_{\text{adj}}}$$
**Eliminando al 100% cualquier distorsión o desfase.**

---

## 3. Implementaciones de Referencia Multi-Stack

### A. TypeScript / JavaScript (Node, React, Next.js, Canvas, jsPDF, Mapbox Static)

```typescript
export interface LatLng {
  lat: number;
  lng: number;
}

export class MercatorViewportProjection {
  readonly x0: number;
  readonly x1: number;
  readonly y0: number;
  readonly y1: number;
  readonly spanX: number;
  readonly spanY: number;
  readonly centerLat: number;
  readonly centerLng: number;
  readonly zoom: number;

  constructor(
    points: LatLng[],
    public readonly width: number,
    public readonly height: number,
    paddingFraction: number = 0.08
  ) {
    if (points.length === 0) {
      throw new Error('Debe proveer al menos un punto geográfico');
    }

    let minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (const p of points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    const minWorldX = MercatorViewportProjection.lngToWorldX(minLng);
    const maxWorldX = MercatorViewportProjection.lngToWorldX(maxLng);
    const minWorldY = MercatorViewportProjection.latToWorldY(maxLat);
    const maxWorldY = MercatorViewportProjection.latToWorldY(minLat);

    const centerX = (minWorldX + maxWorldX) / 2;
    const centerY = (minWorldY + maxWorldY) / 2;

    let spanX = Math.max(1e-7, (maxWorldX - minWorldX) * (1 + 2 * paddingFraction));
    let spanY = Math.max(1e-7, (maxWorldY - minWorldY) * (1 + 2 * paddingFraction));

    const viewportRatio = width / height;
    const dataRatio = spanX / spanY;

    if (dataRatio > viewportRatio) {
      spanY = spanX / viewportRatio;
    } else {
      spanX = spanY * viewportRatio;
    }

    this.spanX = spanX;
    this.spanY = spanY;
    this.x0 = centerX - spanX / 2;
    this.x1 = centerX + spanX / 2;
    this.y0 = centerY - spanY / 2;
    this.y1 = centerY + spanY / 2;

    this.centerLng = MercatorViewportProjection.worldXToLng(centerX);
    this.centerLat = MercatorViewportProjection.worldYToLat(centerY);

    // Zoom para Mapbox Static API (512px tile base)
    const zoomX = Math.log2(width / (spanX * 512));
    const zoomY = Math.log2(height / (spanY * 512));
    this.zoom = Math.max(1, Math.min(20, Math.min(zoomX, zoomY)));
  }

  static lngToWorldX(lng: number): number {
    return (lng + 180.0) / 360.0;
  }

  static latToWorldY(lat: number): number {
    const latRad = (lat * Math.PI) / 180.0;
    const sinLat = Math.sin(latRad);
    return 0.5 - Math.log((1 + sinLat) / (1 - sinLat)) / (4 * Math.PI);
  }

  static worldXToLng(x: number): number {
    return x * 360.0 - 180.0;
  }

  static worldYToLat(y: number): number {
    const n = Math.PI - 2.0 * Math.PI * y;
    return (180.0 / Math.PI) * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)));
  }

  project(lat: number, lng: number): { x: number; y: number } {
    const wx = MercatorViewportProjection.lngToWorldX(lng);
    const wy = MercatorViewportProjection.latToWorldY(lat);

    const normX = (wx - this.x0) / this.spanX;
    const normY = (wy - this.y0) / this.spanY;

    return {
      x: normX * this.width,
      y: normY * this.height,
    };
  }

  getMapboxStaticUrl(token: string, style: string = 'light-v11', retina: boolean = true): string {
    const w = Math.min(1280, Math.round(this.width));
    const h = Math.min(1280, Math.round(this.height));
    const ret = retina ? '@2x' : '';
    return `https://api.mapbox.com/styles/v1/mapbox/${style}/static/${this.centerLng.toFixed(6)},${this.centerLat.toFixed(6)},${this.zoom.toFixed(2)},0/${w}x${h}${ret}?access_token=${token}`;
  }
}
```

---

### B. Python (FastAPI, GeoPandas, ReportLab, Matplotlib)

```python
import math
from typing import List, Tuple

class MercatorViewportProjection:
    def __init__(self, points: List[Tuple[float, float]], width: float, height: float, padding: float = 0.08):
        """
        points: Lista de tuplas (latitud, longitud)
        width, height: Dimensiones en puntos de PDF o píxeles
        """
        lats = [p[0] for p in points]
        lngs = [p[1] for p in points]

        min_world_x = self.lng_to_world_x(min(lngs))
        max_world_x = self.lng_to_world_x(max(lngs))
        min_world_y = self.lat_to_world_y(max(lats))
        max_world_y = self.lat_to_world_y(min(lats))

        center_x = (min_world_x + max_world_x) / 2.0
        center_y = (min_world_y + max_world_y) / 2.0

        span_x = max(1e-7, (max_world_x - min_world_x) * (1.0 + 2.0 * padding))
        span_y = max(1e-7, (max_world_y - min_world_y) * (1.0 + 2.0 * padding))

        viewport_ratio = width / height
        data_ratio = span_x / span_y

        if data_ratio > viewport_ratio:
            span_y = span_x / viewport_ratio
        else:
            span_x = span_y * viewport_ratio

        self.width = width
        self.height = height
        self.span_x = span_x
        self.span_y = span_y
        self.x0 = center_x - span_x / 2.0
        self.y0 = center_y - span_y / 2.0

        self.center_lng = self.world_x_to_lng(center_x)
        self.center_lat = self.world_y_to_lat(center_y)
        self.zoom = min(20.0, max(1.0, math.log2(min(width / (span_x * 512.0), height / (span_y * 512.0)))))

    @staticmethod
    def lng_to_world_x(lng: float) -> float:
        return (lng + 180.0) / 360.0

    @staticmethod
    def lat_to_world_y(lat: float) -> float:
        lat_rad = math.radians(lat)
        return 0.5 - math.log(math.tan(math.pi / 4.0 + lat_rad / 2.0)) / (2.0 * math.pi)

    @staticmethod
    def world_x_to_lng(x: float) -> float:
        return x * 360.0 - 180.0

    @staticmethod
    def world_y_to_lat(y: float) -> float:
        n = math.pi - 2.0 * math.pi * y
        return math.degrees(math.atan(math.sinh(n)))

    def project(self, lat: float, lng: float) -> Tuple[float, float]:
        wx = self.lng_to_world_x(lng)
        wy = self.lat_to_world_y(lat)
        px = ((wx - self.x0) / self.span_x) * self.width
        py = ((wy - self.y0) / self.span_y) * self.height
        return px, py
```

---

## 4. Checklist para Nuevas Implementaciones
1. **Nunca interpolar $\Delta\text{lat}$ linealmente** en documentos cartográficos. Usar siempre la función esférica $y = \frac{1}{2} - \frac{\ln(\tan(\pi/4 + \phi/2))}{2\pi}$.
2. **Siempre forzar el bloqueo de relación de aspecto** (`aspectRatio = width / height`) expandiendo la dimensión menor antes de proyectar coordenadas.
3. **Sincronizar el bounding box del ráster estático** con el centro y el zoom calculados a partir de los puntos expandidos en mundo (`x0, y0, spanX, spanY`).
4. **Verificación de prueba unitaria**: Tomar 4 esquinas de un rectángulo geográfico en Lanús (lat: -34.70 a -34.72, lng: -58.40 a -58.38) y verificar que `project(lat, lng)` mapea exactamente a los límites deseados en píxeles.
