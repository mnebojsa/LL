library ieee;
use ieee.std_logic_1164.all;

package p_uart_interface is
    --! Used to select High(HL) ot Low(LL) Reset Level for the module
    type RST_LEVEL is (HL, LL);
    --! Used to choose LSB or MSB data expected on the rxd input
    type LSB_MSB   is (LSB , MSB);

    --! Calculates parity
    function f_parity(s_in           : std_logic_vector) return std_logic;

    --!UART_RX component
    component uart_rx is
        generic(
            G_DATA_WIDTH       : integer;
            G_RST_LEVEVEL      : RST_LEVEL;
            G_LSB_MSB          : LSB_MSB;
            G_USE_BREAK        : boolean;
            G_USE_OVERRUN      : boolean;
            G_USE_FRAMEIN      : boolean;
            G_USE_PARITY_ODD   : boolean;
            G_USE_PARITY_EVEN  : boolean
        );
        port   (
            i_clk           : in  std_logic;                      -- Input CLOCK
            i_rst           : in  std_logic;                      -- Input Reset for clk
            i_sample        : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
            i_ena           : in  std_logic;                      -- Input Uart Enable Signal
            i_rxd           : in  std_logic;                      -- Input Reciveve Data bus Line
            i_data_accepted : in  std_logic;                      -- Input Data Recieved througth UART are stored/used
            o_brake         : out std_logic;                      -- Break Detected
            o_overrun_err   : out std_logic;                      -- Output Error and Signaling
            o_framein_err   : out std_logic;                      -- Output Error and Signaling
            o_parity_err    : out std_logic;                      -- Output Error and Signaling
            o_rx_data       : out std_logic_vector(G_DATA_WIDTH-1 downto 0); -- Output Recieved Data
            o_valid         : out std_logic
        );
    end component;

end package;

package body p_uart_interface is

    function f_parity(s_in : std_logic_vector) return std_logic is
        variable ret : std_logic;
    begin
	    ret := '0';

        for i in 0 to s_in'length -1 loop
		    ret := ret xor s_in(i);
		end loop;

        return ret;
    end function;

end package body;

--------------------------------------------------------------------------------------------
--                    UART_RX INSTANTIATION template
--------------------------------------------------------------------------------------------

--UART_RX_inst_num: uart_rx
--    generic map(
--        G_DATA_WIDTH       => 8,
--        G_RST_LEVEVEL      => HL,
--        G_LSB_MSB          => LSB,
--        G_USE_BREAK        => true,
--        G_USE_OVERRUN      => true,
--        G_USE_FRAMEIN      => true,
--        G_USE_PARITY_ODD   => true,
--        G_USE_PARITY_EVEN  => true
--    )
--    port map  (
--        i_clk           => i_clk,               -- Input CLOCK
--        i_rst           => s_rst,               -- Input Reset for clk
--        i_sample        => s_sample,            -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
--        i_ena           => s_ena,               -- Input Uart Enable Signal
--        i_rxd           => s_rxd,               -- Input Reciveve Data bus Line
--        i_data_accepted => s_data_accepted,     -- Input Data Recieved througth UART are stored/used
--        o_brake         => s_uart_brake,        -- Break Detected
--        o_overrun_err   => s_overrun_err,       -- Output Error and Signaling
--        o_framein_err   => s_framein_err,       -- Output Error and Signaling
--        o_parity_err    => s_parity_err,        -- Output Error and Signaling
--        o_valid         => s_uart_valid,
--        o_rx_data       => s_uart_rx_data       -- Output Recieved Data
--    );


