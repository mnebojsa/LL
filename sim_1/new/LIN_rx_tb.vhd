-------------------------------------------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
-------------------------------------------------------------------------------------------------------------
-- File        : LIN_slave_tb.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : April 10th, 2020
-- Modified    :
-- Changes     :
-------------------------------------------------------------------------------------------------------------
-- Design Unit : LIN_slave_tb.vhd
-- Library     :
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- Description : Full LIN_slave_tb module
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
    use work.p_verification.all;

entity LIN_slave_tb is
end;

architecture bench of LIN_slave_tb is

  component LIN_slave
      generic
      (
          G_DATA_WIDTH : positive := 8
      );
      port
      (
        i_clk     : in  std_logic;
        i_rst     : in  std_logic;
        i_data    : in  std_logic;
        i_ena     : in  std_logic;
        o_data    : out std_logic_vector(7 downto 0);
        o_valid   : out std_logic
      );
  end component;

  signal i_clk       : std_logic;
  signal i_rst       : std_logic;
  signal i_data      : std_logic := '1';
  signal i_ena       : std_logic := '1';

  signal o_data      : std_logic_vector(7 downto 0);
  signal o_valid     : std_logic;
  signal s_lin_frame : TYPE_LIN_FRAME;

  constant clock_period   : time     := 10 ns;
  constant send_frames_num: positive := 5;
  constant bit_length     : positive := 250; --in clk cycles

begin

  -- Insert values for generic parameters !!
  uut: LIN_slave generic map ( G_DATA_WIDTH   => 8 )
                    port map ( i_clk        => i_clk,
                               i_rst        => i_rst,
                               i_data       => i_data,
                               i_ena        => i_ena,
                               o_data       => o_data );


  process
  begin
      wait for clock_period/2;
          i_clk <= '0';
      wait for clock_period/2;
          i_clk <= '1';
  end process;

  reset_proc: process
      variable v_lin_frame      : TYPE_LIN_FRAME;

      variable v_PID            : std_logic_vector(0 to 9);
      variable v_PID_frame_len  : integer;
      variable v_CHECKSUM       : std_logic_vector(0 to 9);

      variable v_checksum_temp  : unsigned(0 to 8);
      variable v_frame_len      : positive;
  begin
      i_rst    <= '1';
      i_ena    <= '0';
      i_data   <= '1';
          wait for clock_period * 50;
      i_rst    <= '0';
          wait for clock_period * 250;

      i_ena    <= '1';
      --               1     1         2   -   10     1      - bytes num
      -- LIN FRAME = |break|sync|PID| ... DATA ...|CHECKSUM|
      for i in 1 to send_frames_num loop
           --GENERATE_PID
           --|   0  | 1 | 2 | 3 | 4 | 5 | 6 | 7| 8| 9 | - v_PID fields   
           --|start |ID0|ID1|ID2|ID3|ID4|ID5|P0|P1|stop
           v_PID(0)      := '0';                                                  -- Start bit
           v_PID(1 to 6) :=  rand_slv(6,1,i);                                     -- Random PID value
           v_PID(7)      :=      v_PID(0 +1) xor v_PID(1+1) xor v_PID(2+1) xor v_PID(4+1); -- PID parity bit 0 calculation
           v_PID(8)      :=  not(v_PID(1 +1) xor v_PID(3+1) xor v_PID(4+1) xor v_PID(5+1));-- PID parity bit 1 calculation
           v_PID(9)      := '1';                                                  -- Stop bit

           v_PID_frame_len := to_integer(unsigned(reverse_vector(v_PID(1 to 6))));

           if(v_PID_frame_len <= 31) then
               v_frame_len := 2;
           elsif (v_PID_frame_len <= 47) then
               v_frame_len := 4;
           else
               v_frame_len := 8;
           end if;

           report " **** v_frame_len = " & integer'image(v_frame_len);

           --s_lin_frame(0) <= c_break;
           v_lin_frame(0) := v_PID;


           v_checksum_temp := (others => '0');
-----------------------
 report " **** v_checksum_temp na pocetku = " & integer'image(to_integer(v_checksum_temp));
-----------------------
           for jj in 1 to 9 loop
               if jj < 1 + v_frame_len then
                   v_lin_frame(jj)(0)      := '0';
                   v_lin_frame(jj)(1 to 8) := rand_slv(8,jj,i);
                   v_lin_frame(jj)(9)      := '1';

                   v_checksum_temp := v_checksum_temp + unsigned(v_lin_frame(jj)(0 to 8));
 
                   if(v_checksum_temp(0) = '1') then
                       v_checksum_temp(0) := '0';
                       v_checksum_temp    := v_checksum_temp + 1;
                   end if;
-----------------------
 report " **** v_checksum_temp = " & integer'image(to_integer(v_checksum_temp));
-----------------------
               elsif(jj = 1 + v_frame_len) then
                   v_CHECKSUM     := std_logic_vector('0' & not(v_checksum_temp(1 to 8)) & '1');
                   v_lin_frame(1 + v_frame_len)  := v_CHECKSUM;
               else
                   v_lin_frame(jj) := (others => '1');
               end if;
           end loop;

           -- testing purposes
           s_lin_frame <= v_lin_frame;
           -- send the frame
           p_send_lin_frame (v_lin_frame, bit_length, clock_period/2, i_data);

      end loop;

      wait;
  end process;
end;

