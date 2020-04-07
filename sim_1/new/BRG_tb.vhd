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
----------------------------------------------------------------------------------------------------------------
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
----------------------------------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.p_general.all;


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
           -- Input Sample signal
           i_sample           : in  std_logic;
           --! BRG Enable Signal
           --! Starts to give sample bits after enabled
           i_ena              : in  std_logic;
           --! Duration of one bit (expresed in number of clk cycles per bit)
           i_prescaler        : in  std_logic_vector(31 downto 0);
           --! Sample trigger signal
           o_sample           : out std_logic
      );
  end component;

  signal i_clk       : std_logic;
  signal i_rst       : std_logic;
  signal i_sample    : std_logic;
  signal i_ena       : std_logic;
  signal i_prescaler : std_logic_vector(31 downto 0) := "00000000000000000000000001111101"; --125
  signal o_sample    : std_logic;

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
      i_sample      => i_sample,
      i_ena         => i_ena,
      i_prescaler   => i_prescaler,
      o_sample      => o_sample
  );


rest_enable_proc:
  process
  begin

 -- Put initialisation code here
    i_rst  <= '1';
    i_ena  <= '0';
 -- Put test bench stimulus code here
        wait for clock_period * 10;
    i_rst <= '0';
        wait for clock_period * 10;
    i_ena <= '1';
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

stimulus:
  process
  begin
    -- if G_SAMPLE_USED = true generate i_sample input
    -- output is the same shape signal
    if G_SAMPLE_USED = true then
        -- Put initialisation code here
        for i in 0 to 20 loop
            i_sample <= '1';
                wait for 10 ns;
            i_sample <= '0';
                wait for 30 ns;
        end loop;
    end if;
    i_sample <= '0';

    wait;
  end process stimulus;


end;