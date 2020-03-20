----------------------------------------------------------------------------------
-- Company:    RT-RK
-- Engineer:   Nebojsa Markovic
-- 
-- Create Date: 17.03.2020 11:16:12
-- Design Name: 
-- Module Name: baud_rate_gen - Behavioral
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

entity baud_rate_gen is
    generic( G_RST_ACT_LEV : boolean := true;
             G_PRESCALER   : integer := 5);
    port   ( i_clk         : in  std_logic;
             i_rst         : in  std_logic;
             o_br_sample   : out std_logic);
end baud_rate_gen;

architecture Behavioral of baud_rate_gen is
    type TYPE_BRG_REG is record
        brs      : std_logic;
        cnt      : integer range 0 to 15;
    end record;

    constant TYPE_BRG_REG_RST : TYPE_BRG_REG := (
    brs          => '0',
    cnt          =>  0);

    signal r_brd, c_brd       : TYPE_BRG_REG;
    signal s_reset            : std_logic;

begin

    s_reset <= '1' when ((G_RST_ACT_LEV = true and i_rst = '1'))
                   else '0';

synchronus_process:
    process(i_clk)
    begin
        if (rising_edge(i_clk)) then
            if(s_reset = '1') then
                r_brd <= TYPE_BRG_REG_RST;
            else
                r_brd <= c_brd;
            end if;
        end if;
    end process synchronus_process;

comb_process:
    process(c_brd.brs, c_brd.cnt, r_brd.brs, r_brd.cnt)
    begin
        
        c_brd <= r_brd;

        if r_brd.cnt < G_PRESCALER/2 then      
            c_brd.brs <= '1';
        else
            c_brd.brs <= '0'; 
        end if;

        if r_brd.cnt < G_PRESCALER then      
            c_brd.cnt <= r_brd.cnt +1;
        else
            c_brd.cnt <= 0; 
        end if;
        
    end process comb_process;

    o_br_sample <= c_brd.brs;

end Behavioral;
