----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2020 16:50:40
-- Design Name: 
-- Module Name: uart_rx-tb - Behavioral
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
use work.p_uart.all;
use work.p_general.all;

entity uart_rx_tb is
      generic(
        G_DATA_WIDTH       : positive  := 8;
        G_RST_LEVEVEL      : RST_LEVEL := HL;
	     G_SAMPLE_PER_BIT   : positive  := 13;
        G_LSB_MSB          : LSB_MSB   := LSB;
        G_USE_BREAK        : boolean   := false;
        G_USE_OVERRUN      : boolean   := false;
        G_USE_FRAMEIN      : boolean   := true;
        G_USE_PARITY       : U_PARITY  := NONE
      );
end;

architecture bench of uart_rx_tb is

component uart_rx_top
    generic(
        --! Data Width,
        --! Data Type: positive, Default value: 8
        G_DATA_WIDTH       : positive  := 8;
        --! Module Reset Level,
        --! Data type: RST_LEVEL(type deined in p_general package), Default value: HL
        G_RST_LEVEVEL      : RST_LEVEL := HL;
        --! Number of samples per one bit,
        --! Data Type: positive, Default value 13
        --! Sampling starts after START bit is detected on the module's input
        G_SAMPLE_PER_BIT   : positive  := 13;
        --! Data format Expected
        --! DAta type: LSB_MSB(type deined in p_general package), Default value: LSB
        --! LSB frame = START|LSB|  ...  |MSB|STOP - first recived data is LSB bit
        --! MSB frame=  START|MSB|  ...  |LSB|STOP - first recived data is MSB bit
        G_LSB_MSB          : LSB_MSB   := LSB;
        --! Use Brake signal detection,
        --! Data Type: boolean, Default value: false
        G_USE_BREAK        : boolean   := true;
        --! Use Overrun Error detection,
        --! Data Type: boolean, Default value: false
        G_USE_OVERRUN      : boolean   := true;
        --! Use Frameing Error detection,
        --! Data Type: boolean, Default value: false
        G_USE_FRAMEIN      : boolean   := true;
        --! Use Frameing Error detection,
        --! Data Type: U_PARITY(type deined in p_general package), Default value: NONE
        --! NONE(Parity not used), ODD(odd parity), EVEN(Even parity)
        G_USE_PARITY       : U_PARITY  := ODD
        );
    port   (
        --! Input CLOCK
        i_clk           : in  std_logic;
        --! Reset for input clk domain
        i_rst           : in  std_logic;
        --! Uart Enable Signal
        i_ena           : in  std_logic;
        --! Duration of one bit (expresed in number of clk cycles per bit)
        i_prescaler     : in  unsigned(31 downto 0);
        --! Reciveve Data bus Line
        i_rxd           : in  std_logic;
        --! Data Recieved througth UART are stored/used
        --! If o_valid is high level and previous data are not accepted, overrun error  bit will be set
        --! if overrun is used. If not using overrun, output data would just be rewritten
        i_data_accepted : in  std_logic;
        --! Break Detected
        o_break         : out std_logic;
        --! Overrun Err Detected (high when old data is not read, but new data is redy on the output)
        o_overrun_err   : out std_logic;
        --! Frameing Err Detected (when STOP bit is expected, but input data is  not equal to '1')
        o_framein_err   : out std_logic;
        --! Parity Err Detected
        o_parity_err    : out std_logic;
        --! Recieved Data (DW = Data Width)
        o_rx_data       : out std_logic_vector(G_DATA_WIDTH-1 downto 0); -- Output Recieved Data
        --! Valid Data on the module output
        o_valid         : out std_logic
        );
end component;


  signal i_clk         : std_logic;
  signal i_rst         : std_logic;
  signal i_ena         : std_logic;
  signal i_rxd         : std_logic;
  signal i_prescaler   : unsigned(31 downto 0);
  signal o_break       : std_logic;
  signal o_overrun_err : std_logic;
  signal o_framein_err : std_logic;
  signal o_parity_err  : std_logic;
  signal o_rx_data     : std_logic_vector(0 to G_DATA_WIDTH-1);
  signal o_valid       : std_logic ;

  signal send_data     : unsigned(0 to 9);
  signal s_break_done  : std_logic := '0';
  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

begin

  -- Insert values for generic parameters !!
  uut: uart_rx_top 
      generic map(
		    G_DATA_WIDTH     => G_DATA_WIDTH,
		    G_RST_LEVEVEL    => G_RST_LEVEVEL,
			 G_SAMPLE_PER_BIT => G_SAMPLE_PER_BIT,
		    G_LSB_MSB        => G_LSB_MSB,
		    G_USE_BREAK      => G_USE_BREAK,
		    G_USE_OVERRUN    => G_USE_OVERRUN,
		    G_USE_FRAMEIN    => G_USE_FRAMEIN,
		    G_USE_PARITY     => G_USE_PARITY)
      port map (
		    i_clk          => i_clk,
		    i_rst          => i_rst,
		    i_ena          => i_ena,
		    i_rxd          => i_rxd,
			 i_prescaler    => i_prescaler,
		    i_data_accepted=> '1',
		    o_break        => o_break,
		    o_overrun_err  => o_overrun_err, --o_overrun_err,
		    o_framein_err  => o_framein_err, --o_overrun_err,
		    o_parity_err   => o_parity_err,  --o_parity_err,
		    o_rx_data      => o_rx_data,
		    o_valid        => o_valid 
		    );


--  reset_proc: process
--  begin
--      i_rst    <= '1';
--      i_ena    <= '0';
--          wait for clock_period * 50;
--      i_rst    <= '0';
--          wait for clock_period * 50;
--      i_ena    <= '1';
--          wait;
--  end process;

--  data: process(o_valid)
--      variable v_data : unsigned(0 to 7) := (others => '0');
--  begin
--      if rising_edge(o_valid) then
--          v_data := v_data +1;
--      end if;
--      send_data <= '0' & v_data & '1';
--  end process;

--  break: process(i_sample)
--      variable v_data : unsigned(0 to 13) := (others => '0');
--      variable cnt       : integer := 0;
--      variable send_data : unsigned(0 to 15) := (others => '0');
--  begin
--      v_data    := (others => '0');
--      send_data := '0' & v_data & '1';
--      if rising_edge(i_sample) then
--          if (i_ena = '1' and s_break_done <='0') then
--              cnt   := (cnt + 1);
--		        if( cnt >= 16) then
--			         s_break_done <='1';
--			     else
--				      s_break_done <='0';
--				      i_rxd <= send_data(cnt);
--				  end if;
--	       else
--              cnt := 0;				  
--          end if;
			 
--			 if i_ena = '0' then
--			     i_rxd <= '1';
--			 end if;
--		end if;
--  end process;

--  stimulus: process(i_sample)
--      variable cnt1       : integer := 0;
--      variable in_data   : unsigned(0 to 7) := (others => '0');
--  begin
--      if rising_edge(i_sample) then
--          if (i_ena = '1' and s_break_done = '1') then
--              --i_rxd <= send_data(cnt1);
--              cnt1 := (cnt1 + 1) rem 10;
--          end if;
--      end if;  

--  end process;


--  sample: process
--  begin
--  wait for clock_period * 5;
--     i_sample <= '1';
--  wait for clock_period * 3;
--     i_sample <= '0';
--  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      i_clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;


  reset_proc: process
  begin
      i_prescaler <= "00000000000000000000000001111101"; --125
      i_rst    <= '1';
      i_ena    <= '0';
          wait for clock_period * 50;
      i_ena    <= '1';
      i_rxd    <= '1';
          wait for clock_period * 50;
      i_rst    <= '0';
          wait for clock_period * 50;


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


          i_rxd    <= '1';           --add
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;
      
          i_rxd    <= '1';           --add
     wait for clock_period * 120;
           
     wait for clock_period *3;
           
     wait for clock_period *2;

    -- Put test bench stimulus code here
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
 
 
           i_rxd <= '0';       --0
  wait for clock_period * 120;
       
  wait for clock_period *3;
       
  wait for clock_period *2;
  

      i_rxd    <= '1';             --1
  wait for clock_period * 120;
       
  wait for clock_period *3;
       
  wait for clock_period *2;  
  
  
            i_rxd <= '0';        --2
wait for clock_period * 120;
   
wait for clock_period *3;
   
wait for clock_period *2;


  i_rxd    <= '1';                --3
wait for clock_period * 120;
   
wait for clock_period *3;
   
wait for clock_period *2;  


          i_rxd <= '0';             --4
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;
      
  
          i_rxd    <= '1';          --5
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;  


          i_rxd <= '0';              --6
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;
      
  
          i_rxd    <= '1';           --7  
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;  


          i_rxd    <= '1';           --stop
      wait for clock_period * 120;
           
      wait for clock_period *3;
           
      wait for clock_period *2;
      
-----------------------------------------------------
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
 
          wait;
  end process;

end;
