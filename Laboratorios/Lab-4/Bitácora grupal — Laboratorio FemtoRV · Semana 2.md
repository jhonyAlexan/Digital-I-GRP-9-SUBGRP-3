# Bitácora grupal — Laboratorio FemtoRV · Semana 2

Grupo: \[COMPLETAR\] · Integrantes: \[COMPLETAR\] · Tarjeta: \[Colorlight 5A-75E / Tang Nano 9K\]

> Los campos **\[COMPLETAR\]** requieren ejecutar un comando, tomar una captura o medir. El resto está deducido del código del laboratorio: verifíquenlo contra su simulación antes de entregar.

## Tarea 1. Especificar el periférico GPIO

### 1.1 Tabla de registros (base `0x0041_0000`, `cs[1]`)

| Dirección | Nombre | Acceso | Bits usados | Valor tras reset | Si se escribe… | Si se lee… |
| --- | --- | --- | --- | --- | --- | --- |
| `0x0041_0004` | LEDS | L/E | \[7:0\] | `0x00` | Se guarda `d_in[7:0]` y se actualizan los LEDs externos (1 = encendido) | Devuelve `{24'b0, leds}` |
| `0x0041_0008` | BOTONES | L (solo lectura) | \[3:0\] | — (no tiene registro: refleja los pines) | Se ignora | Devuelve `{28'b0, botones}` (1 = presionado) |
| otra `0x0041_xxxx` | — | — | — | — | Se ignora | Devuelve 0 |

### 1.2 Caja negra

| Puerto | Ancho | Sentido | De dónde viene / a dónde va |
| --- | --- | --- | --- |
| `clk` | 1 | entrada | Reloj del SoC |
| `reset` | 1 | entrada | `!resetn` desde `SOC.v` (activo en alto) |
| `d_in` | 32 | entrada | Procesador: `mem_wdata` |
| `cs` | 1 | entrada | `chip_select`: `cs[1]` (`cs_chip1`) |
| `addr` | 32 | entrada | Procesador: `mem_addr` (solo se usan los 5 bits bajos) |
| `rd` | 1 | entrada | Procesador: `mem_rstrb` |
| `wr` | 1 | entrada | Procesador: `\|mem_wmask` |
| `botones` | 4 | entrada | Pines de la tarjeta (`BOTONES`) |
| `d_out` | 32 | salida | Hacia `chip_select` (`chip1_dout`) y de ahí al procesador |
| `leds` | 8 | salida | Pines de la tarjeta (`LEDS_EXT`) |

Dibujo de la caja negra: \[COMPLETAR: imagen\]

## Tarea 2. Descripción en Verilog

Se copió la plantilla a `soc/rtl/perip_gpio.v` y se completaron las tres partes siguiendo el modelo de `perip_mult.v`:

```verilog
// PARTE 1. Decodificador interno (5 bits bajos de addr)
wire sel_leds    = cs && (addr[4:0] == 5'h04);
wire sel_botones = cs && (addr[4:0] == 5'h08);

// PARTE 2. Escritura
always @(posedge clk) begin
  if (reset)
    leds <= 8'b0;
  else if (wr && sel_leds)
    leds <= d_in[7:0];
end

// PARTE 3. Lectura
always @(posedge clk) begin
  if (rd) begin
    if (sel_leds)
      d_out <= {24'b0, leds};      // 8 bits + 24 ceros = 32
    else if (sel_botones)
      d_out <= {28'b0, botones};   // 4 bits + 28 ceros = 32
    else
      d_out <= 32'b0;
  end
end
```

Justificación:

- `sel_leds` ya incluye `cs`, por eso la condición de escritura solo agrega `wr`.
- LEDS tiene 8 bits, así que se completan con 24 ceros; BOTONES tiene 4, con 28 ceros.
- Cada parte corresponde a una fila de la tabla 1.1: la escritura solo existe para LEDS porque BOTONES es de solo lectura.

Comprobación de compilación: `iverilog -g2012 -o build/gpio_check.vvp rtl/perip_gpio.v && echo "Compila"` 

La captura del resultado es la siguiente:

<img width="929" height="254" alt="Tarea 2  compila" src="https://github.com/user-attachments/assets/8de9abb6-21c2-427f-9ae3-bb912ff88c9d" />


## Tarea 3. Probar el periférico solo

### 3.1 Pruebas agregadas al testbench

Se copió `plantillas/tb_perip_gpio.v` a `soc/sim/` y se completaron las pruebas 3, 4 y 5 con el mismo modelo que las anteriores:

```verilog
// 3. Escribir en BOTONES no cambia los LEDs
escribir(32'h0041_0008, 32'hFF);
comprobar("leds tras escribir BOTONES", leds, 8'hA5);

// 4. Escribir en otro periférico no cambia los LEDs
escribir(32'h0042_0004, 32'hFF);
comprobar("leds tras escribir en 0x0042", leds, 8'hA5);

// 5. Leer una dirección sin registro devuelve 0
leer(32'h0041_000C, valor);
comprobar("leer sin registro", valor, 32'h0000_0000);
```

Tabla de pruebas (módulo, estímulo, resultado esperado, criterio):

| # | Comportamiento | Estímulo | Esperado | Criterio |
| --- | --- | --- | --- | --- |
| ej. | Escritura en LEDS | `escribir(0x0041_0004, 0xA5)` | `leds = 0xA5` | `comprobar` = OK |
| 1 | Lectura de LEDS | `leer(0x0041_0004)` | `0x0000_00A5` | OK |
| 2 | Lectura de BOTONES | `botones = 1001`, `leer(0x0041_0008)` | `0x0000_0009` | OK |
| 3 | BOTONES es de solo lectura | `escribir(0x0041_0008, 0xFF)` | `leds` sigue en `0xA5` | OK |
| 4 | Otro periférico no afecta | `escribir(0x0042_0004, 0xFF)` (el `cs` del testbench queda en 0) | `leds` sigue en `0xA5` | OK |
| 5 | Dirección sin registro | `leer(0x0041_000C)` | `0x0000_0000` | OK |

### 3.2 Simulación

```
iverilog -g2012 -o build/tb_gpio.vvp sim/tb_perip_gpio.v rtl/perip_gpio.v
vvp -n build/tb_gpio.vvp
gtkwave build/tb_perip_gpio.vcd &
```

- Salida de la terminal (debe terminar en `--- 0 errores ---`): \[COMPLETAR: pegar\]
- Captura de GTKWave de la escritura del ejemplo con `clk`, `cs`, `wr`, `addr`, `d_in` y `leds`, señalando el flanco en que `leds` cambia: \[COMPLETAR: imagen\]

Explicación de la captura: `cs` y `wr` suben con la dirección `0x0041_0004` y el dato `0xA5` presentes; en el siguiente flanco de subida de `clk` el registro `leds` toma `0xA5`, que es la regla de escritura (`cs = 1`, `wr = 1`, dirección del registro → guardar en el flanco).

<img width="925" height="312" alt="tarea3 1" src="https://github.com/user-attachments/assets/cf4c7076-31ab-4d2e-9c97-f51a9ba4dea3" />


## Tarea 4. Conectarlo al SoC

Todos los cambios fueron en `rtl/SOC.v`; no se tocaron el procesador ni `chip_select.v`.

1. **Declarar el cable de salida** junto a los de los otros periféricos:

```verilog
wire [31:0] gpio_dout;
```

2. **Llevarlo al multiplexor de lectura** en la instancia de `chip_select` (línea 88):

```verilog
.chip1_dout(gpio_dout),    // antes: 32'b0
```

3. **Borrar** `assign LEDS_EXT = 8'b0;` (línea 160), porque `LEDS_EXT` ahora lo maneja el periférico.
4. **Instanciar el periférico** en ese mismo lugar:

```verilog
perip_gpio gpio (
    .clk    (clk),
    .reset  (!resetn),     // el periférico usa reset activo en alto
    .d_in   (mem_wdata),
    .cs     (cs_chip1),
    .addr   (mem_addr),
    .rd     (rd),
    .wr     (wr),
    .d_out  (gpio_dout),
    .botones(BOTONES),
    .leds   (LEDS_EXT)
);
```

Explicación:

- El bus (`mem_addr`, `mem_wdata`, `rd`, `wr`) llega a todos los bloques; solo reacciona el que tiene su `cs` en 1. Aquí `cs_chip1 = cs[1]`, que `chip_select` activa con `0x0041_xxxx`.
- Sin el cambio 2, el procesador podría escribir en el GPIO pero siempre leería 0, porque `chip1_dout` seguiría fijo en `32'b0`.
- El `reset` se invierte porque el SoC usa `resetn` activo en bajo y el periférico usa reset activo en alto.
- El `Makefile` incluye solo cualquier archivo `rtl/perip_*.v`, así que no hizo falta modificarlo.

Comprobación: `make sim` sigue imprimiendo la salida de la semana 1 

<img width="918" height="558" alt="tarea4" src="https://github.com/user-attachments/assets/8a735411-370f-47a1-8f08-0dff9c693315" />



## Tarea 5. El programa en C

### 5.0 Código completado (`firmware/gpio.c`)

```c
#define GPIO_LEDS     REG(GPIO_BASE + 0x04)
#define GPIO_BOTONES  REG(GPIO_BASE + 0x08)

// dentro del while (1):
uint32_t b = GPIO_BOTONES;
if (b == 0)      GPIO_LEDS = 0x01;   // ningún pulsador
else if (b == 1) GPIO_LEDS = 0x15;   // pulsador 0 -> 010101
else if (b == 2) GPIO_LEDS = 0x2A;   // pulsador 1 -> 101010
else             GPIO_LEDS = 0x3F;   // ambos
```

`GPIO_LEDS = 0x2A;` se compila a un `sw` a `0x0041_0004`, y `x = GPIO_BOTONES;` a un `lw` de `0x0041_0008`. La macro `REG()` (con `volatile`) hace que cada acceso se ejecute tal como está escrito.

### 5.1 Simulación con distintos pulsadores

Comandos: `make sim PROG=gpio` y `make sim PROG=gpio ARGS="+botones=N +ciclos=200000"`.

| `+botones=` | LEDS esperado (su patrón) | `LEDS_EXT` en la simulación | ¿Coincide? |
| --- | --- | --- | --- |
| 0 | `0x01` | esperado `00000001` · obtenido \[COMPLETAR\] | \[COMPLETAR\] |
| 1 | `0x15` | esperado `00010101` · obtenido \[COMPLETAR\] | \[COMPLETAR\] |
| 2 | `0x2A` | esperado `00101010` · obtenido \[COMPLETAR\] | \[COMPLETAR\] |

### 5.2 Pregunta

La lectura `LEDS = 0x0000002A` la hace posible la **parte 3 (lectura)** del periférico: cuando `rd = 1` y `sel_leds = 1`, pone `{24'b0, leds}` en `d_out`, y el cambio 2 de `SOC.v` (`.chip1_dout(gpio_dout)`) lleva ese dato hasta el procesador. Si faltara cualquiera de las dos, el programa imprimiría `LEDS = 0x00000000`: en el primer caso porque `d_out` no tendría el valor, y en el segundo porque `chip_select` devolvería `32'b0`.

## Tarea 6. En la tarjeta

Conexiones según `Tarjetas.md`. Comandos:

```
make syn PROG=gpio BOARD=[colorlight | tangnano9k]
make config BOARD=...
make terminal BOARD=...
```

| `+botones=` / pulsador presionado | Comportamiento esperado de los LEDs | Observado | Evidencia |
| --- | --- | --- | --- |
| Ninguno | `0x01` | \[COMPLETAR\] | \[foto/video\] |
| Pulsador 0 | `0x15` | \[COMPLETAR\] | \[foto/video\] |
| Pulsador 1 | `0x2A` | \[COMPLETAR\] | \[foto/video\] |

Nota Tang Nano 9K: solo hay un pulsador de usuario (S2 → `BOTONES[0]`); el caso del pulsador 1 se comprueba en simulación o con un pulsador externo.

Comparación de recursos (tabla al final de `make syn`):

|  | SoC de la semana 1 | SoC con GPIO |
| --- | --- | --- |
| LUT | \[COMPLETAR\] | \[COMPLETAR\] |
| BRAM | \[COMPLETAR\] | \[COMPLETAR\] |
| Frecuencia máxima | \[COMPLETAR\] | \[COMPLETAR\] |

## Tarea 7. Experimento: ¿cuánto cuesta una tarea hecha por software?

### 7.1 Predicción

El bucle de `parpadeo.c` se compila a tres instrucciones (verificable en `build/firmware.lst`):

| Línea de C | Instrucción | Ciclos |
| --- | --- | --- |
| `GPIO_LEDS = 1;` | `sw a4,0(a5)` | 4 |
| `GPIO_LEDS = 0;` | `sw zero,0(a5)` | 4 |
| vuelta al `while` | `j ...` | 3 |
| **Una vuelta** |  | **11** |

Los `sw` recorren buscar → esperar → ejecutar → esperar memoria (4 ciclos) y el salto recorre buscar → esperar → ejecutar (3). Una vuelta enciende y apaga el LED una vez: el periodo es 11 ciclos.

| Tarjeta | Periodo (11 ciclos) | Frecuencia |
| --- | --- | --- |
| Colorlight, 25 MHz (40 ns/ciclo) | 11 × 40 ns = **440 ns** | 25 MHz / 11 ≈ **2,27 MHz** |
| Tang Nano 9K, 27 MHz (37,04 ns/ciclo) | 11 × 37,04 ns ≈ **407 ns** | 27 MHz / 11 ≈ **2,45 MHz** |

### 7.2 Medición en simulación

Comandos: `make sim PROG=parpadeo ARGS="+vcd +ciclos=2000"` y `make wave`, con `clk` y `LEDS_EXT[0]`.

- Ciclos contados entre dos flancos de subida consecutivos de `LEDS_EXT[0]`: \[COMPLETAR\] (esperado: 11, es decir 440 ns).
- Captura con los cursores: \[COMPLETAR: imagen\]

### 7.3 Medición en la tarjeta

- Instrumento usado: \[osciloscopio / analizador lógico\]. Se mide en el pin del LED 0 (J2 en la Colorlight; ver `Tarjetas.md`, opción A, para la Tang Nano).
- Frecuencia medida: \[COMPLETAR\] · Periodo medido: \[COMPLETAR\]
- Captura: \[COMPLETAR: imagen\]
- Aviso práctico: a unos 2,3 MHz el LED se ve encendido de forma continua, así que solo se puede comprobar con instrumento, y el analizador lógico debe muestrear bastante por encima de 2,3 MHz.

### 7.4 Conclusión

1. **¿Coinciden cálculo, simulación y medición?** \[COMPLETAR: comparar los tres valores y explicar cualquier diferencia, por ejemplo la tolerancia del reloj de la tarjeta o la resolución del instrumento.\] Si la simulación da 11 ciclos, el cálculo con la máquina de estados (3 y 4 ciclos por instrucción) queda verificado.
2. **¿Podría el FemtoRV generar por software la señal de la pantalla de 4,3"?** No. Un dato de píxel nuevo unas 9 millones de veces por segundo exige uno cada 1/9 MHz ≈ 111 ns, que son unos 2,8 ciclos a 25 MHz. Una sola escritura (`sw`) ya cuesta 4 ciclos = 160 ns, más de lo permitido, sin contar el salto del bucle, el cálculo del siguiente píxel ni las señales de sincronismo. Incluso en el mejor caso (una escritura por píxel) el procesador queda por debajo de lo necesario. Por eso en la consola irán en **hardware**, como periférico: el generador de temporización de video (reloj de píxel, sincronismos y lectura del framebuffer), y probablemente otras tareas de flujo continuo como el PWM de audio o el barrido de un panel de LEDs. En **software** quedan las tareas lentas y de decisión: lógica del juego, menú, lectura de controles (polling) y puntajes.

## Valor agregado (opcional): periférico del laboratorio anterior

Si su controlador del laboratorio de periféricos fue el puente H con PWM, una propuesta de tabla de registros en `0x0043_0000` (`cs[3]`) sería:

| Dirección | Nombre | Acceso | Bits | Significado |
| --- | --- | --- | --- | --- |
| `0x0043_0004` | CONTROL | L/E | bit 0, bit 1 | bit 0 = habilitar, bit 1 = sentido de giro |
| `0x0043_0008` | DUTY | L/E | \[N-1:0\] | Ciclo útil del PWM (N según el ancho del contador de su diseño) |

Pasos: conectar `cs_chip3` y un `chip3_dout` en `SOC.v`, agregar el puerto del pin del motor en el top y el archivo de pines, probarlo con un testbench de bus (una prueba por fila) y controlarlo desde C con `#define` análogos a los del GPIO. Ajusten los registros a lo que realmente ofrece su diseño.

## Lo que va a la bitácora esta semana (lista de verificación)

- [ ] Tarea 1: tabla de registros y caja negra.
- [ ] Tarea 3: salida con 0 errores y captura de la escritura.
- [ ] Tarea 4: fragmento de `SOC.v` explicado.
- [ ] Tarea 5: tabla de simulación y respuesta.
- [ ] Tarea 6: foto o video en la tarjeta.
- [ ] Tarea 7: periodo y frecuencia calculados, captura de simulación, captura del instrumento y conclusión.
