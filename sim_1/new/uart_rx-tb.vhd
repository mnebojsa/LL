-------------------------------------------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
-------------------------------------------------------------------------------------------------------------
-- File        : uart_rx_tb.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : March 11th, 2020
-- Modified    :
-- Changes     :
-------------------------------------------------------------------------------------------------------------
-- Design Unit : uart_rx_tb.vhd
-- Library     :
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- Description : Full uart_rx_tb module
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


entity uart_rx_tb is
    generic
    (
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
    generic
    (
        G_DATA_WIDTH       : positive;
        G_RST_LEVEVEL      : RST_LEVEL;
        G_SAMPLE_PER_BIT   : positive;
        G_LSB_MSB          : LSB_MSB;
        G_USE_BREAK        : boolean;
        G_USE_OVERRUN      : boolean;
        G_USE_FRAMEIN      : boolean;
        G_USE_PARITY       : U_PARITY
    );
    port
    (
        i_clk           : in  std_logic;
        i_rst           : in  std_logic;
        i_ena           : in  std_logic;
        i_prescaler     : in  std_logic_vector(31 downto 0);
        i_rxd           : in  std_logic;
        i_data_accepted : in  std_logic;
        o_break         : out std_logic;
        o_overrun_err   : out std_logic;
        o_framein_err   : out std_logic;
        o_parity_err    : out std_logic;
        o_rx_data       : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
        o_valid         : out std_logic
    );
end component;


  signal i_clk         : std_logic;
  signal i_rst         : std_logic;
  signal i_ena         : std_logic;
  signal i_rxd         : std_logic;
  signal i_prescaler   : std_logic_vector(31 downto 0);
  signal o_break       : std_logic;
  signal o_overrun_err : std_logic;
  signal o_framein_err : std_logic;
  signal o_parity_err  : std_logic;
  signal o_rx_data     : std_logic_vector(0 to G_DATA_WIDTH-1);
  signal o_valid       : std_logic ;

  -- helper signals
  signal s_data_to_send : std_logic_vector(0 to G_DATA_WIDTH +1); --start|byte_to_send|stop
  signal s_byte_to_send : std_logic_vector(0 to G_DATA_WIDTH -1);
  signal cnt            : integer := 0;
  -- constants
  constant clock_period: time := 10 ns;

begin

  -- Insert values for generic parameters !!
  uut:
  uart_rx_top
    generic map
    (
        G_DATA_WIDTH     => G_DATA_WIDTH,
        G_RST_LEVEVEL    => G_RST_LEVEVEL,
        G_SAMPLE_PER_BIT => G_SAMPLE_PER_BIT,
        G_LSB_MSB        => G_LSB_MSB,
        G_USE_BREAK      => G_USE_BREAK,
        G_USE_OVERRUN    => G_USE_OVERRUN,
        G_USE_FRAMEIN    => G_USE_FRAMEIN,
        G_USE_PARITY     => G_USE_PARITY
    )
    port map
    (
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


clk_proc:
  process
  begin
      i_clk <= '0';
          wait for clock_period/2;
      i_clk <= '1';
          wait for clock_period/2;
  end process;


  i_prescaler <= std_logic_vector(to_unsigned(125, 32));

  s_data_to_send <= '0' & s_byte_to_send & '1';

  stimulus: process
      variable v_cnt : integer := 0;
  begin

    -- Put initialisation code here

      i_rst    <= '1';
      i_ena    <= '0';
      i_rxd    <= '1';
          wait for clock_period * 50;
      i_rst    <= '0';
          wait for clock_period * 50;

      for i in 0 to 3 loop
          wait for clock_period * to_integer(unsigned(i_prescaler));
      end loop;

      i_ena    <= '1';

                       --7 .... 0
      s_byte_to_send <= "10101010";

      for i in 0 to 3 loop
          wait for clock_period * to_integer(unsigned(i_prescaler));
      end loop;

      for i in 0 to G_DATA_WIDTH + 1 loop
          i_rxd <= s_data_to_send(v_cnt);        --start
          wait for clock_period * to_integer(unsigned(i_prescaler));

          cnt <= v_cnt;

          if v_cnt <= G_DATA_WIDTH then
              v_cnt := v_cnt +1;
          else
              v_cnt := 0;
          end if;

      end loop;
          cnt <= v_cnt;
    -- data 2
                       --7 .... 0
      s_byte_to_send <= "00110011";

      for i in 0 to 3 loop
          wait for clock_period * to_integer(unsigned(i_prescaler));
      end loop;

      for i in 0 to G_DATA_WIDTH + 1 loop
          i_rxd <= s_data_to_send(v_cnt);        --start
          wait for clock_period * to_integer(unsigned(i_prescaler));

          cnt <= v_cnt;

          if v_cnt <= G_DATA_WIDTH then
              v_cnt := v_cnt +1;
          else
              v_cnt := 0;
          end if;

      end loop;
          cnt <= v_cnt;
    -- data 3
                       --7 .... 0
      s_byte_to_send <= "11001100";

      for i in 0 to G_DATA_WIDTH + 1 loop
          i_rxd <= s_data_to_send(v_cnt);        --start
          wait for clock_period * to_integer(unsigned(i_prescaler));

          cnt <= v_cnt;

          if v_cnt <= G_DATA_WIDTH then
              v_cnt := v_cnt +1;
          else
              v_cnt := 0;
          end if;

      end loop;

      for i in 0 to 3 loop
          wait for clock_period * to_integer(unsigned(i_prescaler));
      end loop;

      i_ena <= '0';

    wait;
  end process;


end;
