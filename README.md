Mi Lista de Tareas - Aplicación Flutter

Una aplicación **To-Do List** moderna y robusta desarrollada en **Flutter** con gestión de estado avanzada, persistencia local, sincronización offline-first y arquitectura limpia.

---


## ✨ Características Principales

**Gestión de Tareas Completa**
- Crear, editar, marcar como completadas y eliminar tareas
- Filtrar tareas por estado (Todas, Pendientes, Completadas)
- Interfaz intuitiva con Material Design 3

**Offline-First Strategy**
- Las tareas se guardan en la base de datos local (SQLite) **primero**
- Las operaciones se encolan para sincronizar cuando hay conexión
- El usuario siempre ve datos locales incluso sin internet

**Sincronización Inteligente**
- Detección automática de conectividad (connectivity_plus)
- Cola de operaciones (`queue_operations`) para reintentos
- Estrategia **Last-Write-Wins (LWW)** para resolver conflictos
- Incremento de intentos y registro de errores

**Gestión de Estado Moderna**
- Riverpod para inyección de dependencias y state management
- Providers especializados para cada capa (data, domain, presentation)
- Invalidación automática de estado tras cambios

**Persistencia Local (SQLite)**
- Almacenamiento robusto con sqflite
- Tablas: `tasks` (datos) y `queue_operations` (sincronización)
- Soft-delete para preservar historial

**Integración con API REST**
- Cliente HTTP configurado con soporte a reintentos
- Headers de `Idempotency-Key` para evitar duplicaciones
- Manejo robusto de errores (4xx, 5xx, timeouts)

**Arquitectura Limpia (Clean Architecture)**
- Separación clara: **data**, **domain**, **presentation**
- Repositories pattern con abstracción de datos
- Use cases independientes del framework

---

##  Arquitectura y Tecnologías

### Stack Tecnológico

| Componente         | Tecnología              | Versión |
|--------------------|-------------------------|---------|
| **Framework**      | Flutter                 | 3.35.6+ |
| **Lenguaje**       | Dart                    | 3.9.2+  |
| **State Mgmt**     | Riverpod                | 2.4.0   |
| **Base de Datos**  | SQLite (sqflite)        | 2.3.0   |
| **HTTP Client**    | http                    | 1.1.0   |
| **Conectividad**   | connectivity_plus       | 5.0.0   |
| **ID Generation**  | uuid                    | 4.0.0   |
| **Logging**        | logger                  | 2.0.0   |
| **JSON**           | json_serializable       | 6.7.0   |

### Patrón de Arquitectura

```
Clean Architecture + Repository Pattern + Offline-First

┌─────────────────────────────────────────────────────┐
│         PRESENTATION LAYER (UI)                     │
│  - Pages (TasksPage)                                │
│  - Widgets (TaskListItem, CreateTaskDialog)         │
│  - Providers (Riverpod)                             │
│  - State Management (TaskController)                │
└────────────┬────────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────────┐
│         DOMAIN LAYER (Business Logic)               │
│  - Entities (Task)                                  │
│  - Repository Interfaces                           │
│  - Use Cases (GetTasks, CreateTask, etc.)           │
└────────────┬────────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────────┐
│          DATA LAYER (Persistence)                   │
│  ┌─────────────────┐    ┌──────────────────────┐   │
│  │  Local (sqflite)│    │  Remote (HTTP API)   │   │
│  │  - LocalDatabase│    │  - TasksRemoteDS     │   │
│  │  - tasks table  │    │  - GET/POST/PUT/DEL  │   │
│  │  - queue_ops    │    │  - Idempotency-Key   │   │
│  └─────────────────┘    └──────────────────────┘   │
│         │                        │                  │
│         └─────────┬──────────────┘                  │
│                   ▼                                 │
│  ┌─────────────────────────────────────┐           │
│  │  Repository (TaskRepositoryImpl)     │           │
│  │  - Offline-first reads              │           │
│  │  - Local writes + queue ops         │           │
│  │  - Sync pending operations          │           │
│  │  - Conflict resolution (LWW)        │           │
│  └─────────────────────────────────────┘           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│         SERVICES (Cross-cutting)                    │
│  - ConnectivityService (stream de conectividad)    │
│  - SyncService (orchestration de sync)             │
│  - DatabaseManager (singleton global)              │
└─────────────────────────────────────────────────────┘
```

### Flujo de Datos

**Lectura (Offline-First)**
```
UI → tasksProvider (Riverpod)
  → GetFilteredTasksUseCase
    → TaskRepository.getFilteredTasks()
      → LocalDatabase.getAllTasks()
        → [mostrar datos locales inmediatamente]
        → (en background: fetchTasksFromRemote si hay conexión)
```

**Escritura (Local + Queue)**
```
UI → createTask / updateTask / deleteTask
  → TaskController
    → CreateTaskUseCase / UpdateTaskUseCase / DeleteTaskUseCase
      → TaskRepository.createTask() / updateTask() / deleteTask()
        ├─ LocalDatabase.insertTask()
        ├─ LocalDatabase.insertQueueOperation()
        └─ Invalidar tasksProvider (refrescar UI)
        
[Sincronización en background]
  → SyncService (detecta conectividad)
    → TaskRepository.syncPendingOperations()
      → LocalDatabase.getOperationsToSync()
        → Para cada operación:
          ├─ Intentar enviar a API (con Idempotency-Key)
          ├─ Si OK: eliminar de queue, actualizar local
          └─ Si Error: incrementar attempt_count, registrar error
```

---

##  Estructura de Carpetas

```
taller_flutter/
├── lib/
│   ├── main.dart                          # Entry point, inicializa DB
│   ├── app.dart                           # MyApp widget
│   │
│   ├── core/                              # Capa transversal (utilities)
│   │   ├── database/
│   │   │   └── database_manager.dart      # Singleton global de DB
│   │   ├── errors/
│   │   │   ├── exceptions.dart            # AppException, NetworkException, DatabaseException
│   │   │   └── failures.dart              # Failure, NetworkFailure, DatabaseFailure
│   │   ├── network/
│   │   │   └── api_client.dart            # Cliente HTTP base (extensible)
│   │   └── utils/
│   │       └── extensions.dart            # Extensiones de tipos
│   │
│   ├── features/
│   │   └── tasks/                         # Feature: Gestión de Tareas
│   │       ├── domain/                    # Capa de Dominio (Lógica de negocio)
│   │       │   ├── entities/
│   │       │   │   └── task.dart          # Entidad Task (id, title, description, etc.)
│   │       │   ├── repositories/
│   │       │   │   └── task_repository.dart  # Interfaz de repositorio
│   │       │   └── usecases/
│   │       │       └── task_usecases.dart    # Use Cases: Get, Create, Update, Delete, Filter
│   │       │
│   │       ├── data/                      # Capa de Datos (Persistencia)
│   │       │   ├── local/
│   │       │   │   └── database.dart      # LocalDatabase: SQLite CRUD + queue ops
│   │       │   ├── remote/
│   │       │   │   └── tasks_api.dart     # TasksRemoteDataSource: HTTP client
│   │       │   ├── models/
│   │       │   │   ├── task_model.dart    # TaskModel: serialización/deserialización
│   │       │   │   └── queue_operation.dart  # QueueOperation: modelo de operación encolada
│   │       │   └── repositories/
│   │       │       └── task_repository_impl.dart  # TaskRepositoryImpl: lógica offline-first
│   │       │
│   │       └── presentation/              # Capa de Presentación (UI)
│   │           ├── pages/
│   │           │   └── tasks_page.dart    # TasksPage: pantalla principal
│   │           ├── widgets/
│   │           │   ├── task_list_item.dart    # Widget de item en lista
│   │           │   └── create_task_dialog.dart # Dialog para crear/editar
│   │           └── providers/
│   │               └── task_provider.dart  # Providers Riverpod + inyección dependencias
│   │
│   └── services/                          # Servicios transversales
│       ├── connectivity_service.dart      # Detección de conectividad
│       └── sync_service.dart              # Orchestration de sincronización
│
├── test/                                  # Tests unitarios e integración
│   └── widget_test.dart
│
├── android/                               # Configuración Android
├── ios/                                   # Configuración iOS
├── windows/                               # Configuración Windows
├── web/                                   # Configuración Web
├── linux/                                 # Configuración Linux
├── macos/                                 # Configuración macOS
│
├── pubspec.yaml                           # Dependencias y configuración
├── analysis_options.yaml                  # Reglas de linting
├── .env.example                           # Variables de entorno (plantilla)
├── README.md                              # Este archivo
└── db.json                                # (Opcional) Datos de prueba para json-server
```


##  Instalación y Configuración

### Prerequisitos

- **Flutter SDK**: 3.35.6 o superior ([descargar](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: incluido con Flutter (3.9.2+)
- **Android SDK**: para compilar APK (API level 21+)
- **Git**: para clonar el repositorio

### Verificar Instalación

```bash
flutter --version
dart --version
flutter doctor
```

### Clonar Repositorio

```bash
git clone <URL_REPOSITORIO>
cd taller_flutter
```

### Instalar Dependencias

```bash
flutter pub get
```

Este comando descarga todas las dependencias definidas en `pubspec.yaml`:
- flutter_riverpod (state management)
- sqflite (local DB)
- connectivity_plus (detectar internet)
- http (cliente REST)
- uuid (generador de IDs)
- logger (logging)
- json_serializable (JSON serialization)

---

##  Cómo Ejecutar

### En Emulador Android

```bash
# 1. Verificar que el emulador está corriendo
flutter emulators

# 2. Lanzar emulador (si no está activo)
flutter emulators --launch <nombre_emulador>

# 3. Ejecutar la app
flutter run
```

### En Dispositivo Físico Android

```bash
# 1. Conectar dispositivo por USB
# 2. Verificar que Flutter ve el dispositivo
flutter devices

# 3. Ejecutar
flutter run
```

### En Navegador Web (Debug)

```bash
flutter run -d chrome
# o
flutter run -d edge
```

### En Desktop (Windows)

```bash
flutter run -d windows
```

---

##  Probar Modo Offline y Sincronización

### Escenario 1: Crear Tarea en Modo Offline

**Objetivo**: Verificar que la tarea se guarda localmente aunque no haya internet.

**Pasos**:

1. **Iniciar la app** con emulador/dispositivo
2. **Desconectar internet** (airplane mode o desactivar WiFi/datos)
3. **Tocar el botón `+`** para crear una tarea:
   - Título: "Mi tarea offline"
   - Descripción: "Esta se sincronizará después"
4. **Guardar** la tarea
5. **Verificar**: La tarea aparece en la lista instantáneamente (datos locales)
6. **Revisar logs**: En la consola Flutter deberías ver:
   ```
   [TaskRepositoryImpl] Created task locally: id=<uuid>
   [TaskRepositoryImpl] Queued operation: type=CREATE, id=<uuid>
   ```

### Escenario 2: Sincronización Automática (Offline → Online)

**Objetivo**: Verificar que la app sincroniza automáticamente cuando se recupera la conexión.

**Pasos**:

1. **Con la tarea anterior sin sincronizar** (offline):
2. **Reconectar internet** (desactivar airplane mode)
3. **Esperar 2-3 segundos**: La app detecta conectividad y lanza sincronización
4. **Verificar**:
   - La tarea en la lista **persiste** (OK)
   - Los logs muestran:
     ```
     [SyncService] Connectivity restored
     [SyncService] Syncing pending operations...
     [TaskRepositoryImpl] Syncing operation: CREATE for task <id>
     [TaskRepositoryImpl] Operation synced successfully: <id>
     ```
   - En el backend (json-server o API): verifica que la tarea se envió

### Escenario 3: Editar Tarea en Modo Offline

**Objetivo**: Verificar que ediciones se encolan correctamente.

**Pasos**:

1. **Crear una tarea** con conexión (para que esté en la nube)
2. **Desconectar internet**
3. **Editar la tarea**: Cambiar título o marcar como completada
4. **Verificar**: Cambios visibles localmente
5. **Reconectar**: SyncService debe enviar operación UPDATE a la API
6. **Logs esperados**:
   ```
   [TaskRepositoryImpl] Queued operation: UPDATE for task <id>
   [SyncService] Syncing 1 pending operations...
   ```

### Escenario 4: Manejar Errores de Sincronización

**Objetivo**: Verificar reintentos y manejo de errores.

**Pasos**:

1. **Simular error de API**: Apaga temporalmente el backend (json-server)
2. **Crear/editar tarea** en modo offline
3. **Reconectar internet** (pero backend sigue apagado)
4. **Observar**:
   - La operación intenta sincronizar (primer intento)
   - Logs muestran error e `attempt_count` incrementa:
     ```
     [TaskRepositoryImpl] Sync attempt 1 failed: Connection refused
     [LocalDatabase] Incremented attempt_count to 1
     ```
   - SyncService **reintentará** después
5. **Reiniciar backend**: La app eventualmente sincroniza

### Escenario 5: Filtros en Modo Offline

**Objetivo**: Verificar que los filtros funcionan con datos locales.

**Pasos**:

1. **Desconectar internet**
2. **Crear varias tareas**, algunas completadas, otras no
3. **Tocar "Pendientes"**: Deben mostrarse solo tareas incompletas (datos locales)
4. **Tocar "Completadas"**: Deben mostrarse solo completadas
5. **Tocar "Todas"**: Todas aparecen

---

##  API REST - Contrato de Endpoints

### Base URL

```
http://10.0.2.2:3000  (Android emulator)
http://localhost:3000 (Desktop/Web)
```

### Endpoints

#### **GET /tasks**

Obtener todas las tareas.

```http
GET /tasks HTTP/1.1
Host: 10.0.2.2:3000
```

**Response (200 OK)**:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Hacer compras",
    "description": "Leche, pan, huevos",
    "completed": false,
    "updatedAt": "2025-11-15T10:30:00.000Z"
  }
]
```

#### **POST /tasks**

Crear una nueva tarea.

```http
POST /tasks HTTP/1.1
Host: 10.0.2.2:3000
Content-Type: application/json
Idempotency-Key: <unique-request-id>

{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "title": "Nueva tarea",
  "description": "Descripción opcional",
  "completed": false,
  "updatedAt": "2025-11-15T12:00:00.000Z"
}
```

#### **PUT /tasks/{id}**

Actualizar una tarea.

```http
PUT /tasks/550e8400-e29b-41d4-a716-446655440000 HTTP/1.1
Host: 10.0.2.2:3000
Content-Type: application/json
Idempotency-Key: <unique-request-id>

{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Tarea actualizada",
  "description": "Nueva descripción",
  "completed": true,
  "updatedAt": "2025-11-15T12:30:00.000Z"
}
```

#### **DELETE /tasks/{id}**

Eliminar una tarea.

```http
DELETE /tasks/550e8400-e29b-41d4-a716-446655440000 HTTP/1.1
Host: 10.0.2.2:3000
Idempotency-Key: <unique-request-id>
```

**Response (204 No Content)**:
```
(sin body)
```

---

##  Generación de APK

### APK de Debug (para testing)

```bash
flutter build apk --debug
```

**Salida**: `build/app/outputs/flutter-apk/app-debug.apk`

### APK de Release (para distribución)

```bash
flutter clean
flutter pub get
flutter build apk --release
```

**Salida**: `build/app/outputs/apk/release/app-release.apk`

---

##  Base de Datos - Esquema SQLite

### Tabla `tasks`

```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  completed INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0
);
```

### Tabla `queue_operations`

```sql
CREATE TABLE queue_operations (
  id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  op TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT
);
```

---

##  Troubleshooting

### "Failed to get tasks from local database"

```bash
flutter clean
flutter pub get
flutter run -v
```

### Sincronización no ocurre

Verifica que el backend esté corriendo:
```bash
json-server --watch db.json --port 3000
```

### APK Release muy grande

```bash
flutter build apk --release --split-per-abi
```

---

##  Referencias

- [Flutter Official Docs](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [sqflite Package](https://pub.dev/packages/sqflite)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)

---

