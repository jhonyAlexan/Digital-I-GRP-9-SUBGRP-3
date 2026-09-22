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
