# Cómo contribuir a DeckStation ARM

Este repositorio y el **centro de Pocknix para la AYN Odin 3**
(`arcadematicas/pocknix-odin3-support`, carpeta `packages/deckstation-arm/`) contienen
**lo mismo**: son dos sitios con el mismo contenido.

## La regla

Cualquier cambio de DeckStation que se haga **para el sistema de la Odin 3**
(wrapper de Steam, cores, configs de RetroArch, ES-DE, scripts, arte…) tiene que
quedar reflejado **en los dos sitios**.

- Si solo se sube aquí, **la próxima imagen de la Odin no lo llevará**.
- Si solo se sube al centro, **aquí no lo verán los demás**.

## El flujo (cambios que salen del sistema de la Odin)

1. Editar en el centro: `pocknix-odin3-support/packages/deckstation-arm/<ruta>`
2. Copiarlo aquí: `cp <centro>/packages/deckstation-arm/<ruta> /home/fransis/deckstation-arm/<ruta>`
3. Subir este repo: `git -C /home/fransis/deckstation-arm add -A && git commit -m "..." && git push`
4. Subir el centro: `git -C <centro> add -A && git commit -m "..." && git push`
5. Desplegarlo a la Odin (solo si hay que probarlo ya): `tools/deploy-to-device.sh <paquete>`
6. Comprobar que no queda nada descuadrado:

   ```bash
   diff -rq <centro>/packages/deckstation-arm /home/fransis/deckstation-arm
   ```

## Aviso importante (nos ha mordido ya)

Los scripts (`scripts/*.sh`) **no los gestiona ningún paquete**: los despliega el
propio DeckStation en `/opt/deckstation/scripts/`. Si tocas uno, además de subirlo a
los dos sitios, **cópialo a mano a la Odin**, o se quedará viejo sin que nadie se
entere.
