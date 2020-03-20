----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nebojsa Markovic
-- 
-- Create Date: 10.03.2020 13:10:48
-- Design Name: 
-- Module Name: LIN_slave - Behavioral
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

entity LIN_slave is
    generic
    (
        G_DATA_LEN : integer := 8
    );
    port 
    ( 
        i_clk     : in  std_logic;
        i_rst     : in  std_logic;
        i_data    : in  std_logic;
        o_data    : out std_logic_vector(0 to 7)
    );
end LIN_slave;

architecture Behavioral of LIN_slave is
    component uart_rx is
        generic(
            G_DATA_LEN    : integer := 8;
            G_RST_ACT_LEV : boolean := true;
            G_USE_BREAK   : boolean := true;
            G_USE_OVERRUN : boolean := false;
            G_USE_UNDERRUN: boolean := false;
            G_USE_FRAMEIN : boolean := false;
            G_USE_PARITY  : boolean := false
        );
        port   (
            i_clk           : in  std_logic;                      -- Input CLOCK
            i_rst           : in  std_logic;                      -- Input Reset for clk
            i_sample        : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
            i_ena           : in  std_logic;                      -- Input Uart Enable Signal
            i_rxd           : in  std_logic;                      -- Input Reciveve Data bus Line
            o_brake         : out std_logic;                      -- Break Detected
            o_uart_err      : out std_logic_vector(3 downto 0);   -- Output Error and Signaling
            o_rx_data       : out std_logic_vector(0 to G_DATA_LEN -1); -- Output Recieved Data
            o_valid         : out std_logic
        );
    end component uart_rx;

    component baud_rate_gen is
        generic( G_RST_ACT_LEV : boolean := true;
                 G_PRESCALER   : integer := 5);
        port   ( i_clk         : in  std_logic;
                 i_rst         : in  std_logic;
                 o_br_sample   : out std_logic);
    end component baud_rate_gen;

    component LIN_fsm is
        generic(
            G_DATA_LEN    : integer := 8;
            G_RST_ACT_LEV : boolean := true
        );
        port   (
            i_clk           : in  std_logic;                      -- Input CLOCK
            i_rst           : in  std_logic;                      -- Input Reset for clk
            i_valid_data    : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
            i_brake         : in  std_logic;                      -- Break Detected
            i_rxd           : in  std_logic_vector(0 to G_DATA_LEN -1); -- Input Reciveve Data bus Line
            i_err           : in  std_logic;                      -- Output Error and Signaling
            o_rx_data       : out std_logic_vector(0 to G_DATA_LEN -1); -- Output Recieved Data
            o_valid         : out std_logic;
            o_to_mit        : out std_logic
        );
   end component LIN_fsm;


    signal i_sample, i_ena : std_logic; 


    signal s_uart_valid, s_uart_brake : std_logic;
    signal s_uart_err                 : std_logic_vector(3 downto 0);
    signal s_uart_rx_data             : std_logic_vector(0 to G_DATA_LEN -1);
begin

BRG_inst: baud_rate_gen
    generic map(
        G_RST_ACT_LEV => true,
        G_PRESCALER   => 5)
    port map( 
        i_clk       => i_clk,
        i_rst       => i_rst,
        o_br_sample => i_sample
        ); 


LIN_fsm_inst: LIN_fsm
        generic map(
            G_DATA_LEN    => G_DATA_LEN,
            G_RST_ACT_LEV  => true
        )
        port map(
            i_clk           => i_clk,               -- Input CLOCK
            i_rst           => i_rst,               -- Input Reset for clk
            i_valid_data    => s_uart_valid,        -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
            i_brake         => s_uart_brake,        -- Break Detected
            i_rxd           => s_uart_rx_data,      -- Input Reciveve Data bus Line
            i_err           => s_uart_err(0),                       -- Output Error and Signaling
            o_rx_data       => open,  -- Output Recieved Data
            o_valid         => open, 
            o_to_mit        => open
        );


UART_RX_inst1: uart_rx
    generic map(
        G_DATA_LEN     => G_DATA_LEN,
        G_RST_ACT_LEV  => true,
        G_USE_BREAK    => true,
        G_USE_OVERRUN  => false,
        G_USE_UNDERRUN => false,
        G_USE_FRAMEIN  => false,
        G_USE_PARITY   => false
    )
    port map  (
        i_clk           => i_clk,               -- Input CLOCK
        i_rst           => i_rst,               -- Input Reset for clk
        i_sample        => i_sample,            -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_ena           => '1',               -- Input Uart Enable Signal
        i_rxd           => i_data,              -- Input Reciveve Data bus Line
        o_brake         => s_uart_brake,                -- Break Detected
        o_uart_err      => s_uart_err,                -- Output Error and Signaling
        o_rx_data       => s_uart_rx_data,                -- Output Recieved Data
        o_valid         => s_uart_valid
    );

end Behavioral;
