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
use work.p_uart_interface.all;

entity uart_rx_tb is
      generic(
        G_DATA_WIDTH       : integer   := 8;
        G_RST_LEVEVEL      : RST_LEVEL := HL;
        G_LSB_MSB          : LSB_MSB   := LSB;
        G_USE_BREAK        : boolean   := true;
        G_USE_OVERRUN      : boolean   := false;
        G_USE_FRAMEIN      : boolean   := false;
        G_USE_PARITY_ODD   : boolean   := false;
        G_USE_PARITY_EVEN  : boolean   := false
      );
end;

architecture bench of uart_rx_tb is

  component uart_rx
      generic(
        G_DATA_WIDTH       : integer   := 8;
        G_RST_LEVEVEL      : RST_LEVEL := HL;
        G_LSB_MSB          : LSB_MSB   := LSB;
        G_USE_BREAK        : boolean   := true;
        G_USE_OVERRUN      : boolean   := false;
        G_USE_FRAMEIN      : boolean   := false;
        G_USE_PARITY_ODD   : boolean   := false;
        G_USE_PARITY_EVEN  : boolean   := false
      );
      port   (
        i_clk           : in  std_logic;                      -- Input CLOCK
        i_rst           : in  std_logic;                      -- Input Reset for clk
        i_sample        : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_ena           : in  std_logic;                      -- Input Uart Enable Signal
        i_rxd           : in  std_logic;                      -- Input Reciveve Data bus Line
        o_brake         : out std_logic;                      -- Break Detected
        o_overrun_err   : out std_logic;                      -- Output Error and Signaling
        o_framein_err   : out std_logic;                      -- Output Error and Signaling
        o_parity_err    : out std_logic;                      -- Output Error and Signaling
        o_rx_data       : out std_logic_vector(G_DATA_WIDTH-1 downto 0); -- Output Recieved Data
        o_valid         : out std_logic
      );
  end component;

  signal i_clk: std_logic;
  signal i_rst: std_logic;
  signal i_sample: std_logic;
  signal i_ena: std_logic;
  signal i_rxd: std_logic := '1';
  signal o_brake: std_logic;
  signal o_uart_err: std_logic_vector(3 downto 0);
  signal o_rx_data: std_logic_vector(0 to G_DATA_WIDTH-1);
  signal o_valid: std_logic ;

  signal send_data : unsigned(0 to 9);

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

begin

  -- Insert values for generic parameters !!
  uut: uart_rx generic map ( G_DATA_WIDTH     => 8,
                             G_RST_LEVEVEL    => G_RST_LEVEVEL,
                             G_LSB_MSB        => G_LSB_MSB,
                             G_USE_BREAK      => G_USE_BREAK,
                             G_USE_OVERRUN    => G_USE_OVERRUN,
                             G_USE_FRAMEIN    => G_USE_FRAMEIN,
                             G_USE_PARITY_ODD => G_USE_PARITY_ODD,
                             G_USE_PARITY_EVEN=> G_USE_PARITY_EVEN)
                  port map ( i_clk          => i_clk,
                             i_rst          => i_rst,
                             i_sample       => i_sample,
                             i_ena          => i_ena,
                             i_rxd          => i_rxd,
                             o_brake        => o_brake,
                             o_overrun_err  => open, --o_overrun_err,
                             o_framein_err  => open, --o_overrun_err,
                             o_parity_err   => open, --o_parity_err,
                             o_rx_data      => o_rx_data,
                             o_valid        => o_valid 
									  );


  reset_proc: process
  begin
      i_rst    <= '1';
      i_ena    <= '0';
          wait for clock_period * 50;
      i_rst    <= '0';
          wait for clock_period * 50;
      i_ena    <= '1';
          wait;
  end process;


  data: process(o_valid)
      variable v_data : unsigned(0 to 7) := (others => '0');
  begin
      if rising_edge(o_valid) then
          v_data := v_data +1;
      end if;
      
      send_data <= '0' & v_data & '1';
  end process;

  stimulus: process(i_sample)
      variable cnt       : integer := 0;
      variable in_data   : unsigned(0 to 7) := (others => '0');
  begin
      if rising_edge(i_sample) then
          if (i_ena = '1') then
              i_rxd <= send_data(cnt);
              cnt := (cnt + 1) rem 10;
          end if;
      end if;  

  end process;


  sample: process
  begin
  wait for clock_period;-- * 5;
     i_sample <= '1';
  wait for clock_period;-- * 3;
     i_sample <= '0';
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      i_clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;
