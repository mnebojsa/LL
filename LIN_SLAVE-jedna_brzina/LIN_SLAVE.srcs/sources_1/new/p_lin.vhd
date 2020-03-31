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

library ieee;
use ieee.std_logic_1164.all;

package p_lin is
    --! Used to select High(HL) ot Low(LL) Reset Level for the module
   -- type RST_LEVEL is (HL, LL);
    type LIN_STD   is (L1_0, L2_0);
    --! Used to select High(HL) ot Low(LL) Reset Level for the module
    type RST_LEVEL is (HL, LL);
    --! Type of frame sent
    type FRAME_TIPE is (UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC, RESERVERD);
    --!
    type COMNCT_SPEED is (CONST_SPEED, DETECT_SPEED);

    component LIN_fsm is
        generic(
            G_DATA_LEN    : integer;
            G_RST_LEVEVEL : RST_LEVEL;
            G_LIN_STANDARD: LIN_STD
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

   function f_check_parity(data : std_logic_vector(7 downto 0)) return boolean;
   function f_valid_id    (data : std_logic_vector(7 downto 0)) return std_logic;
end package;

package body p_lin is

  function f_check_parity(data : std_logic_vector(7 downto 0)) return boolean is
    variable ret : boolean;
  begin
        ret :=( data(6) = ( data(0) xor data(1) xor data(2) xor data(4))) and (data(7) = not(data(1) xor data(3) xor data(4) xor data(5) )) ;
    return ret;
  end function;

    function f_valid_id(data : std_logic_vector(7 downto 0)) return std_logic is
        variable ret : std_logic;  
    begin
        ret := '1';
        return ret;
    end function;

end package body;