----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2020 03:33:42 PM
-- Design Name: 
-- Module Name: data_sample - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.p_uart.all;

entity data_sample is
    generic(
        G_RST_LEVEVEL      : RST_LEVEL := HL;                    -- HL (High Level), LL(Low Level)
        G_SAMPLE_USED      : boolean   := false                  -- 
        );
    port   (
        i_clk              : in  std_logic;                      -- Input CLOCK
        i_rst              : in  std_logic;                      -- Input Reset for clk
        i_sample           : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_ena              : in  std_logic;                      -- Input Uart Enable Signal
        i_prescaler        : in  integer range 0 to 256;
        i_rxd              : in  std_logic;                      -- Input Reciveve Data bus Line
        o_valid            : out std_logic;
        o_rxd              : out std_logic                       -- Output Recieved Data
        );
end data_sample;

architecture Behavioral of data_sample is

component BRG
    generic(
        G_RST_LEVEVEL      : RST_LEVEL;                -- HL (High Level), LL(Low Level)
        G_SAMPLE_USED      : boolean                   -- 
        );
    port   (
        i_clk              : in  std_logic;                      -- Input CLOCK
        i_rst              : in  std_logic;                      -- Input Reset for clk
        i_sample           : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_ena              : in  std_logic;                      -- Input Uart Enable Signal
        i_prescaler        : in  integer range 0 to 256;         --

        o_sample           : out std_logic                       -- Sample signal
        );
end component BRG;

    -- Inputs registered
    type TYPE_IN_REG is record
        sample      : std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        ena         : std_logic;                      -- Input Uart Enable Signal
        rxd         : std_logic;                      -- Input Reciveve Data bus Line
        valid       : std_logic;
        sample_1s   : integer range 0 to 16;
        sample_0s   : integer range 0 to 16;
    end record;

    -- Reset Values for TYPE_IN_REG type data
    constant TYPE_IN_REG_RST : TYPE_IN_REG := (
        sample       => '0',
        ena          => '0',
        rxd          => '0',
        valid        => '0',
        sample_1s    =>  0,
        sample_0s    =>  0);

    -- signal
    signal s_sample   : std_logic;
    -- signal - takes High Level if there is active RESET on the module input
    signal s_reset    : std_logic;
    -- signal - Registered inputs to the module
    signal i_reg      : TYPE_IN_REG;
    -- signal - Contains input values to be registered
    signal c_to_i_reg : TYPE_IN_REG;


begin

    -- equals '1' if there is active reset on the rst input, otherwise equals '0'
    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';


-------------------------------------------------------------------------------------------------------
--        BRG Instance
-------------------------------------------------------------------------------------------------------
BRG_inst_0: BRG
    generic map(
        G_RST_LEVEVEL => G_RST_LEVEVEL,               -- HL (High Level), LL(Low Level)
        G_SAMPLE_USED => G_SAMPLE_USED                   -- 
        )
    port map(
        i_clk       => i_clk,                   -- Input CLOCK
        i_rst       => i_rst,                     -- Input Reset for clk
        i_sample    => i_sample,                    -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_ena       => i_ena,                  -- Input Uart Enable Signal
        i_prescaler => i_prescaler,       --

        o_sample    => s_sample                -- Sample signal
        );


-------------------------------------------------------------------------------------------------------
--        Registring Inputs
-------------------------------------------------------------------------------------------------------

-- If RST is active assign reset value to i_reg,
-- else, register c_to_i_reg value as i_reg
reg_in_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                i_reg      <= TYPE_IN_REG_RST;
            else
                i_reg      <= c_to_i_reg;
            end if;
        end if;
    end process reg_in_proc;

comb_in_proc:
--    process(i_reg, i_ena, i_rxd, i_data_accepted, s_sample)
    process(i_reg.sample, i_reg.ena, i_reg.rxd, i_reg.sample_1s, i_reg.sample_0s,
            i_ena, i_rxd, s_sample)
        variable V         : TYPE_IN_REG;
    begin
        V          := i_reg;

        V.sample   := s_sample;
        V.ena      := i_ena;
        V.valid    := '0';

        if s_sample = '1' and i_reg.sample = '0' then
            if (i_rxd = '1') then
                V.sample_1s:= i_reg.sample_1s +1;
            else
                V.sample_0s:= i_reg.sample_0s +1;
            end if;
        end if;

        if (i_reg.sample_1s + i_reg.sample_0s = 12 ) then
            if (i_reg.sample_1s >= i_reg.sample_0s) then
                V.rxd      := '1';
            else
                V.rxd      := '0';
            end if;
            V.valid    := '1';
            V.sample_1s:=  0;
            V.sample_0s:=  0;
        end if;
        -- Assign valuses that should be registered
        c_to_i_reg <= V;
    end process comb_in_proc;


-------------------------------------------------------------------------------------------------------
--        Outputs Assigment
-------------------------------------------------------------------------------------------------------
    o_valid       <= i_reg.valid;
    o_rxd         <= i_reg.rxd;                      -- Break Detected

end Behavioral;