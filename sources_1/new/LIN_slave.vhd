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
use work.p_general.all;
use work.p_uart.all;
use work.p_lin.all;

entity LIN_slave is
    generic
    (
        G_DATA_WIDTH   : positive      := 8;
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

    signal s_uart_valid, s_uart_brake : std_logic;

    signal s_valid                    : std_logic;
    signal s_uart_en                  : std_logic;
    signal s_uart_rx_data             : std_logic_vector(G_DATA_WIDTH -1 downto 0);
    signal s_data                     : std_logic_vector(G_DATA_WIDTH -1 downto 0);
    signal s_prescaler                : integer range 0 to 256;

    signal s_lin_fsm_in               : TYPE_LIN_FSM_IN;  -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
    signal s_lin_fsm_out              : TYPE_LIN_FSM_OUT;
    signal s_uart_in                  : TYPE_UART_IN;
begin

    s_lin_fsm_in.serial_in <= i_data;   

LIN_fsm_inst:
    LIN_fsm
        generic map(
            G_DATA_WIDTH   => G_DATA_WIDTH,
            G_RST_LEVEVEL  => HL,
            G_LIN_STANDARD => L1
        )
        port map(
            i_clk           => i_clk,               -- Input CLOCK
            i_rst           => i_rst,               -- Input Reset for clk
            i_lin_fsm       => s_lin_fsm_in,
            o_lin_fsm       => s_lin_fsm_out
        );

    s_uart_in.ena         <= s_lin_fsm_out.en_uart;
    s_uart_in.prescaler   <= '0' & s_lin_fsm_out.prescaler(31 downto 1);
    s_uart_in.rxd         <= i_data;
    s_uart_in.data_acc    <= '1';


UART_RX_inst1:
    uart_rx
        generic map(
            G_DATA_WIDTH       => 8,
            G_RST_LEVEVEL      => HL,
            G_SAMPLE_PER_BIT   => 13,
            G_LSB_MSB          => LSB,
            G_USE_BREAK        => true,
            G_USE_OVERRUN      => false,
            G_USE_FRAMEIN      => true,
            G_USE_PARITY       => NONE
            )
        port map  (
            i_clk           => i_clk,               -- Input CLOCK
            i_rst           => i_rst,               -- Input Reset for clk
            i_uart          => s_uart_in, 
            o_uart          => s_lin_fsm_in.uart
            );

    o_data    <= s_lin_fsm_out.rx_data;
    o_valid   <= s_lin_fsm_out.rx_data_valid;

end Behavioral;
