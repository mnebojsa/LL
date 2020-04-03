library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use work.p_uart.all;


entity BRG_tb is
    generic(
        G_RST_LEVEVEL      : RST_LEVEL := HL;
        G_SAMPLE_USED      : boolean   := true
        );
end;

architecture bench of BRG_tb is

  component BRG
      generic(
          G_RST_LEVEVEL      : RST_LEVEL;
          G_SAMPLE_USED      : boolean
          );
      port   (
          i_clk              : in  std_logic;
          i_rst              : in  std_logic;
          i_sample           : in  std_logic;
          i_ena              : in  std_logic;
          i_prescaler        : in  integer range 0 to 256;
          o_sample           : out std_logic
          );
  end component;

  signal i_clk: std_logic;
  signal i_rst: std_logic;
  signal i_sample: std_logic;
  signal i_ena: std_logic;
  signal i_prescaler: integer range 0 to 256 := 250;
  signal o_sample: std_logic ;

  constant clock_period: time := 10 ns;

begin

  -- Insert values for generic parameters !!
  uut: BRG generic map ( G_RST_LEVEVEL => G_RST_LEVEVEL,
                         G_SAMPLE_USED => G_SAMPLE_USED )
              port map ( i_clk         => i_clk,
                         i_rst         => i_rst,
                         i_sample      => i_sample,
                         i_ena         => i_ena,
                         i_prescaler   => i_prescaler,
                         o_sample      => o_sample );


  st: process
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
  end process;


  process
  begin
      i_clk <= '0';
          wait for clock_period/2;
      i_clk <= '1';
          wait for clock_period/2;
  end process;

  stimulus: process
  begin
  
    -- Put initialisation code here
    for i in 0 to 20 loop
        i_sample <= '1';
            wait for 10 ns;
        i_sample <= '0';
            wait for 30 ns;
    end loop;

    -- Put test bench stimulus code here

    wait;
  end process;


end;