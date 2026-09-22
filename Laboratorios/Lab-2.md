# 1. Dominio Comportamental

 ## 1.1 **Diagrama de Caja Negra:** 
 El sistema aísla la lógica interna de control para concentrarse exclusivamente en la interacción entre los captadores de señal (entradas) y los elementos accionadores o de señalización (salidas).

<div align="center">
  
![](https://github.com/jhonyAlexan/Digital-I-GRP-9-SUBGRP-3/blob/main/Imagenes/Caja-Negra.png)

Figura 1: Representación en caja negra del sistema de conmutación.
</div>

### **Definición de Entradas**
 - $I_1$ (Sensor Red Eléctrica): $1$ = Red disponible | $0$ = Red no disponible.
 - $I_2$ (Sensor Batería): $1$ = Batería cargada/disponible | $0$ = Batería descargada.
 - $I_3$ (Sensor Radiación Solar): $1$ = Presencia de radiación solar | $0$ = Sin radiación solar suficiente.
 - $I_4$ (Botón Paro de Emergencia): $1$ = Botón presionado (Mantenimiento) | $0$ = Estado normal.

### **Definición de Salidas** 
 - $Q_1$ (Relé Conmutador): $1$ = Conectado a Red Comercial | $0$ = Conectado a Batería.
 - $Q_2$ (Relé Energizador): $1$ = Casa energizada | $0$ = Casa desenergizada (Corte).
 - $Q_3$ (Luz Paro de Emergencia): $1$ = Indicador de paro encendido | $0$ = Apagado.
 - $Q_4$ (Luz Batería Descargada): $1$ = Indicador encendido | $0$ = Apagado.
 - $Q_5$ (Luz Casa Energizada): $1$ = Indicador encendido | $0$ = Apagado.
 - $Q_6$ (Luz Red Disponibilidad): $1$ = Indicador encendido | $0$ = Apagado.
 - $Q_7$ (Luz Radiación Solar): $1$ = Indicador encendido | $0$ = Apagado.

  ## 1.2 **Tabla de Verdad Criterio de diseño adoptado:** 
  Prioridad de consumo energético red eléctrica comercial. Cuando la red eléctrica comercial está disponible ($I_1 = 1$), se mantiene conectado el inversor ($Q_1 = 1$). Solo se conmuta a las baterías ($Q_1 = 0$) cuando la red eléctrica comercial presenta fallas ($I_1 = 0$) y las baterías cargadas ($I_2 = 1$).

<div align="center">
 
![](https://github.com/jhonyAlexan/Digital-I-GRP-9-SUBGRP-3/blob/main/Imagenes/TablaDeVerdad.png)

</div>

## 1.3 **Algoritmo y Diagrama de Flujo**
El algoritmo opera en un bucle continuo de escaneo:

<div align="center">
 
![](https://github.com/jhonyAlexan/Digital-I-GRP-9-SUBGRP-3/blob/main/Imagenes/diagram.png)

</div>

- Cuando $I_1 = 0$ e $I_2 = 0$, el sistema no tiene capacidad de energizar la casa ($Q_2 = 0$). Sin embargo, la lógica indica $Q_4 = 1$ para advertir que las baterías no tienen carga.
- La señal $I_4$ actúa como interrupción de mayor jerarquía. Independientemente del estado de la red o las baterías, si $I_4 = 1$, la casa se desenergiza automáticamente.

# 2. Dominio Físico Inicial

## 2.1 Esquema del Circuito Eléctrico de Control
El circuito se divide en dos secciones: Red de Potencia (AC) y Red de Control (DC 24V).
- Alimentación de Control: Fuente conmutada independiente de 24V DC con respaldo por batería auxiliar para garantizar la lectura de sensores y señalización aun durante fallas principales.
- Actuadores: Relé $Q_1$ (conmutador de contactos conmutados C/NO/NC) y Relé $Q_2$ (contactor de potencia con contacto NO principal).

## 2.2 Descripción y Diagrama en Lenguaje LadderEcuaciones Booleanas Simplificadas:
- $Q_1 = I_1$
- $Q_2 = (I_1 + I_2) \cdot \overline{I_4}$
- $Q_3 = I_4$
- $Q_4 = \overline{I_2}$
- $Q_5 = Q_2$
- $Q_6 = I_1$
- $Q_7 = I_3$

<div align="center">
 
![](https://github.com/jhonyAlexan/Digital-I-GRP-9-SUBGRP-3/blob/main/Imagenes/lenguaje-Ladder.png)

Diagrama de Contactos Ladder
</div>

- Se asume un contacto tipo conmutador. En estado desactivado ($Q_1 = 0$), conecta mecánicamente el inversor. Al energizar la bobina ($Q_1 = 1$), conmuta a la Red Comercial.
- Entradas Normales:
  - $I_1, I_2, I_3$ utilizan contactos Normalmente Abiertos (NO) que cierran al detectar estado verdadero.
  - $I_4$ utiliza un contacto Normalmente Abierto (NO) que cierra al pulsar el botón de emergencia.
- En el circuito físico real de potencia, se asume un interbloqueo mecánico/eléctrico entre las fuentes para evitar cortocircuitos entre la red pública y la salida del inversor.

## 3. Simulación en Lenguaje Ladder
Se encuentra en el siguiente enlace:
https://studio.rungs.dev/9fVoBLfx 

## 4. Simulación en Tinker Cad previo al montaje

Se usan las compuertas de la familia HC por tener tecnología CMOS que tienen mejor comportamiento frente al ruido.
<div align="center">
<img width="1627" height="802" alt="SimTKC" src="https://github.com/user-attachments/assets/346de9f2-527c-48cb-9e77-067efdeda4a7" />


