// =============================================================================
// puente_h_pwm.v
// -----------------------------------------------------------------------------
// Controlador de puente H con PWM de 3 velocidades y sentido de giro (nivel).
// Compatible con simulación directa e implementación en hardware FPGA.
// =============================================================================
module puente_h_pwm #(
    parameter CLK_FREQ = 25_000_000,  // Hz: Frecuencia de reloj de la FPGA
    parameter F_PWM    = 30_000        // Hz: Frecuencia elegida para la PWM
)(
    input  wire clk,
    input  wire fwd_n, rev_n,         // Sentido adelante / atrás (activos en bajo)
    input  wire v1_n, v2_n, v3_n,     // Velocidades 1(40%), 2(70%), 3(100%) (activos en bajo)
    output wire in1, in2,             // Control de dirección para el módulo L298N
    output reg  ena = 1'b0            // PWM enviada a ENA (registrada, sin glitches)
);

    // ---- 1. Cuentas y constantes localparam ----------------------------------
    localparam N     = CLK_FREQ / F_PWM;
    localparam T40   = N * 40 / 100;   // Velocidad 1: 40 %
    localparam T70   = N * 70 / 100;   // Velocidad 2: 70 %
    localparam T100  = N;              // Velocidad 3: 100 %
    localparam ANCHO = $clog2(N);

    // ---- 2. Sincronizador de entradas externas (10 Flip-Flops) --------------
    reg [4:0] meta = 5'b0, sync = 5'b0;

    always @(posedge clk) begin
        meta <= ~{fwd_n, rev_n, v1_n, v2_n, v3_n}; // Inversión: activo en bajo -> alto
        sync <= meta;
    end

    // ---- 3. Antirrebote adaptable (Simulación vs Síntesis) ------------------
    `ifdef SIMULATION
        localparam CNT_10MS_MAX = 1; // En simulación pasa inmediatamente
    `else
        localparam CNT_10MS_MAX = CLK_FREQ / 100; // 10 ms en hardware real (250,000 ciclos)
    `endif

    localparam B_10MS = $clog2(CNT_10MS_MAX > 1 ? CNT_10MS_MAX : 2);

    reg [B_10MS-1:0] cnt_10ms = {B_10MS{1'b0}};
    reg tick_10ms = 1'b0;

    always @(posedge clk) begin
        if (CNT_10MS_MAX == 1) begin
            tick_10ms <= 1'b1;
        end else begin
            if (cnt_10ms >= CNT_10MS_MAX - 1) begin
                cnt_10ms  <= {B_10MS{1'b0}};
                tick_10ms <= 1'b1;
            end else begin
                cnt_10ms  <= cnt_10ms + 1'b1;
                tick_10ms <= 1'b0;
            end
        end
    end

    // Muestra y actualiza la señal limpia tras confirmar el intervalo
    reg [4:0] btn_clean = 5'b0;

    always @(posedge clk) begin
        if (tick_10ms) begin
            btn_clean <= sync;
        end
    end

    // Extraer botones filtrados
    wire fwd = btn_clean[4];
    wire rev = btn_clean[3];
    wire v1  = btn_clean[2];
    wire v2  = btn_clean[1];
    wire v3  = btn_clean[0];

    // ---- 4. Selector combinacional de dirección ------------------------------
    assign in1 = fwd & ~rev;
    assign in2 = rev & ~fwd;

    // ---- 5. Mux de selección de ciclo de trabajo (t_on) ---------------------
    wire [ANCHO-1:0] t_on = v3 ? T100 :
                            v2 ? T70  :
                            v1 ? T40  : {ANCHO{1'b0}};

    // ---- 6. Contador del Periodo PWM -----------------------------------------
    reg [ANCHO-1:0] cnt = {ANCHO{1'b0}};
    wire fin = (cnt >= N - 1);

    always @(posedge clk) begin
        if (fin)
            cnt <= {ANCHO{1'b0}};
        else
            cnt <= cnt + 1'b1;
    end

    // ---- 7. Salida PWM registrada --------------------------------------------
    wire mover = (in1 | in2) & (v1 | v2 | v3);

    always @(posedge clk) begin
        ena <= mover & (cnt < t_on);
    end

endmodule
