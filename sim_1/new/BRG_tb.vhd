-------------------------------------------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
-------------------------------------------------------------------------------------------------------------
-- File        : BRG_tb.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : March 10th, 2020
-- Modified    :
-- Changes     :
-------------------------------------------------------------------------------------------------------------
-- Design Unit : BRG_tb.vhd
-- Library     :
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- Description : Full BRG_tb module
--
--
--
--------------------------------------------------------------------------------------------------------------
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--------------------------------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.p_general.all;
    use work.p_uart.all;


entity BRG_tb is
    generic
    (
        G_RST_LEVEVEL      : RST_LEVEL := HL;
        G_SAMPLE_USED      : boolean   := false;
        G_SAMPLE_PER_BIT   : positive  := 13;
        G_DATA_WIDTH       : positive  := 8
    );
end;

architecture bench of BRG_tb is

  component BRG
      generic
      (
          G_RST_LEVEVEL    : RST_LEVEL := HL;
          G_SAMPLE_USED    : boolean   := false;
          G_SAMPLE_PER_BIT : positive  := 13;
          G_DATA_WIDTH     : positive  := 8
      );
      port
      (
           --! Input CLOCK
           i_clk              : in  std_logic;
           --! Reset for input clk domain
           i_rst              : in  std_logic;
           --! Input
           i_brg              : in  TYPE_BRG_IN;
           --! Sample trigger signal
           o_brg              : out TYPE_BRG_OUT
      );
  end component;

  signal i_clk       : std_logic;
  signal i_rst       : std_logic;
           --! Input
  signal i_brg       : TYPE_BRG_IN;
           --! Sample trigger signal
  signal o_brg       : TYPE_BRG_OUT;

  constant clock_period: time := 10 ns;

begin

  -- Insert values for generic parameters !!
uut:
  BRG
  generic map
  (
      G_RST_LEVEVEL    => G_RST_LEVEVEL,
      G_SAMPLE_USED    => G_SAMPLE_USED,
      G_SAMPLE_PER_BIT => G_SAMPLE_PER_BIT,
      G_DATA_WIDTH     => G_DATA_WIDTH
  )
  port map
  (
      i_clk         => i_clk,
      i_rst         => i_rst,
      i_brg         => i_brg,
      o_brg         => o_brg
  );


rest_enable_proc:
  process
  begin

 -- Put initialisation code here
    i_rst      <= '1';
    i_brg.ena  <= '0';
 -- Put test bench stimulus code here
        wait for clock_period * 10;
    i_rst     <= '0';
        wait for clock_period * 10;
    i_brg.ena <= '1';
        wait for clock_period * 10000;
  end process rest_enable_proc;

clk_process:
  process
  begin
      i_clk <= '0';
          wait for clock_period/2;
      i_clk <= '1';
          wait for clock_period/2;
  end process clk_process;

  i_brg.prescaler <= std_logic_vector(to_unsigned(125, 32));

stimulus:
  process
  begin
    -- if G_SAMPLE_USED = true generate i_sample input
    -- output is the same shape signal
    if G_SAMPLE_USED = true then
        -- Put initialisation code here
        for i in 0 to 20 loop
            i_brg.sample <= '1';
                wait for 10 ns;
            i_brg.sample <= '0';
                wait for 30 ns;
        end loop;
    end if;
    i_brg.sample <= '0';

    wait;
  end process stimulus;


end;