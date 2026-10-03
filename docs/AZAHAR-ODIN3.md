# Azahar en el AYN Odin 3

Estado: **2026-10-03**. Documento escrito a partir de la sesión de diagnóstico
real sobre el Odin 3 (`ssh odin`, usuario `deck`, hostname `pocknix-1`).

Hay **dos problemas distintos** y conviene no mezclarlos:

1. El gamepad interno no lo ve el emulador.
2. Azahar aborta al abrir Ajustes. **La causa está en gamescope, no en Azahar.**

---

## 1. El gamepad interno no aparece en SDL

### Síntoma

`SDL_NumJoysticks()` devuelve `0`. Azahar (y cualquier emulador basado en SDL) no ve
el gamepad, aunque `/dev/input/js0` y `/dev/input/event6` existen.

### Causa raíz

El builtin `input_id` de udev clasifica el mando interno del Odin como
**ratón**, no como joystick:

```
/dev/input/js0    "AYN Odin3 Gamepad"  vendor 0x2020  product 0x3001
/dev/input/event6 "AYN Odin3 Gamepad"  (rsinput-gamepad)
  ID_INPUT_MOUSE=1
  (sin ID_INPUT_JOYSTICK)
  symlink: platform-89c000.serial-event-mouse
```

El enumerador de joysticks de SDL3 filtra por `ID_INPUT_JOYSTICK`, así que el
dispositivo queda descartado antes de llegar al emulador. Confirmado con
`strings /usr/lib/libSDL3.so.0.4.14`.

El SDL del sistema es `sdl2-compat 2.32.70-1` (API SDL2 sobre SDL3 3.4.14).
El AppImage de Azahar **no incluye SDL**, usa el del sistema.

### Por qué no lo arregla `70-odin3-gamepad.rules`

Esa regla (en `/usr/lib/udev/rules.d/`) asume que udev ya marcó el
dispositivo como joystick ("systemd/udev ya setea para joysticks"). En este
equipo es falso, así que su regla de permisos **nunca llega a dispararse**:
depende de `ENV{ID_INPUT_JOYSTICK}` y esa variable no existe.

### Solución probada

Fijar `ID_INPUT_JOYSTICK=1` para ese dispositivo concreto. Regla temporal
usada en la sesión:

```
# /etc/udev/rules.d/60-input-id2-odin3-gamepad.rules
SUBSYSTEM=="input", ATTRS{name}=="AYN Odin3 Gamepad", ENV{ID_INPUT_JOYSTICK}="1"
```

El nombre `60-input-id2-...` es intencionado: tiene que ordenarse **después**
de `60-input-id.rules` (que es quien calcula mal `.INPUT_CLASS`) y **antes** de
`60-persistent-input.rules`.

Aplicar:

```sh
sudo udevadm control --reload-rules
sudo udevadm trigger --action=change /sys/class/input/event6 /sys/class/input/js0
```

Resultado: SDL pasa de 0 a **exactamente 1** mando, y los symlinks pasan a
`platform-89c000.serial-event-joystick` / `platform-89c000.serial-joystick`.

Revertir:

```sh
sudo rm /etc/udev/rules.d/60-input-id2-odin3-gamepad.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --action=change /sys/class/input/event6 /sys/class/input/js0
```

> **PENDIENTE:** decidir si la regla se queda permanente (afecta a todos los
> programas SDL del sistema) y en qué fichero. El sitio natural es
> `70-odin3-gamepad.rules`, junto al resto de reglas del proyecto, corrigiendo
> el comentario que asume que udev ya marcó el joystick.

### GUID del Odin

El GUID correcto lo devuelve SDL al enumerar el device, no hay que adivinarlo:

```
0300bb95202000000130000001000000
```

Descomposición:

| parte | valor | qué es |
|---|---|---|
| `0300` | 3 | bus USB |
| `bb95` | CRC16 | CRC16 de "AYN Odin3 Gamepad" |
| `2020` | | vendor |
| `0000` | | padding |
| `3001` | | product (van en el slot de versión) |
| `1000 0000` | | padding |

El GUID que hay hoy en `configs/azahar/qt-config.ini`:

```
0300f6b6c82d00000b31000014010000
```

está **mal formado**: son 30 hex = 15 bytes, truncado. Sustituir en las líneas
`profiles\1\...` (44 y ss.).

### InputPlumber no sirve para esto

Los pads virtuales de InputPlumber (`js1`, `/devices/virtual/input/...`,
"InputPlumber Generic Steam Controller") **no llegan a SDL**. Ya tenían
`ID_INPUT_JOYSTICK=1` y aun así SDL seguía viendo 0 devices: SDL se salta
casi todos los dispositivos bajo `/devices/virtual/input`. Cualquier diseño que
se apoye en el pad virtual de InputPlumber para los emuladores no va a
funcionar; la vía que funciona es el `event6` físico.

`event6` **no** está oculto por InputPlumber (solo `event4`, el táctil, vía
`50-inputplumber-hide-event4-early.rules` y `96-...-late.rules` en
`/run/udev/rules.d/`), así que la regla de arriba no choca con la regla del
proyecto de "no descubrir event6".

---

## 2. El crash de Ajustes NO es de Azahar

### Lo que se pensaba

Que la pestaña `Gráficos` de *Emulación → Configurar...* provocaba el crash.

### Lo que dice el core dump

El core no lo reproduce la pestaña Gráficos. La pila del thread principal
(PID 143237, 2026-10-02 23:40:53, SIGABRT) es:

```
#0-#1  tgkill                            libc.so.6
#2     gsignal                           libc.so.6
#3     abort                             libc.so.6
#4     __libc_message                    libc.so.6
#5     __assert_fail                     libc.so.6
#6     VkDispatchTableMap<VkDevice_t*>::insert
                                        libVkLayer_FROG_gamescope_wsi_aarch64.so
#7-#8  (libvulkan interno)               libvulkan.so.1.4.357
#9     vkCreateDevice                    libvulkan.so.1.4.357
#10    av_hwframe_ctx_create_derived     libavutil.so.61.1.102
#11-14 (plugin multimedia de Qt)        libffmpegmediaplugin.so
#15-18 QMediaDevices::videoInputs()      libQt6Multimedia.so.6.11.2
#19-21 (código de Azahar)                shared/bin/azahar
#22    QObjectPrivate::ConnectionData    libQt6Core.so.6.11.2
#23-24 glib main loop                    libglib-2.0.so.0
#25    QEventDispatcherGlib::processEvents libQt6Core.so.6.11.2
```

Y los argumentos de la aserción, leídos del core:

```
assertion: obj
file:      ../subprojects/vkroots/vkroots.h:129
function:  const DispatchType* vkroots::tables::VkDispatchTableMap<
             Object, DispatchType, DispatchPtr>::insert(Object, DispatchPtr)
             [with Object = VkDevice_T*; DispatchType = vkroots::VkDeviceDispatch; ...]
```

### Qué significa

1. Azahar llama a `QMediaDevices::videoInputs()` desde el bucle de eventos de
   Qt (enumera cámaras de vídeo).
2. Eso carga el backend multimedia de Qt, que es el plugin de FFmpeg.
3. El plugin de FFmpeg pide un contexto de hardware **Vulkan**
   (`av_hwframe_ctx_create_derived`).
4. Eso llama a `vkCreateDevice()`.
5. La **capa WSI de gamescope** (`libVkLayer_FROG_gamescope_wsi_aarch64.so`)
   intercepta ese `vkCreateDevice` y mete un `VkDevice_t*` **nulo** en su
   tabla de dispatch.
6. `vkroots` hace `__glibcxx_assert("obj")` → `abort()`.

Es un bug de gamescope. Azahar solo dispara la detonación.

Por eso el fallo parece aleatorio y por eso **no tiene nada que ver con la
pestaña Gráficos**: `videoInputs()` se llama desde el bucle de eventos, en
cualquier momento.

### Por qué solo pasa dentro de gamescope

`/usr/share/vulkan/implicit_layer.d/VkLayer_FROG_gamescope_wsi.aarch64.json`:

```json
"enable_environment":  { "ENABLE_GAMESCOPE_WSI": "1" },
"disable_environment": { "DISABLE_GAMESCOPE_WSI": "1" }
```

La capa solo se carga si el proceso tiene `ENABLE_GAMESCOPE_WSI=1` en el
entorno, y eso solo lo hace gamescope a las apps que lanza. Por eso:

- En ES-DE / gamescope (`:1`) → capa cargada → crash.
- En un Xvfb aparte sin esa variable → **imposible que crashee**, por eso las
  primeras pruebas nunca lo reproducían.

### Arreglo candidato

```sh
DISABLE_GAMESCOPE_WSI=1
```

en el entorno de Azahar. El sitio donde ponerlo es
`emulators/Azahar.sh` (la entrada que ES-DE usa), **no** `lanzar.sh`, que es
una plantilla regenerada por `/opt/deckstation/scripts/deploy-lanzar-sh.sh` y no
se debe editar a mano.

Riesgo asumido: Azahar podría dejar de componerse bien dentro de gamescope
(pantalla en negro o sin aceleración). Se deshace borrando la línea.

> **PENDIENTE:** el arreglo **no está probado**. Falta reproducir con
> `ENABLE_GAMESCOPE_WSI=1` y luego comprobar que `DISABLE_GAMESCOPE_WSI=1` lo
> evita.

---

## 3. Lo que NO está hecho

- El GUID bueno **no** está escrito en `configs/azahar/qt-config.ini`. Sigue el
  truncado `0300f6b6c82d00000b31000014010000`.
- `graphics_api=2` (Vulkan) no se ha tocado. Ojo: el enum es
  `Software, OpenGL, Vulkan`, así que `1` sería OpenGL, y se guarda como
  `@Variant(...)`, no como entero pelado.
- La regla udev **no** se ha convertido en permanente.
- No hay copia de seguridad de `qt-config.ini` porque **no se ha modificado**.

---

## 4. Notas operativas (para no volver a perder horas)

**AppImage y su montaje fuse.** El AppImage de Azahar usa `fuse.dwarfs`. Al
matar el proceso a SIGKILL el montaje se queda colgado y el siguiente arranque
falla con:

```
Existing mount at /tmp/.mount_Azaharemp... does not have a valid mapping and
process generation record; refusing unsafe reuse
```

Arreglo:

```sh
fusermount3 -u  /tmp/.mount_Aza*    # o -uz si está huérfano
rm -rf         /tmp/.mount_Aza*
```

**No matar `dwarfs`.** Si lo matas, el montaje queda huérfano sin
`auto_unmount` y ningún `umount` posterior funciona. Además `fusermount3`
aborta en el primer argumento que no sea un mountpoint, así que el glob
`/tmp/.mount_Aza*` (que también matchea `.lock` y `.pid`) no vale: hay que
pasarle un solo directorio.

**Azahar ignora SIGTERM.** Hay que pasar a SIGKILL.

**Probar en un Xvfb aislado.** Para no tocar la sesión real se puede lanzar
contra un `Xvfb :9` propio:

```sh
cd /opt/deckstation && DISPLAY=:9 XDG_RUNTIME_DIR=/run/user/1001 \
  setsid ./Apps/Azahar/lanzar.sh > /tmp/az.out 2>&1 < /dev/null &
```

Con `QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1 QT_ACCESSIBILITY=1` la app se registra
en AT-SPI y se puede inspeccionar (no se pueden leer las capturas, así que la
navegación va por AT-SPI + `xdotool`).

**Xvfb sin gestor de ventanas.** No hay WM, así que:

- Hay que dar el foco a mano: `xdotool windowfocus <id>`.
- Los clics del `QMenuBar` no llegan; abrir el menú con la mnemónica
  (`xdotool key alt+e`) sí funciona.
- Con `QT_SCALE_FACTOR != 1` las coordenadas que da AT-SPI son **lógicas**:
  hay que multiplicarlas por el factor antes de pasar a `xdotool`.
- Las extensiones AT-SPI cachean los hijos: para obtener coordenadas frescas
  hay que consultar en un proceso nuevo, no reutilizar el objeto `Accessible`.

**`lanzar.sh` no se edita a mano.** Es plantilla; se regenera con
`/opt/deckstation/scripts/deploy-lanzar-sh.sh`.