----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2020 14:03:26
-- Design Name: 
-- Module Name: LIN_slave_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity LIN_slave_tb is
end;

architecture bench of LIN_slave_tb is

  component LIN_slave
      generic
      (
          G_DATA_LEN : integer range 4 to 8
      );
      port 
      ( 
          i_clk     : in  std_logic;
          i_rst     : in  std_logic;
          i_data    : in  std_logic;
          o_data    : out std_logic_vector(0 to 7)
      );
  end component;

  component baud_rate_gen is
      generic( G_RST_ACT_LEV : boolean := true;
               G_PRESCALER   : integer := 5);
      port   ( i_clk         : in  std_logic;
               i_rst         : in  std_logic;
               o_br_sample   : out std_logic);
  end component;

  signal i_clk       : std_logic;
  signal i_rst       : std_logic;
  signal i_data      : std_logic := '1';
  signal o_br_sample : std_logic;
  signal o_data      : std_logic_vector(0 to 7);

  constant i_clk_period: time := 10 ns;

begin

  -- Insert values for generic parameters !!
  uut: LIN_slave generic map ( G_DATA_LEN   => 8 )
                    port map ( i_clk        => i_clk,
                               i_rst        => i_rst,
                               i_data       => i_data,
                               o_data       => o_data );

  stimulus: process
  begin
  
 -- Put initialisation code here
    i_rst  <= '1';
 -- Put test bench stimulus code here
        wait for i_clk_period * 10;
    i_rst <= '0';    
        wait for i_clk_period * 10000;
  end process;

  process
  begin
      wait for i_clk_period/2;
          i_clk <= '0';
      wait for i_clk_period/2;
          i_clk <= '1';
  end process;

 process(o_br_sample)
     variable v_data : std_logic_vector(0 to 9) ;
     variable v_cnt0   : integer range 0 to 10 := 9;
     variable brek_cnt : integer range 0 to 16 := 0;
     variable v_info_sync : unsigned (0 to 7) := "10101010";
     variable v_info_data : unsigned (0 to 7) := "00000000";
 begin
     if(rising_edge(o_br_sample)) then
 
     if brek_cnt < 14 then
         i_data <= '0';
         brek_cnt := brek_cnt +1;
     elsif (brek_cnt = 14) then
         i_data   <= '1';
         brek_cnt :=  15;
     elsif (brek_cnt = 15) then
         brek_cnt := 16;
     elsif(v_cnt0 = 9 ) then
         v_data := '1' & std_logic_vector(v_info_sync) & '0';
         v_info_data := v_info_data + 1;
         v_cnt0 := 0;
     else
         i_data <= v_data(v_cnt0);  
         v_cnt0 := v_cnt0  +1;   
  
     end if;
     
     end if;
 end process; 


  BRG: baud_rate_gen
      generic map( G_RST_ACT_LEV => true,
                   G_PRESCALER   => 5)
      port map   ( i_clk       => i_clk,      
                   i_rst       => i_rst,
                   o_br_sample => o_br_sample);


end;

