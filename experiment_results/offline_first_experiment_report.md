# Reporte de experimentacion offline-first

## Objetivo

Evaluar la arquitectura offline-first implementada en TinkiyAgro midiendo:

- Registro local completo en SQLite/Drift.
- Tasa de sincronizacion exitosa.
- Latencia promedio de sincronizacion.

## Parte A: experimento automatizado controlado

La parte A se ejecuto como prueba automatizada sobre los repositorios offline-first y una base Drift en memoria. Se simularon tres condiciones de red mediante remotos controlados:

- Conexion completa.
- Sin conexion durante la creacion local y sincronizacion posterior.
- Conexion intermitente con un fallo inicial y reintento.

Flujos evaluados:

- Crear producto.
- Editar producto/stock.
- Crear punto de recojo.
- Marcar pedido como preparado.

Comando ejecutado:

```bash
flutter test test/offline_first_experiment_test.dart --dart-define=OFFLINE_EXPERIMENT_REPETITIONS=20
```

Resultado:

| Condicion de red | Flujos probados | Registro local completo | Tasa de sincronizacion exitosa | Latencia promedio de sincronizacion |
|---|---:|---:|---:|---:|
| Conexion completa | 80 | 100.0% | 100.0% | 0.031 s |
| Sin conexion (offline total) | 80 | 100.0% | 100.0% | 0.049 s |
| Conexion intermitente | 80 | 100.0% | 100.0% | 0.311 s |

Archivo crudo:

- `experiment_results/offline_first_part_a_raw.csv`

## Parte B: validacion en emulador Android

La parte B se ejecuto dentro del emulador Android `emulator-5554` usando `integration_test`, el runtime Flutter real y la base local real de la app. La red se controlo mediante remotos instrumentados para obtener mediciones repetibles.

Flujos evaluados:

- Crear producto desde el flujo offline-first.
- Crear punto de recojo desde el flujo offline-first.

Comando ejecutado:

```bash
flutter test integration_test/offline_first_emulator_experiment_test.dart -d emulator-5554 --dart-define=OFFLINE_EMULATOR_REPETITIONS=5
```

Resultado:

| Condicion de red | Flujos probados | Registro local completo | Tasa de sincronizacion exitosa | Latencia promedio de sincronizacion |
|---|---:|---:|---:|---:|
| Conexion completa | 10 | 100.0% | 100.0% | 0.075 s |
| Sin conexion (offline total) | 10 | 100.0% | 100.0% | 0.106 s |
| Conexion intermitente | 10 | 100.0% | 100.0% | 0.429 s |

Archivo crudo:

- `experiment_results/offline_first_part_b_emulator_raw.csv`

## Interpretacion

Los resultados muestran que la capa offline-first mantiene el registro local completo en las tres condiciones evaluadas y sincroniza correctamente cuando la conectividad vuelve a estar disponible. La condicion intermitente presenta mayor latencia promedio porque incorpora un fallo inicial y reintento automatico.

## Limitaciones

La parte A es una simulacion controlada de la red, no una prueba con red fisica real. La parte B corre dentro de un emulador Android real, pero tambien usa remotos instrumentados para controlar las condiciones de red. Para evidencia complementaria en una defensa, se recomienda ejecutar una pequena muestra manual adicional con modo avion o apagado real del backend.
