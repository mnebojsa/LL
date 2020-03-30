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
        o_rx_data       : out std_logic_vector(G_DATA_LEN -1 downto 0); -- Output Recieved Data
        o_valid         : out std_logic;
        o_to_mit        : out std_logic
        );
end LIN_fsm;

architecture Behavioral of LIN_fsm is

    -- Inputs registered
    type TYPE_IN_REG is record
        valid_data  : std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        brake       : std_logic;                      -- Input Uart Enable Signal
        uart_err    : std_logic;                      -- Input Reciveve Data bus Line
        rxd         : std_logic_vector(G_DATA_LEN -1 downto 0);  -- Input Data Recieved througth UART are stored/used
    end record;

    -- Reset Values for TYPE_IN_REG type data
    constant TYPE_IN_REG_RST : TYPE_IN_REG := (
        valid_data  => '0',
        brake       => '0',
        uart_err    => '0',
        rxd         => (others => '0'));

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
        frame_len    => 0,
        frame_cnt    => 0);   --UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC


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
    process(r_in, i_rxd, i_brake, i_valid_data, i_err)
        variable V         : TYPE_IN_REG;
    begin
        V          := r_in;

        V.brake      := i_brake;
        V.valid_data := i_valid_data;
        V.uart_err   := i_err;

        if i_valid_data = '1' and r_in.valid_data = '0' then
            V.rxd      := i_rxd;
        end if;
        -- Assign valuses that should be registered
        c_in       <= V;
    end process comb_in_proc;


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
    process(r_lin.break    , r_lin.err , r_lin.data   , r_lin.lin_valid, r_lin.fsm, r_lin.check_sum, r_lin.frame_type, r_lin.frame_len, r_lin.frame_cnt,
            r_in.valid_data, r_in.brake, r_in.uart_err, r_in.rxd, i_valid_data)
        variable V : TYPE_FSM_REG;
    begin
        V       := r_lin;

        if i_valid_data = '1' and r_in.valid_data = '0' then
            case (r_lin.fsm) is
                when IDLE      =>
                    V  := TYPE_FSM_REG_RST;
                    if r_in.brake = '1' then
                        V.fsm := BREAK;
                    end if;

                when BREAK     =>
                    if r_in.brake = '0' then
                        V.fsm := SYNC;
                    end if;

                when SYNC      =>
                    if r_in.rxd = x"55" then
                        V.fsm := PID;
                    else
                        V.fsm := LIN_ERR;
                    end if;

                when PID       =>
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

                when DATA      =>
                    V.fsm       := DATA;
                    if (r_lin.frame_cnt >= r_lin.frame_len -1) then
                        V.fsm   := CHECKSUM;
                    end if;
                    V.check_sum := r_lin.check_sum xor r_in.rxd;
                    V.frame_cnt := r_lin.frame_cnt +1;

                when CHECKSUM  =>
                    if (not(r_lin.check_sum) xor r_in.rxd) = "11111111" then
                        V.fsm       := IDLE;
                        V.lin_valid := '1';
                    else
                        V.fsm       := LIN_ERR;
                        V.lin_valid := '0';
                    end if;

                when LIN_ERR   =>
                    V.fsm := IDLE;
            end case;
        end if;

        c_lin <= V;
    end process;

    o_valid   <= r_lin.lin_valid;
    o_rx_data <= r_lin.data;

end Behavioral;

