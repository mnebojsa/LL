-------------------------------------------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
-------------------------------------------------------------------------------------------------------------
-- File        : data_sample_tb.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : March 10th, 2020
-- Modified    :
-- Changes     :
-------------------------------------------------------------------------------------------------------------
-- Design Unit : data_sample_tb.vhd
-- Library     :
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- Description : Full data_sample_tb module
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

entity data_sample_tb is
    generic
     (
       G_RST_LEVEVEL      : RST_LEVEL := HL;
       G_SAMPLE_USED      : boolean   := false;
       G_SAMPLE_PER_BIT   : positive  := 13;
       G_DATA_WIDTH       : POSITIVE  := 8
    );
end;

architecture bench of data_sample_tb is

  component data_sample
      generic
        (
          G_RST_LEVEVEL      : RST_LEVEL;
          G_SAMPLE_USED      : boolean;
          G_SAMPLE_PER_BIT   : positive;
          G_DATA_WIDTH       : positive
      );
      port
        (
          i_clk           : in  std_logic;
          i_rst           : in  std_logic;
          i_ds            : in  TYPE_IN_DS;  -- Input to Sample module
          o_ds            : out TYPE_OUT_DS  -- Outpus from Sample Module
      );
  end component;

  signal i_clk       : std_logic;
  signal i_rst       : std_logic;
  signal i_ds        : TYPE_IN_DS;
  signal o_ds        : TYPE_OUT_DS;

  -- helper signals
  signal s_data_to_send : std_logic_vector(0 to G_DATA_WIDTH +1); --start|byte_to_send|stop
  signal s_byte_to_send : std_logic_vector(0 to G_DATA_WIDTH -1);
  signal cnt            : integer := 0;
  -- constants
  constant clock_period: time := 10 ns;

begin

  -- Insert values for generic parameters !!
  uut: data_sample
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
          i_ds          => i_ds,
          o_ds          => o_ds
      );


  clk_proc:
  process
  begin
      i_clk <= '0';
          wait for clock_period/2;
      i_clk <= '1';
          wait for clock_period/2;
  end process;

  i_ds.prescaler <= std_logic_vector(to_unsigned(125, 32));

                   --7 .... 0
  s_byte_to_send <= "10101010";
  s_data_to_send <= '0' & s_byte_to_send & '1';

  stimulus: process
      variable v_cnt : integer := 0;
  begin

    -- Put initialisation code here

      i_rst    <= '1';

      i_ds.sample <= '0';
      i_ds.ena    <= '0';
      i_ds.rxd    <= '1';
          wait for clock_period * 50;
      i_rst    <= '0';

      for i in 0 to 3 loop
          wait for clock_period * to_integer(unsigned(i_ds.prescaler));
      end loop;

      for i in 0 to 3 loop
          wait for clock_period * to_integer(unsigned(i_ds.prescaler));
      end loop;

      i_ds.ena    <= '1';

      for i in 0 to G_DATA_WIDTH + 1 loop
          i_ds.rxd <= s_data_to_send(v_cnt);        --start
          wait for clock_period * to_integer(unsigned(i_ds.prescaler));

          cnt <= v_cnt;

          if v_cnt <= G_DATA_WIDTH +1 then
              v_cnt := v_cnt +1;
          else
              v_cnt := 0;
          end if;

      end loop;
      i_ds.rxd <= '1';
    wait;
  end process;

end;