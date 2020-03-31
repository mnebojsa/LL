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
use work.p_uart.all;
use work.p_lin.all;

entity LIN_slave is
    generic
    (
        G_DATA_LEN     : integer      := 8;
        G_COMUNICATION : COMNCT_SPEED := DETECT_SPEED -- CONST_SPEED, DETECT_SPEED
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
end LIN_slave;

architecture Behavioral of LIN_slave is

    component baud_rate_gen is
        generic( G_RST_ACT_LEV : boolean                := true;
                 G_PRESCALER   : integer range 0 to 256 := 5);
        port   ( i_clk         : in  std_logic;
                 i_rst         : in  std_logic;
				     i_en          : in  std_logic;
		           i_prescaler   : in  integer range 0 to 256;
                 o_br_sample   : out std_logic);
    end component baud_rate_gen;

    signal s_sample                   : std_logic; 


    signal s_uart_valid, s_uart_brake : std_logic;
    signal s_overrun_err              : std_logic;
    signal s_framein_err              : std_logic;
    signal s_parity_err               : std_logic;
    signal s_uart_err                 : std_logic;
    signal s_valid                    : std_logic;
    signal s_uart_en                  : std_logic;
    signal s_uart_rx_data             : std_logic_vector(G_DATA_LEN -1 downto 0);
    signal s_data                     : std_logic_vector(G_DATA_LEN -1 downto 0);
    signal s_prescaler                : integer range 0 to 256;
begin

BRG_inst: baud_rate_gen
    generic map(
        G_RST_ACT_LEV => true)
    port map( 
        i_clk       => i_clk,
        i_rst       => i_rst,
        i_en        => s_uart_en,
		  i_prescaler => s_prescaler,
        o_br_sample => s_sample
        ); 


LIN_fsm_inst: LIN_fsm
        generic map(
            G_DATA_LEN    => 8,
            G_RST_LEVEVEL => HL,
            G_LIN_STANDARD=> L1_0
        )
        port map(
            i_clk           => i_clk,               -- Input CLOCK
            i_rst           => i_rst,               -- Input Reset for clk
            i_valid_data    => s_uart_valid,        -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
            i_brake         => s_uart_brake,        -- Break Detected
            i_rxd           => s_uart_rx_data,      -- Input Reciveve Data bus Line
            i_err           => s_uart_err,          -- Output Error and Signaling
            i_serial_data   => i_data,
            o_rx_data       => s_data,              -- Output Recieved Data
            o_valid         => s_valid, 
            o_uart_en       => s_uart_en,
            o_to_mit        => open,
				o_prescaler     => s_prescaler
        );

    s_uart_err <= s_overrun_err or s_framein_err or s_parity_err;

UART_RX_inst1: uart_rx
    generic map(
        G_DATA_WIDTH       => 8,
        G_RST_LEVEVEL      => HL,
        G_LSB_MSB          => LSB,
        G_USE_BREAK        => false,
        G_USE_OVERRUN      => false,
        G_USE_FRAMEIN      => true,
        G_USE_PARITY       => NONE
    )
    port map  (
        i_clk           => i_clk,               -- Input CLOCK
        i_rst           => i_rst,               -- Input Reset for clk
        i_sample        => s_sample,            -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_ena           => s_uart_en,               -- Input Uart Enable Signal
        i_rxd           => i_data,              -- Input Reciveve Data bus Line
        i_data_accepted => '1',
        o_brake         => s_uart_brake,        -- Break Detected
        o_overrun_err   => s_overrun_err,       -- Output Error and Signaling
        o_framein_err   => s_framein_err,       -- Output Error and Signaling
        o_parity_err    => s_parity_err,        -- Output Error and Signaling
        o_valid         => s_uart_valid,
        o_rx_data       => s_uart_rx_data       -- Output Recieved Data
    );


        o_data    <= s_data;
		  o_valid   <= s_valid;
end Behavioral;
