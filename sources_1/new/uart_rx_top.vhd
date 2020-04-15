-------------------------------------------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
-------------------------------------------------------------------------------------------------------------
-- File        : uart_rx.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : March 10th, 2020
-- Modified    :
-- Changes     :
-------------------------------------------------------------------------------------------------------------
-- Design Unit : uart_rx.vhd
-- Library     :
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- Description : Full UART_RX module
--
--
--
----------------------------------------------------------------------------------------------------------------
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
----------------------------------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.p_general.all;
    use work.p_uart.all;

entity uart_rx_top is
    generic(
        --! Data Width,
        --! Data Type: positive, Default value: 8
        G_DATA_WIDTH       : positive  := 8;
        --! Module Reset Level,
        --! Data type: RST_LEVEL(type deined in p_general package), Default value: HL
        G_RST_LEVEVEL      : RST_LEVEL := HL;
        --! Number of samples per one bit,
        --! Data Type: positive, Default value 13
        --! Sampling starts after START bit is detected on the module's input
        G_SAMPLE_PER_BIT   : positive  := 13;
        --! Data format Expected
        --! DAta type: LSB_MSB(type deined in p_general package), Default value: LSB
        --! LSB frame = START|LSB|  ...  |MSB|STOP - first recived data is LSB bit
        --! MSB frame=  START|MSB|  ...  |LSB|STOP - first recived data is MSB bit
        G_LSB_MSB          : LSB_MSB   := LSB;
        --! Use Brake signal detection,
        --! Data Type: boolean, Default value: false
        G_USE_BREAK        : boolean   := false;
        --! Use Overrun Error detection,
        --! Data Type: boolean, Default value: false
        G_USE_OVERRUN      : boolean   := false;
        --! Use Frameing Error detection,
        --! Data Type: boolean, Default value: false
        G_USE_FRAMEIN      : boolean   := false;
        --! Use Frameing Error detection,
        --! Data Type: U_PARITY(type deined in p_general package), Default value: NONE
        --! NONE(Parity not used), ODD(odd parity), EVEN(Even parity)
        G_USE_PARITY       : U_PARITY  := NONE
        );
    port   (
        --! Input CLOCK
        i_clk           : in  std_logic;
        --! Reset for input clk domain
        i_rst           : in  std_logic;
        --! Uart Enable Signal
        i_ena           : in  std_logic;
        --! Duration of one bit (expresed in number of clk cycles per bit)
        i_prescaler     : in  std_logic_vector(31 downto 0);
        --! Reciveve Data bus Line
        i_rxd           : in  std_logic;
        --! Data Recieved througth UART are stored/used
        --! If o_valid is high level and previous data are not accepted, overrun error  bit will be set
        --! if overrun is used. If not using overrun, output data would just be rewritten
        i_data_accepted : in  std_logic;
        --! Break Detected
        o_break         : out std_logic;
        --! Overrun Err Detected (high when old data is not read, but new data is redy on the output)
        o_overrun_err   : out std_logic;
        --! Frameing Err Detected (when STOP bit is expected, but input data is  not equal to '1')
        o_framein_err   : out std_logic;
        --! Parity Err Detected
        o_parity_err    : out std_logic;
        --! Recieved Data (DW = Data Width)
        o_rx_data       : out std_logic_vector(G_DATA_WIDTH-1 downto 0); -- Output Recieved Data
        --! Valid Data on the module output
        o_valid         : out std_logic
        );
end uart_rx_top;

architecture Behavioral of uart_rx_top is

begin

    UART_RX_inst_0:
    uart_rx
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
            i_clk                => i_clk,
            i_rst                => i_rst,
            i_uart.ena           => i_ena,
            i_uart.rxd           => i_rxd,
            i_uart.prescaler     => i_prescaler,
            i_uart.data_acc      => i_data_accepted,
            o_uart.break         => o_break,
            o_uart.overrun_err   => o_overrun_err,
            o_uart.framein_err   => o_framein_err,
            o_uart.parity_err    => o_parity_err,
            o_uart.rx_data       => o_rx_data,
            o_uart.valid         => o_valid
        );

end Behavioral;
