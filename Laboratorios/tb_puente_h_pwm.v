// =============================================================================
// tb_puente_h_pwm.v
// -----------------------------------------------------------------------------
// Testbench automático para el controlador de puente H con PWM.
// =============================================================================
`timescale 1ns/1ps

module tb_puente_h_pwm;

    localparam CLK_FREQ_TB = 1_000_000;                       // 1 MHz
    localparam F_PWM_TB    = 1_000;                           // 1 kHz (Periodo = 1 ms)
    localparam T_CLK       = 1_000_000_000 / CLK_FREQ_TB;     // 1000 ns (1 us)

    reg clk   = 1'b0;
    reg fwd_n = 1'b1, rev_n = 1'b1;  // Activos en bajo (1 = suelto)
    reg v1_n  = 1'b1, v2_n  = 1'b1, v3_n = 1'b1;

    wire in1, in2, ena;

    always #(T_CLK/2) clk = ~clk;     // Generador de reloj

    // ---- Diseño Bajo Prueba (DUT) -------------------------------------------
    puente_h_pwm #(
        .CLK_FREQ(CLK_FREQ_TB),
        .F_PWM(F_PWM_TB)
    ) dut (
        .clk  (clk),
        .fwd_n(fwd_n),
        .rev_n(rev_n),
        .v1_n (v1_n),
        .v2_n (v2_n),
        .v3_n (v3_n),
        .in1  (in1),
        .in2  (in2),
        .ena  (ena)
    );

    integer errores = 0;

    // ---- Tarea: Mide periodo y ancho de pulso alto de ENA -------------------
    task medir_pwm;
        input [8*20-1:0] nombre;
        input integer    ton_esperado_us;
        time t_subida, t_bajada, t_siguiente;
        integer ton_medido, periodo_medido;
        begin
            @(posedge ena);                   // Espera inicio del pulso
            t_subida = $time;
            @(negedge ena);                   // Espera fin del pulso alto
            t_bajada = $time;
            @(posedge ena);                   // Espera inicio del siguiente periodo
            t_siguiente = $time;

            ton_medido     = (t_bajada - t_subida) / 1000;    // Convertir ns a us
            periodo_medido = (t_siguiente - t_subida) / 1000;

            if (periodo_medido == 1000 && ton_medido == ton_esperado_us) begin
                $display("OK:    %0s: Ton = %0d us, Periodo = %0d us", nombre, ton_medido, periodo_medido);
            end else begin
                $display("ERROR: %0s: Ton = %0d us (esp %0d us), Periodo = %0d us (esp 1000 us)",
                         nombre, ton_medido, ton_esperado_us, periodo_medido);
                errores = errores + 1;
            end
        end
    endtask

    // ---- Estímulos y Verificaciones -----------------------------------------
    initial begin
        $dumpfile("tb_puente_h_pwm.vcd");
        $dumpvars(0, tb_puente_h_pwm);

        // Esperar estabilización del sincronizador (5 ciclos)
        #(5 * T_CLK);

        // --- E7: Sin pulsadores presionados -> Motor detenido ---
        if (in1 === 1'b0 && in2 === 1'b0 && ena === 1'b0)
            $display("OK:    E7 Sin pulsadores: in1=0, in2=0, ena=0 (Detenido)");
        else begin
            $display("ERROR: E7 Sin pulsadores: in1=%b, in2=%b, ena=%b", in1, in2, ena);
            errores = errores + 1;
        end

        // --- E5 y E2: Sentido Adelante + Velocidad 1 (40 % duty) ---
        fwd_n = 1'b0; v1_n = 1'b0;
        #(5 * T_CLK);
        if (in1 === 1'b1 && in2 === 1'b0)
            $display("OK:    E5 Adelante: in1=1, in2=0");
        else begin
            $display("ERROR: E5 Adelante: in1=%b, in2=%b", in1, in2);
            errores = errores + 1;
        end
        medir_pwm("E2 Duty V1 (40 %)", 400);

        // --- E3: Velocidad 2 (70 % duty) ---
        v1_n = 1'b1; v2_n = 1'b0;
        medir_pwm("E3 Duty V2 (70 %)", 700);

        // --- E6 y E4: Sentido Atrás + Velocidad 3 (100 % duty) ---
        fwd_n = 1'b1; rev_n = 1'b0; v1_n = 1'b1; v2_n = 1'b1; v3_n = 1'b0;
        #(5 * T_CLK);
        if (in1 === 1'b0 && in2 === 1'b1)
            $display("OK:    E6 Atras: in1=0, in2=1");
        else begin
            $display("ERROR: E6 Atras: in1=%b, in2=%b", in1, in2);
            errores = errores + 1;
        end

        #(1200 * T_CLK);
        if (ena === 1'b1)
            $display("OK:    E4 Duty V3 (100 %%): ena se mantiene en alto continuo");
        else begin
            $display("ERROR: E4 Duty V3 (100 %): ena no es 1 continuo");
            errores = errores + 1;
        end

        // --- E8: Ambos sentidos presionados a la vez -> Detenido ---
        fwd_n = 1'b0; rev_n = 1'b0;
        #(5 * T_CLK);
        if (in1 === 1'b0 && in2 === 1'b0 && ena === 1'b0)
            $display("OK:    E8 fwd + rev a la vez: Motor detenido de forma segura");
        else begin
            $display("ERROR: E8 fwd + rev: in1=%b, in2=%b, ena=%b", in1, in2, ena);
            errores = errores + 1;
        end

        // --- E9: Varias velocidades presionadas (V1 + V3) -> Gana la mayor (V3) ---
        fwd_n = 1'b0; rev_n = 1'b1; v1_n = 1'b0; v3_n = 1'b0;
        #(500 * T_CLK);
        if (ena === 1'b1)
            $display("OK:    E9 Prioridad V1+V3: Gana V3 (100 %%)");
        else begin
            $display("ERROR: E9 Prioridad: ena = %b", ena);
            errores = errores + 1;
        end

        // Resumen final
        $display("--------------------------------------------------");
        if (errores == 0) $display("SIMULACION CORRECTA: 0 errores");
        else              $display("SIMULACION FALLIDA con %0d errores", errores);
        $display("--------------------------------------------------");

        $finish;
    end

endmodule
