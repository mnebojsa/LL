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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.p_lin.all;

entity LIN_fsm is
    generic(
        G_DATA_LEN    : integer   := 8;
        G_RST_LEVEVEL : RST_LEVEL := HL;
        G_LIN_STANDARD: LIN_STD   := L2_0
        );
    port   (
        i_clk           : in  std_logic;                      -- Input CLOCK
        i_rst           : in  std_logic;                      -- Input Reset for clk
        i_valid_data    : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_brake         : in  std_logic;                      -- Break Detected
        i_rxd           : in  std_logic_vector(G_DATA_LEN -1 downto 0); -- Input Reciveve Data bus Line
        i_err           : in  std_logic;                      -- Output Error and Signaling
        i_serial_data   : in  std_logic;                      -- Output Error and Signaling
        o_rx_data       : out std_logic_vector(G_DATA_LEN -1 downto 0); -- Output Recieved Data
        o_valid         : out std_logic;
        o_to_mit        : out std_logic;
        o_uart_en       : out std_logic;
		  o_prescaler     : out integer range 0 to 256
        );
end LIN_fsm;

architecture Behavioral of LIN_fsm is

    -- Inputs registered
    type TYPE_IN_REG is record
        valid_data  : std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        brake       : std_logic;                      -- Input Uart Enable Signal
        uart_err    : std_logic;                      -- Input Reciveve Data bus Line
        rxd         : std_logic_vector(G_DATA_LEN -1 downto 0);  -- Input Data Recieved througth UART are stored/used
        serial_in   : std_logic;
    end record;

    -- Reset Values for TYPE_IN_REG type data
    constant TYPE_IN_REG_RST : TYPE_IN_REG := (
        valid_data  => '0',
        brake       => '0',
        uart_err    => '0',
        rxd         => (others => '0'),
        serial_in   => '1');

    type TYPE_CTRL_REG is record
        err        : std_logic;
        data       : std_logic_vector(G_DATA_LEN -1 downto 0);
        lin_valid  : std_logic;

        sync_cnt        : integer range 0 to 8;  -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        clk_cnt0        : integer range 0 to 256;               -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        clk_cnt1        : integer range 0 to 256;               -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        clk_cnt2        : integer range 0 to 256;               -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        clk_cnt_final   : integer range 0 to 256;               -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
    end record;

    constant TYPE_CTRL_REG_RST : TYPE_CTRL_REG := (
        err           => '0',
        data          => (others => '0'),
        lin_valid     => '0',

        sync_cnt      =>  0,
        clk_cnt0      =>  0,    --UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC
        clk_cnt1      =>  0,    --UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC
        clk_cnt2      =>  0,    --UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC
        clk_cnt_final =>  0);   --UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC

    signal r_ctrl, c_ctrl : TYPE_CTRL_REG;

    type TYPE_LIN_FSM is (IDLE, BREAK, SYNC, PID, DATA, CHECKSUM, LIN_ERR);

    type TYPE_FSM_REG is record
        break      : std_logic;
        err        : std_logic;
        data       : std_logic_vector(G_DATA_LEN -1 downto 0);
        lin_valid  : std_logic;
        fsm        : TYPE_LIN_FSM;
        check_sum  : std_logic_vector(7 downto 0);
        frame_type : FRAME_TIPE; -- (UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC)
        frame_len  : integer range 0 to 8;  -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
        frame_cnt  : integer range 0 to 8;  -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
    end record;

    constant TYPE_FSM_REG_RST : TYPE_FSM_REG := (
        break        => '0',
        err          => '0',
        data         => (others => '0'),
        lin_valid    => '0',
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



-- razdvoji ulazi i izlaz kao kod uarta
-- prouci lin specifikaciju
-- iskomentarisi kod
----------------------------------------------------------------------------------------------------

    -- signal - Registered inputs to the module
    signal r_in       : TYPE_IN_REG;
    -- signal - Contains input values to be registered
    signal c_in       : TYPE_IN_REG;

-------------------------------------------------------------------------------------------------

    signal r_lin, c_lin : TYPE_FSM_REG;

 -------------------------------------------------------------------------------------------------

    signal s_uart_en  : std_logic;
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
                r_in       <= TYPE_IN_REG_RST;
            else
                r_in       <= c_in;
            end if;
        end if;
    end process reg_in_proc;


comb_in_proc:
    process(r_in, i_rxd, i_brake, i_valid_data, i_err, i_serial_data)
        variable V         : TYPE_IN_REG;
    begin
        V            := r_in;

        V.brake      := i_brake;
        V.valid_data := i_valid_data;
        V.uart_err   := i_err;
        V.serial_in  := i_serial_data;

        if i_valid_data = '1' and r_in.valid_data = '0' then
            V.rxd      := i_rxd;
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
                r_ctrl       <= TYPE_CTRL_REG_RST;
            else
                r_ctrl       <= c_ctrl;
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
                r_lin <= TYPE_FSM_REG_RST;
            else
                r_lin <= c_lin;
            end if;
        end if;
    end process LIN_fsm_syn_proc;


LIN_fsm_comb_proc:
    process(r_lin, r_in, r_ctrl, i_valid_data, i_serial_data)
        variable V       : TYPE_FSM_REG;
        variable V_ctrl  : TYPE_CTRL_REG;
    begin
        V       := r_lin;

            case (r_lin.fsm) is
                when IDLE      =>
                    V  := TYPE_FSM_REG_RST;
                    if r_in.serial_in = '0' then
                        V.fsm := BREAK;
                    end if;
                    s_uart_en <= '0';
                when BREAK     =>
                    if r_in.serial_in = '1' then
                        V.fsm := SYNC;
                    end if;

                when SYNC      =>
                      if (i_serial_data = '1' and r_in.serial_in = '0') then
                          V_ctrl.sync_cnt := r_ctrl.sync_cnt +1;
                      end if;

                      if (r_ctrl.sync_cnt = 1) then
                          V_ctrl.clk_cnt0 := r_ctrl.clk_cnt0 +1;
                      end if;

                      if (r_ctrl.sync_cnt = 2) then
                          V_ctrl.clk_cnt1 := r_ctrl.clk_cnt1 +1;
                      end if;

                      if (r_ctrl.sync_cnt = 3) then
                          V_ctrl.clk_cnt2 := r_ctrl.clk_cnt2 +1;
                      end if;

                      if (r_ctrl.sync_cnt = 5 and r_in.serial_in = '1') then
                          V_ctrl.clk_cnt_final := r_ctrl.clk_cnt1;
                          s_uart_en <= '1';
                          V.fsm     := PID;
                      end if;

-------------------- implement no sync error !!!
--   vidi da se rijesi na uartu ovo
-- sync na sample malo zakasnjen i counter ukljucen
--                    if r_in.rxd = x"55" then
--                        V.fsm := PID;
--                    else
--                        V.fsm := LIN_ERR;
--                    end if;

                when PID       =>
                    if i_valid_data = '0' and r_in.valid_data = '1' then
                    if f_valid_id(r_in.rxd) = '1' then
                        V.fsm   := LIN_ERR;
                        if f_check_parity(r_in.rxd) = true then
                            V.fsm        := DATA;

                            V.frame_type := UNCONDITIONAL;

                            if    r_in.rxd(5 downto 4) = "11" then
                                V.frame_len := 8;
                                if r_in.rxd(3 downto 0) = X"C" or r_in.rxd(3 downto 0) = X"D" then
                                    V.frame_type := DIAGNOSTIC;
                                elsif r_in.rxd(3 downto 0) = X"E" or r_in.rxd(3 downto 0) = X"F" then
                                    V.frame_type := RESERVERD;
                                end if;
                            elsif r_in.rxd(5 downto 4) = "10" then
                                V.frame_len := 4;
                            else  -- r_in.rxd(5 downto 4) = "00" or r_in.rxd(5 downto 4) = "01"
                                V.frame_len := 2;
                            end if;

                            if(G_LIN_STANDARD = L2_0) then
                                V.check_sum := r_lin.check_sum xor r_in.rxd;
                            end if;
                        end if;
                    else
                        V.fsm   := LIN_ERR;
                    end if;
                    end if;

                when DATA      =>
                    if i_valid_data = '1' and r_in.valid_data = '0' then
                        V.fsm       := DATA;
                        if (r_lin.frame_cnt >= r_lin.frame_len -1) then
                            V.fsm   := CHECKSUM;
                        end if;
                        V.check_sum := r_lin.check_sum xor r_in.rxd;
                        V.frame_cnt := r_lin.frame_cnt +1;
                    end if;

                when CHECKSUM  =>
                    if i_valid_data = '1' and r_in.valid_data = '0' then
                        if (not(r_lin.check_sum) xor r_in.rxd) = "00000000" then
                            V.fsm       := IDLE;
                            V.lin_valid := '1';
                        else
                            V.fsm       := LIN_ERR;
                            V.lin_valid := '0';
                        end if;
                    end if;

                when LIN_ERR   =>
                    if i_valid_data = '1' and r_in.valid_data = '0' then
                        V.fsm := IDLE;
                    end if;
            end case;

        c_lin <= V;
		  c_ctrl <= V_ctrl;
    end process;

    o_valid     <= r_lin.lin_valid;
    o_rx_data   <= r_lin.data;
    o_uart_en   <= s_uart_en;
	 o_prescaler <= r_ctrl.clk_cnt_final;
end Behavioral;

