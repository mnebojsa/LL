----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 04/02/2020 03:43:35 PM
-- Design Name:
-- Module Name: BRG - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.p_uart.all;

entity BRG is
    generic(
        G_RST_LEVEVEL      : RST_LEVEL := HL;                -- HL (High Level), LL(Low Level)
        G_SAMPLE_USED      : boolean   := false;             --
        G_SAMPLE_PER_BIT   : positive  := 13
        );
    port   (
        i_clk              : in  std_logic;                      -- Input CLOCK
        i_rst              : in  std_logic;                      -- Input Reset for clk
        i_sample           : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_ena              : in  std_logic;                      -- Input Uart Enable Signal
        i_prescaler        : in  integer range 0 to 256;         --

        o_sample           : out std_logic                       -- Sample signal
        );
end BRG;

architecture Behavioral of BRG is
    type TYPE_BRG_REG is record
        brs        : std_logic;
        cnt        : integer range 0 to 15;
        sample_cnt : integer range 0 to 256;
    end record;

    constant TYPE_BRG_REG_RST : TYPE_BRG_REG := (
        brs        => '0',
        cnt        =>  0,
        sample_cnt =>  0);

-- signal - takes High Level if there is active RESET on the module input
signal s_reset    : std_logic;
-- signal - Registered inputs to the module
signal r_brd      : TYPE_BRG_REG;
-- signal - Contains input values to be registered
signal c_brd      : TYPE_BRG_REG;

begin

-------------------------------------------------------------------------------------------------------
--                             BRG
-------------------------------------------------------------------------------------------------------

    -- equals '1' if there is active reset on the rst input, otherwise equals '0'
    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';

    synchronus_BRG_process:
    process(i_clk)
    begin
        if (rising_edge(i_clk)) then
            if(s_reset = '1') then
                r_brd <= TYPE_BRG_REG_RST;
            else
                r_brd <= c_brd;
            end if;
        end if;
    end process synchronus_BRG_process;


smpl_gen_not_used:
if G_SAMPLE_USED = true generate
    comb_process:
    process(r_brd.brs, r_brd.cnt, r_brd.sample_cnt, i_sample, i_ena)
        variable V : TYPE_BRG_REG;
    begin
        V     := r_brd;

        if i_ena = '1' then
            V.brs := i_sample;
        end if;

        c_brd <= V;
    end process comb_process;
end generate smpl_gen_not_used;

smpl_gen_used:
if G_SAMPLE_USED = false generate
    comb_process:
        process(r_brd.brs, r_brd.cnt, r_brd.sample_cnt, i_prescaler, i_ena)
            variable V : TYPE_BRG_REG;
        begin

            V := r_brd;

            V.sample_cnt := (i_prescaler/2) / G_SAMPLE_PER_BIT;
            if ((i_prescaler/2) / G_SAMPLE_PER_BIT) = 0 then
                V.sample_cnt := i_prescaler/4;
            end if;

            if i_ena = '1' then
                if r_brd.sample_cnt /= 0 then
                    if (r_brd.cnt = r_brd.sample_cnt) then
                        V.brs := '1';
                        V.cnt :=  0;
                    else
                        V.brs := '0';
                        V.cnt := r_brd.cnt +1;
                    end if;
                end if;
            end if;

        c_brd <= V;
    end process comb_process;
end generate smpl_gen_used;

-------------------------------------------------------------------------------------------------------
--                             OUPUTS
-------------------------------------------------------------------------------------------------------
    o_sample <= r_brd.brs;

end Behavioral;
