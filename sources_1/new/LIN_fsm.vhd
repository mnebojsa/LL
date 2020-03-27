----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2020 17:24:40
-- Design Name: 
-- Module Name: LIN_fsm - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


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

    type TYPE_LIN_FSM is (IDLE, BREAK, SYNC, PID, DATA, CHECKSUM, LIN_ERR);

    type TYPE_FSM_REG is record
        break      : std_logic;
        err        : std_logic_vector(3 downto 0);
        data       : std_logic_vector(0 to G_DATA_LEN -1);
        valid      : std_logic;
        fsm        : TYPE_LIN_FSM;
        cnt        : integer range 0 to 15;
        check_sum  : std_logic_vector(7 downto 0);
        frame_type : FRAME_TIPE; -- (UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC)
        frame_len  : integer range 2 to 8;  -- napravi ovo kao std_logic_vec!!! ili unsigned, a?
    end record;

    constant TYPE_FSM_REG_RST : TYPE_FSM_REG := (
        break        => '0',
        err          => (others => '0'),
        data         => (others => '0'),
        valid        => '0',
        fsm          => IDLE,
        cnt          => 0,
        check_sum    => (others => '0'),
        frame_type   => UNCONDITIONAL,
        frame_len    => 0);   --UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC


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


    signal s_reset              : std_logic;

    -- signal - registered sample signal(trigers FSM)
    signal r_sample   : std_logic;
    -- signal - input i_sample value that will be registered on the rising edge of the clk
    signal c_sample   : std_logic;

    signal r_lin_fsm, c_lin_fsm : TYPE_FSM_REG;

begin

    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';


-------------------------------------------------------------------------------------------------------
--        Sequential Process
-------------------------------------------------------------------------------------------------------
reg_sample_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_sample   <= '0';
            else
                r_sample   <= c_sample;
            end if;
        end if;
    end process reg_sample_proc;

-- If RST is active assign reset value to o_reg,
-- else, if i_sample rises to '1' register c_to_o_reg value in o_reg
LIN_fsm_syn_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_lin_fsm <= TYPE_FSM_REG_RST;
            else
                r_lin_fsm <= c_lin_fsm;
            end if;
        end if;
    end process LIN_fsm_syn_proc;


LIN_fsm_comb_proc:
    process(r_lin_fsm.break , r_lin_fsm.err , r_lin_fsm.data , r_lin_fsm.valid , r_lin_fsm.fsm , r_lin_fsm.cnt,
            i_brake, i_valid_data, i_rxd)
        variable V : TYPE_FSM_REG;
    begin
        V       := r_lin_fsm;
        V.valid := i_valid_data;
        case (r_lin_fsm.fsm) is
            when IDLE      =>
                if i_brake = '1' then
                    V.fsm := BREAK;
                end if;
            when BREAK     =>
                if i_brake = '0' then
                    V.fsm := SYNC;
                end if;
            when SYNC      =>
                if i_valid_data = '1' and r_lin_fsm.valid = '0' then
                    if i_rxd = x"55" then
                        V.fsm := PID;
                    else
                        V.fsm := LIN_ERR;
                    end if;
                end if;
            when PID       =>
                if i_valid_data = '1' and r_lin_fsm.valid = '0' then
                    if f_valid_id(i_rxd) = '1' then
                        if f_check_parity(i_rxd) = true then
                            V.fsm       := DATA;
                            
                            if i_rxd(5 downto 4) = "01" then
                                V.frame_len := 2;
                            elsif i_rxd(5 downto 4)= "10" then
                                V.frame_len := 4;
                            else
                                V.frame_len := 8;
                            end if;

                            if(G_LIN_STANDARD = L2_0) then
                                V.check_sum := r_lin_fsm.check_sum xor i_rxd; 
                            end if;
                        else
                            V.fsm := LIN_ERR;
                        end if;
                    else
                        V.fsm := LIN_ERR;
                    end if;
                end if;

            when DATA      =>
                if i_valid_data = '1' and r_lin_fsm.valid = '0' then
                      V.check_sum := r_lin_fsm.check_sum xor i_rxd;
                    -- if f_valid_id(i_rxd) = '1' then
                        -- c_lin_fsm.fsm <= DATA;
                    -- else
                      --   c_lin_fsm.fsm <= IDLE;
                    -- end if;
                end if;
            when CHECKSUM  =>
                if i_valid_data = '1' and r_lin_fsm.valid = '0' then
                   -- if f_valid_id(i_rxd) = '1' then
                       -- c_lin_fsm.fsm <= DATA;
                   -- else
                     --   c_lin_fsm.fsm <= IDLE;
                   -- end if;
                end if; 
            when LIN_ERR   =>                       
        end case; 
        
        c_lin_fsm <= V;  
    end process;

    o_rx_data <= r_lin_fsm.data;

end Behavioral;

