----------------------------------------------------------------------------
-- Company     :
-- Project     :
----------------------------------------------------------------------------
-- File        : LIN_fsm.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : March 17th, 2020
-- Modified    :
-- Changes     :
---------------------------------------------------------------------------
-- Design Unit : LIN_fsm.vhd
-- Library     :
---------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.p_general.all;
    use work.p_lin.all;
    use work.p_uart.all;

entity LIN_fsm is
    generic
    (
        G_DATA_WIDTH   : positive  := 8;
        G_RST_LEVEVEL  : RST_LEVEL := HL;
        G_LIN_STANDARD : LIN_STD   := L2
    );
    port
    (
        i_clk           : in  std_logic;        -- Input CLOCK
        i_rst           : in  std_logic;        -- Input Reset for clk
        i_lin_fsm       : in  TYPE_LIN_FSM_IN;  -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        o_lin_fsm       : out TYPE_LIN_FSM_OUT
    );
end LIN_fsm;

architecture Behavioral of LIN_fsm is

    type TYPE_LIN_FSM is (IDLE, BREAK, SYNC, PID, DATA, CHECKSUM, LIN_ERR);

    type TYPE_LIN_FSM_CTRL is record
        sync_cnt        : integer range 0 to 8;  -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        clk_cnt0        : integer range 0 to 256;               -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        clk_cnt1        : integer range 0 to 256;               -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        clk_cnt2        : integer range 0 to 256;               -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        clk_cnt_final   : integer range 0 to 256;               -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        fsm             : TYPE_LIN_FSM;
        check_sum       : unsigned(8 downto 0);
        frame_type      : FRAME_TIPE; -- (UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC)
        frame_len       : integer range 0 to 8;  -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        frame_cnt       : integer range 0 to 8;  -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
    end record;

    constant TYPE_LIN_FSM_CTRL_RST : TYPE_LIN_FSM_CTRL := (
        sync_cnt      =>  0,
        clk_cnt0      =>  0,    --UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC
        clk_cnt1      =>  0,    --UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC
        clk_cnt2      =>  0,    --UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC
        clk_cnt_final =>  0,
        fsm          => IDLE,
        check_sum    => (others => '0'),
        frame_type   => UNCONDITIONAL,
        frame_len    =>  0,
        frame_cnt    =>  0);   --UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC


-----------------------------------------------------------------------------------------------------
-- napravi strukturu u koju ce se ekstraktovati bitne informacije za upis u memoriju:
--     *timestamp
--     *ID
--     *PORUKA
--     *CHECKSUM ako treba

-- prouci lin specifikaciju
-- iskomentarisi kod
----------------------------------------------------------------------------------------------------
    -- signal - Registered inputs to the module
    signal r_in       : TYPE_LIN_FSM_IN;
    -- signal - Contains input values to be registered
    signal c_in       : TYPE_LIN_FSM_IN;

    signal r_lin_ctrl : TYPE_LIN_FSM_CTRL;
    signal c_lin_ctrl : TYPE_LIN_FSM_CTRL;


    -- signal - Registered inputs to the module
    signal r_out      : TYPE_LIN_FSM_OUT;
    -- signal - Contains input values to be registered
    signal c_out      : TYPE_LIN_FSM_OUT;
 -------------------------------------------------------------------------------------------------

    signal s_out_data : TYPE_LIN_DATA;
    -- signal - takes High Level if there is active RESET on the module input
    signal s_reset    : std_logic;

begin

    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or
                         (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';

-------------------------------------------------------------------------------------------------------
--        Registring Inputs
-------------------------------------------------------------------------------------------------------

-- If RST is active assign reset value to i_reg,
-- else, register c_to_i_reg value as i_reg
reg_in_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_in       <=TYPE_LIN_FSM_IN_RST;
            else
                r_in       <= c_in;
            end if;
        end if;
    end process reg_in_proc;


comb_in_proc:
    process(r_in.uart, r_in.uart.valid, i_lin_fsm.uart, i_lin_fsm.uart.valid, i_lin_fsm.serial_in)
        variable V   : TYPE_LIN_FSM_IN;
    begin
        V.uart            := r_in.uart;
        V.serial_in       := i_lin_fsm.serial_in;
        V.uart.valid      := i_lin_fsm.uart.valid;
        if i_lin_fsm.uart.valid = '1' and r_in.uart.valid = '0' then
            V.uart        := i_lin_fsm.uart;
        end if;
        -- Assign valuses that should be registered
        c_in       <= V;
    end process comb_in_proc;


-------------------------------------------------------------------------------------------------------
--        Control Signals reg
-------------------------------------------------------------------------------------------------------

-- If RST is active assign reset value to i_reg,
-- else, register c_to_i_reg value as i_reg
reg_ctrl_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_lin_ctrl       <= TYPE_LIN_FSM_CTRL_RST;
            else
                r_lin_ctrl       <= c_lin_ctrl;
            end if;
        end if;
    end process reg_ctrl_proc;


-------------------------------------------------------------------------------------------------------
--        Sequential Process
-------------------------------------------------------------------------------------------------------

-- If RST is active assign reset value to o_reg,
-- else, if i_sample rises to '1' register c_to_o_reg value in o_reg
LIN_fsm_syn_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_out <= TYPE_LIN_FSM_OUT_RST;
            else
                r_out <= c_out;
            end if;
        end if;
    end process LIN_fsm_syn_proc;


LIN_fsm_comb_proc:
    process(r_out, r_in, r_in.serial_in, i_lin_fsm, i_lin_fsm.serial_in, r_lin_ctrl)
      --preimenuj variablr i pazi na latchh-eve
		-- dodaj detekciju uart_break u ostalim stanjima da se FSM vrati u idle ako naidje break
		-- ba ce uci u break jer je 0 na serial in, a u sync kad dodje '1'
        variable vvvvvvvvvvvvvvvv: unsigned(8 downto 0) := (others => '0');
        variable vvv             : std_logic_vector(7 downto 0) := (others => '0');

        variable V       : TYPE_LIN_FSM_OUT;
        variable V_ctrl  : TYPE_LIN_FSM_CTRL;
    begin
        V       := r_out;
        V_ctrl  := r_lin_ctrl;
  
            case (r_lin_ctrl.fsm) is
                -- Lin waits for break signal. Here,
                -- '0' detected will be treated as break
                -- when LIN_fsm is in IDLE state.
                when IDLE      =>
                    V      := TYPE_LIN_FSM_OUT_RST;
                    V_ctrl := TYPE_LIN_FSM_CTRL_RST;
                    if r_in.serial_in = '0' then
                        V_ctrl.fsm := BREAK;
                    end if;

                -- After BREAK is detected LIN_fsm stays
                -- in this state until STOP bit is detected
                -- on the serial input
                when BREAK     =>
                    if r_in.serial_in = '1' then
                        V_ctrl.fsm := SYNC;
                    end if;

                -- After Break Sync sequence should appear
                -- It is 0x55 sequence send in LSB fasion
                -- it is used in slaves to adjust to master
                -- data speed. Here, after sync is recieved
                -- UART_rx module is enabled to catch 
                -- PID and the messages
                when SYNC      =>
                      if (i_lin_fsm.serial_in = '1' and r_in.serial_in = '0') then
                          V_ctrl.sync_cnt := r_lin_ctrl.sync_cnt +1;
                      end if;

                      if (r_lin_ctrl.sync_cnt = 1) then
                          V_ctrl.clk_cnt0 := r_lin_ctrl.clk_cnt0 +1;
                      end if;

                      if (r_lin_ctrl.sync_cnt = 2) then
                          V_ctrl.clk_cnt1 := r_lin_ctrl.clk_cnt1 +1;
                      end if;

                      if (r_lin_ctrl.sync_cnt = 3) then
                          V_ctrl.clk_cnt2 := r_lin_ctrl.clk_cnt2 +1;
                      end if;

                      if (r_lin_ctrl.sync_cnt = 5 and r_in.serial_in = '1') then
                          V_ctrl.clk_cnt_final := r_lin_ctrl.clk_cnt1;
                          V.prescaler    := std_logic_vector(to_unsigned(V_ctrl.clk_cnt_final, 32));
                          V.en_uart      := '1';
                          V_ctrl.fsm     := PID;
                      end if;

                -- Unique ID, sent by master after SYNC signal
                -- When recieved, ID validity and parity should be
                -- checked
                when PID       =>
                if i_lin_fsm.uart.valid = '0' and r_in.uart.valid = '1' then
                    V.rx_data_valid   := '0';
                    if f_valid_id(r_in.uart.rx_data) = '1' then
                        V_ctrl.fsm   := LIN_ERR;
                        V.rx_data    := r_in.uart.rx_data;
                        if f_check_parity(r_in.uart.rx_data) = true then
                            V.rx_data_valid   := '1';

                            V_ctrl.fsm        := DATA;
                            V_ctrl.frame_type := UNCONDITIONAL;

                            -- Check frame length
                            if r_in.uart.rx_data(5 downto 4) = "11" then
                                V_ctrl.frame_len := 8;
                                if r_in.uart.rx_data(3 downto 0) = X"C" or r_in.uart.rx_data(3 downto 0) = X"D" then
                                    V_ctrl.frame_type := DIAGNOSTIC;
                                elsif r_in.uart.rx_data(3 downto 0) = X"E" or r_in.uart.rx_data(3 downto 0) = X"F" then
                                    V_ctrl.frame_type := RESERVERD;
                                end if;
                            elsif r_in.uart.rx_data(5 downto 4) = "10" then
                                V_ctrl.frame_len := 4;
                            else  -- r_in.rxd(5 downto 4) = "00" or r_in.rxd(5 downto 4) = "01"
                                V_ctrl.frame_len := 2;
                            end if;

                            -- if LIN 2.x standard is used, calculate checksum
                            -- using PID and MESSAGE frames
                            if(G_LIN_STANDARD = L2) then
                                V_ctrl.check_sum(7 downto 0) := r_lin_ctrl.check_sum + unsigned(r_in.uart.rx_data);
                            end if;
                        end if;
                    else
                        V_ctrl.fsm   := LIN_ERR;
                    end if;
                end if;

                when DATA      =>
                    V.rx_data_valid  := '0';
                    if i_lin_fsm.uart.valid = '0' and r_in.uart.valid = '1' then
                        V.rx_data        := r_in.uart.rx_data;
                        V.rx_data_valid  := '1';

                        V_ctrl.fsm       := DATA;
                        if (r_lin_ctrl.frame_cnt >= r_lin_ctrl.frame_len -1) then
                            V_ctrl.fsm   := CHECKSUM;
                        end if;

                        vvvvvvvvvvvvvvvv(7 downto 0) := unsigned(reverse_vector(r_in.uart.rx_data));
                        vvvvvvvvvvvvvvvv(8) := '0';
                        V_ctrl.check_sum := r_lin_ctrl.check_sum + vvvvvvvvvvvvvvvv; --unsigned(r_in.uart.rx_data(0 to 7));
                        if(V_ctrl.check_sum(8) = '1') then
                            V_ctrl.check_sum(8) := '0';
                            V_ctrl.check_sum    := V_ctrl.check_sum +1;
                        end if;
                        V_ctrl.frame_cnt := r_lin_ctrl.frame_cnt +1;
                    end if;

                when CHECKSUM  =>
                    V.rx_data_valid  := '0';
                    if i_lin_fsm.uart.valid = '0' and r_in.uart.valid = '1' then
                        V.rx_data        := r_in.uart.rx_data;
                        V_ctrl.fsm       := LIN_ERR;
                        
                        vvvvvvvvvvvvvvvv(7 downto 0) := unsigned(reverse_vector(r_in.uart.rx_data));
                                                                                                   --r_in.uart.rx_data;
                        if (std_logic_vector(r_lin_ctrl.check_sum(7 downto 0)) xor std_logic_vector(vvvvvvvvvvvvvvvv(7 downto 0))) = x"FF" then
                            V_ctrl.fsm       := IDLE;
                            V.rx_data_valid  := '1';
                        end if;
                    end if;

                when LIN_ERR   =>
                    if r_in.serial_in = '1' then
                        V_ctrl.fsm := IDLE;
                    end if;
            end case;

          c_out      <= V;
		  c_lin_ctrl <= V_ctrl;
    end process;

    o_lin_fsm <= r_out;
end Behavioral;

