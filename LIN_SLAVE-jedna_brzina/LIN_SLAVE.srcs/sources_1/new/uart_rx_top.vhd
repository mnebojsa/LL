----------------------------------------------------------------------------------
-- Company:  RT-RK
-- Engineer: Nebojsa Markovic
-- 
-- Create Date: 10.03.2020 13:46:37
-- Design Name: 
-- Module Name: uart_rx - Behavioral
-- Project Name: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
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
use work.p_uart_interface.all;

entity uart_rx_top is
    generic(
        G_DATA_LEN    : integer := 8;
        G_USE_BREAK   : boolean := true;
        G_USE_OVERRUN : boolean := false;
        G_USE_FRAMEIN : boolean := false;
        G_USE_PARITY  : boolean := false
    );
    port   (
        i_clk           : in std_logic;             -- Input CLOCK
        i_rst	        : in std_logic;             -- Input Reset for clk
        i_ena           : in std_logic;             -- Input Uart Enable Signal
        i_rxd           : in std_logic;             -- Input Reciveve Data bus Line
        o_uart_event    : out TYPE_UART_RX_EVENT;   -- Output Error and Signaling
        o_rx_data       : out std_logic_vector(G_DATA_LEN-1 downto 0) -- Output Recieved Data
    );
end uart_rx_top;

architecture Behavioral of uart_rx_top is

begin

UART_RX_i: uart_rx
    generic map(
        G_DATA_LEN    => G_DATA_LEN,
        G_USE_BREAK   => G_USE_BREAK,
        G_USE_OVERRUN => G_USE_OVERRUN,
        G_USE_FRAMEIN => G_USE_FRAMEIN,
        G_USE_PARITY  => G_USE_PARITY
    )
    port map(
        i_clk  => i_clk,                -- Input CLOCK
        i_rst  => i_rst,                -- Input Reset for clk
        i_ena  => i_ena,                -- Input Uart Enable Signal
        i_rxd  => i_rxd,                -- Input Reciveve Data bus Line
        o_uart_event => o_uart_event,   -- Output Error and Signaling
        o_rx_data    => o_rx_data       -- Output Recieved Data
    );
end uart_rx_top;

end Behavioral;
