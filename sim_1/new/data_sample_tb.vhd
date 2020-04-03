library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

use work.p_uart.all;

entity data_sample_tb is
    generic(
       G_RST_LEVEVEL      : RST_LEVEL := HL;
       G_SAMPLE_USED      : boolean   := false
       );
end;

architecture bench of data_sample_tb is

  component data_sample
      generic(
          G_RST_LEVEVEL      : RST_LEVEL;
          G_SAMPLE_USED      : boolean
          );
      port   (
          i_clk           : in  std_logic;
          i_rst           : in  std_logic;
          i_sample        : in  std_logic;
          i_ena           : in  std_logic;
          i_prescaler     : in  integer range 0 to 256;
          i_rxd           : in  std_logic;
          o_valid         : out std_logic;
          o_rxd           : out std_logic
          );
  end component;

  signal i_clk: std_logic;
  signal i_rst: std_logic;
  signal i_sample: std_logic;
  signal i_ena: std_logic;
  signal i_prescaler: integer range 0 to 256 := 250;
  signal i_rxd: std_logic;
  signal o_rxd: std_logic ;
  signal o_valid : std_logic ;


  constant clock_period: time := 10 ns;
begin

  -- Insert values for generic parameters !!
  uut: data_sample generic map ( G_RST_LEVEVEL => G_RST_LEVEVEL,
                                 G_SAMPLE_USED => G_SAMPLE_USED )
                      port map ( i_clk         => i_clk,
                                 i_rst         => i_rst,
                                 i_sample      => i_sample,
                                 i_ena         => i_ena,
                                 i_prescaler   => i_prescaler,
                                 i_rxd         => i_rxd,
                                 o_rxd         => o_rxd );

  stimulus: process
  begin
  
    -- Put initialisation code here

      i_rst    <= '1';
      i_ena    <= '0';
      i_rxd    <= '1';
          wait for clock_period * 50;
      i_rst    <= '0';
          wait for clock_period * 50;

    for i in 0 to 3 loop
      wait for clock_period * 120;
      wait for clock_period *3;
      wait for clock_period *2;
    end loop;

      i_ena    <= '1';


    for i in 0 to 3 loop
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;
    end loop;

----------------------------------------------------------------------
          i_rxd <= '0';        --start
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;
      
  
          i_rxd    <= '1';      -- 0
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;  
 
 
           i_rxd <= '0';       --1
  wait for clock_period * 120;
       
  wait for clock_period *3;
       
  wait for clock_period *2;
  

      i_rxd    <= '1';             --2
  wait for clock_period * 120;
       
  wait for clock_period *3;
       
  wait for clock_period *2;  
  
  
            i_rxd <= '0';        --3
wait for clock_period * 120;
   
wait for clock_period *3;
   
wait for clock_period *2;


  i_rxd    <= '1';                --4
wait for clock_period * 120;
   
wait for clock_period *3;
   
wait for clock_period *2;  


          i_rxd <= '0';             --5
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;
      
  
          i_rxd    <= '1';          --6
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;  


          i_rxd <= '0';              --7
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;
      
  
          i_rxd    <= '1';           --add
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;  


          i_rxd    <= '0';           --add
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;
      
          i_rxd    <= '1';           --add
     wait for clock_period * 120;
           
     wait for clock_period *3;
           
     wait for clock_period *2;

    -- Put test bench stimulus code here

    wait;
  end process;

process
begin
i_clk <= '0';
 wait for clock_period/2;
i_clk <= '1';
  wait for clock_period/2;
end process;
end;