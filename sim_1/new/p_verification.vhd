---------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
---------------------------------------------------------------------------
-- File        : p_verification.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : April 9th, 2020
-- Modified    :
-- Changes     :
---------------------------------------------------------------------------
-- Design Unit : p_verification.vhd
-- Library     :
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Description : Full p_verification package
--
--
--
---------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use work.p_general.all;

package p_verification is

type TYPE_LIN_FRAME is array (0 to 9) of std_logic_vector(0 to 9);

constant c_break : std_logic_vector := "00000000000001";
constant c_sync  : std_logic_vector := "0101010101";

   impure function rand_slv
                         (len                : integer;
                          seed1              : positive;
                          seed2              : positive)
                                               return std_logic_vector;

   procedure p_send_data (i_vector_data      : in std_logic_vector;
                          i_cycles_num_delay : in integer;
                          i_clk_period       : in time;
                          signal o_data      : out std_logic);

   procedure p_send_lin_frame
                         (i_lin_frame        : in  TYPE_LIN_FRAME;
                          i_cycles_num_delay : in  integer;
                          i_clk_period       : in  time;
                          signal o_data      : out std_logic);
end package;

package body p_verification is

    -- takes vector of data and sends it bit by bit on o_data output
    -- with coresponding delay between the changes of the output
    procedure p_send_data(i_vector_data      : in std_logic_vector;
                          i_cycles_num_delay : in integer;
                          i_clk_period       : in time;
                          signal o_data      : out std_logic) is
        variable p_cnt     : natural;
        variable wait_time : time;
    begin
        p_cnt     := 0;
        wait_time := (i_cycles_num_delay * i_clk_period);

        for i in 0 to i_vector_data'length -1 loop
            o_data <= i_vector_data(p_cnt);
            wait for wait_time;
            p_cnt := p_cnt +1;
        end loop;
    end p_send_data;


    procedure p_send_lin_frame (
                          i_lin_frame        : TYPE_LIN_FRAME;
                          i_cycles_num_delay : in integer;
                          i_clk_period       : in time;
                          signal o_data      : out std_logic) is
        variable p_cnt     : natural;
        variable wait_time : time;
    begin
        p_cnt     := 0;
        wait_time := (i_cycles_num_delay * i_clk_period);

     -- Send Brake signal
        p_send_data(c_break, i_cycles_num_delay, i_clk_period, o_data);
     -- Send Sync signal
        p_send_data(c_sync , i_cycles_num_delay, i_clk_period, o_data);

        for i in 0 to i_lin_frame'length -1 loop
           p_send_data(i_lin_frame(p_cnt), i_cycles_num_delay, i_clk_period, o_data);
           p_cnt := p_cnt +1;
           wait for wait_time;
        end loop;
    end p_send_lin_frame;


    impure function rand_slv(
                          len                : integer;
                          seed1              : positive;
                          seed2              : positive)
                                               return std_logic_vector is
        variable r : real;
        variable slv : std_logic_vector(len - 1 downto 0);
        variable v_seed1, v_seed2 : positive;
    begin

        v_seed1 := seed1;
        v_seed2 := seed2;

        for i in slv'range loop
            uniform(v_seed1, v_seed2, r);
            if r > 0.5 then
                 slv(i) := '1';
            else
                 slv(i) := '0';
            end if;
        end loop;
        return slv;
    end function;

end package body;