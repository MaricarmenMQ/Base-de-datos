# 📊 Base de Datos — Hotel System (v2 con datos reales)

Esta carpeta contiene la base de datos del sistema hotelero, construida con los **datos reales** que pasó tu cliente (25 habitaciones distribuidas en 3 pisos, 6 tipos de habitación, tarifas por franja horaria y temporadas).

## 📁 Archivos

```
database/
├── schema.sql       ← Estructura: 14 tablas, 3 triggers, 4 vistas
├── seed.sql         ← Datos REALES del cliente (25 habitaciones, tarifas, etc.)
├── migrations/      ← Cambios futuros versionados
└── README.md        ← Este archivo
```

## 🚀 Instalación con XAMPP — Paso a paso (Windows)

### Paso 1: Iniciar XAMPP

1. Abre el **panel de control de XAMPP** (`xampp-control.exe`)
2. Click en **Start** junto a **Apache**
3. Click en **Start** junto a **MySQL**

   ✅ Cuando estén corriendo, se ponen verdes y muestran los puertos (Apache: 80, MySQL: 3306)

   ❌ Si **MySQL** no arranca:
   - Probablemente otro MySQL ya está usando el puerto 3306
   - Solución 1: Detén el otro MySQL desde Servicios de Windows (`services.msc` → MySQL → Detener)
   - Solución 2: Cambia el puerto de XAMPP. Click en **Config → my.ini**, busca `port=3306` y cámbialo a `port=3307`. Reinicia MySQL. Recuerda este puerto para el `.env` del backend.

### Paso 2: Abrir phpMyAdmin

1. En el panel de XAMPP, click en **Admin** (botón al lado de MySQL)
2. Se abre tu navegador en `http://localhost/phpmyadmin`

   ⚠️ Si pide usuario/contraseña: usuario es `root`, contraseña **vacía** (default de XAMPP). Si te pidieron poner contraseña al instalar, usa la que pusiste.

### Paso 3: Importar `schema.sql`

1. En phpMyAdmin, **NO crees ninguna BD** todavía (el script lo hace solo)
2. Click arriba en la pestaña **"Importar"** (Import)
3. Click en **"Seleccionar archivo"** → busca `database/schema.sql`
4. Baja al final de la página → click en **"Continuar"** (Go)
5. Espera ~5 segundos. Deberías ver:

   ```
   ✅ La importación se ha completado con éxito.
   ```

   Y a la izquierda verás aparecer la BD **`hotel_system`** con sus 14 tablas.

### Paso 4: Importar `seed.sql`

1. Sin cerrar phpMyAdmin, click otra vez en la pestaña **"Importar"**
2. Selecciona `database/seed.sql`
3. Click en **"Continuar"**
4. Verás:

   ```
   ✅ La importación se ha completado con éxito.
   ```

### Paso 5: Verificar que todo cargó bien

En phpMyAdmin, click izquierdo sobre **`hotel_system`** → click en pestaña **"SQL"** (arriba) → pega esta query:

```sql
USE hotel_system;
SELECT
  (SELECT COUNT(*) FROM habitaciones)                   AS habitaciones,
  (SELECT COUNT(*) FROM usuarios)                       AS usuarios,
  (SELECT COUNT(*) FROM clientes WHERE tipo_cliente='frecuente') AS clientes_frecuentes,
  (SELECT COUNT(*) FROM tarifas_franjas)                AS tarifas_franjas,
  (SELECT COUNT(*) FROM tarifas_noche_temporada)        AS tarifas_temporadas,
  (SELECT COUNT(*) FROM productos)                      AS productos,
  (SELECT COUNT(*) FROM limpieza_registros)             AS limpiezas;
```

Click en **"Continuar"** y deberías ver:

| habitaciones | usuarios | clientes_frecuentes | tarifas_franjas | tarifas_temporadas | productos | limpiezas |
|--------------|----------|---------------------|-----------------|--------------------|-----------|-----------|
| **25**       | **6**    | **2**               | **24**          | **30**             | **3**     | **2**     |

Si los números coinciden → **¡Importación exitosa! 🎉**

## 📊 Estructura general (14 tablas)

```
SISTEMA / USUARIOS
  ├── usuarios               ← admin, recepcionistas, limpieza
  ├── sesiones               ← refresh tokens JWT
  ├── auditoria              ← qué hizo cada quien y cuándo
  └── notificaciones         ← Socket.IO + historial

CLIENTES Y RESERVAS
  ├── clientes               ← huéspedes (12 campos del registro real)
  ├── reservas               ← estancias por noche o por horas
  ├── insumos_entregados     ← toalla, jabón, papel higiénico
  └── objetos_perdidos       ← objetos olvidados

HABITACIONES Y PRECIOS
  ├── habitaciones           ← 25 habitaciones reales del cliente
  ├── camas_habitacion       ← N camas por habitación
  ├── tarifas_franjas        ← precio por hora del día
  ├── temporadas             ← Fiestas Patrias, Año Nuevo, etc.
  └── tarifas_noche_temporada ← precio por noche según temporada

LIMPIEZA (corazón del sistema)
  ├── limpieza_registros     ← cada limpieza con auditoría completa
  └── turnos_limpieza        ← resumen diario por turno

OPERACIONES
  ├── productos              ← lo que vende el hotel (toallas, etc.)
  ├── ventas_productos       ← ventas asociadas a reservas
  └── configuracion_hotel    ← settings (check-in time, RUC, etc.)
```

## 🏨 Datos reales del cliente cargados

### Hotel
- **3 pisos** (2, 3, 4)
- **25 habitaciones** totales
- Check-in **12:00 PM** / Check-out **11:00 AM**

### Habitaciones por piso

| Piso | Habitaciones |
|------|--------------|
| 2    | 201–208 (8 habs) |
| 3    | 301–309 (9 habs) |
| 4    | 401–408 (8 habs) |

### 6 tipos de habitación (datos del cliente)

| Tipo (en BD)                  | Descripción                          | Cantidad |
|-------------------------------|--------------------------------------|----------|
| `matrimonial_privada_ducha`   | Matrimonial privada c/n ducha y baño | ~10      |
| `matrimonial_bano`            | Matrimonial solo c/n baño            | ~2       |
| `tv_cable`                    | TV cable                             | ~9       |
| `simple`                      | Simple                               | 2        |
| `doble_privada`               | Doble privada baño y ducha           | 1        |
| `doble_tv_cable`              | Doble c/n TV cable                   | 2        |

### Tarifas por hora (4 franjas reales)

```
Franja 1: 5am – 12pm  (mañana)
Franja 2: 12pm – 7pm  (tarde)
Franja 3: 7pm – 10pm  (noche)
Franja 4: 10pm – 5am  (madrugada)
```

### Temporadas con tarifas especiales
- Tarifa Regular (todo el año)
- Fiestas Patrias (26-30 Julio)
- Año Nuevo (29 Dic - 2 Ene)
- Semana Santa (29 Mar - 5 Abr)
- Temporada Alta (Julio-Agosto)

⚠️ **Aviso del cliente:** los precios de temporadas están "parcialmente inventados" en el HTML — confirma con tu cliente antes de poner el sistema en producción.

## 🔑 Credenciales de prueba

⚠️ **Las contraseñas no funcionan todavía.** Los hashes en el `seed.sql` son placeholders. Para activarlas necesitas correr el backend (Fase 2):

```bash
cd backend
npm run seed:passwords
```

Después de eso, podrás hacer login con:

| Usuario      | Contraseña  | Rol           | Turno   |
|--------------|-------------|---------------|---------|
| `admin`      | `admin123`  | Administrador | Rotativo |
| `recep1`     | `recep123`  | Recepcionista | Mañana  |
| `recep2`     | `recep123`  | Recepcionista | Tarde   |
| `recep3`     | `recep123`  | Recepcionista | Noche   |
| `limpieza1`  | `limp123`   | Limpieza (Juanita)  | Mañana |
| `limpieza2`  | `limp123`   | Limpieza (Rosa)     | Tarde  |

## 🔁 Resetear la BD desde cero

Si quieres empezar limpio:

**Opción A — Desde phpMyAdmin:**
1. Click izquierdo en `hotel_system`
2. Pestaña **"Operaciones"**
3. Sección "Eliminar la base de datos" → **"Eliminar la base de datos"**
4. Confirmar
5. Vuelve a Importar `schema.sql` y `seed.sql`

**Opción B — Por SQL:**
```sql
DROP DATABASE hotel_system;
```
Y vuelves a importar los archivos.

## 🐛 Problemas comunes

### "MySQL no arranca en XAMPP"

→ Otro MySQL está usando el puerto 3306. Detén el servicio de Windows o cambia el puerto.

### "Error: #1064 - You have an error in your SQL syntax"

→ Tu MySQL es muy viejo. Necesitas **MySQL 8.0+** o **MariaDB 10.5+**. XAMPP nuevo (8.x) ya viene con MariaDB compatible.

### "Error: #1452 - Cannot add or update a child row: a foreign key constraint fails"

→ Estás corriendo `seed.sql` antes que `schema.sql`. Corre primero el schema.

### "Caracteres raros (ñ, tildes salen como Ã±, Ã©)"

→ La BD usa `utf8mb4`. En phpMyAdmin: ve a **"Configuración" → "Idioma"** y verifica que esté en `utf-8`. También en el archivo SQL verifica que abra como UTF-8 en tu editor.

### "La página phpMyAdmin tarda muchísimo"

→ XAMPP está iniciando. Espera 30 segundos después de darle Start a Apache y MySQL.

### "Cuando importo me dice 'archivo demasiado grande'"

→ El archivo `seed.sql` debería ser <50 KB, no debería pasar. Si te pasa con uno tuyo en el futuro: edita `php.ini` en XAMPP, busca `upload_max_filesize` y `post_max_size`, súbelos a `64M`. Reinicia Apache.

## 🛠️ Modificar el esquema en el futuro

**No edites `schema.sql` directamente** una vez que estés en producción. En vez de eso, crea un archivo nuevo en `migrations/`:

```
migrations/
├── 001_agregar_columna_X.sql
├── 002_crear_tabla_Y.sql
└── ...
```

Y los aplicas en orden. Esto te permite saber qué cambios se aplicaron a cada base de datos (la tuya, la de tu colaborador, la de producción).

## 💡 Queries útiles para explorar

```sql
-- Ver todas las habitaciones con su info amigable
SELECT * FROM vista_habitaciones_completa;

-- Ver qué habitaciones están sucias / pendientes de limpiar
SELECT numero, piso, estado_limpieza
FROM habitaciones
WHERE estado_limpieza IN ('sucia','en_limpieza','limpieza_pendiente_validacion');

-- Resumen del dashboard (lo que pidió el cliente)
SELECT * FROM vista_dashboard_modulos;

-- Tarifas de una habitación tipo "TV cable" para hoy a las 8pm
SELECT * FROM tarifas_franjas
WHERE tipo_habitacion = 'tv_cable'
  AND '20:00:00' BETWEEN hora_inicio AND hora_fin
  AND activo = TRUE;

-- Productividad de limpieza de los últimos 7 días
SELECT * FROM vista_limpieza_por_empleado
WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);

-- Buscar cliente por nombre o documento (búsqueda fulltext)
SELECT * FROM clientes
WHERE MATCH(nombres, apellidos, numero_documento)
      AGAINST('Pérez' IN NATURAL LANGUAGE MODE);
```
