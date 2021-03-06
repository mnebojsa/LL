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
    use ieee.numeric_std.all;

    use work.p_general.all;
    use work.p_uart.all;

package p_lin is

-------------------------------------------------------------------------------------
--             Constants
-------------------------------------------------------------------------------------
    constant G_DATA_WIDTH     : positive  := 8;      -- Default 8


-------------------------------------------------------------------------------------
--             Data Types
-------------------------------------------------------------------------------------
    --! Type of frame sent
    type FRAME_TIPE is (UNCONDITIONAL, EVENT_TRIGGERED, SPORADIC, DIAGNOSTIC, RESERVERD);
    --!
    type COMNCT_SPEED is (CONST_SPEED, DETECT_SPEED);
                                                      --   31 30 29  28                                    16 15 14 13 12  11                            0
    type TYPE_LIN_DATA is record                      --    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
        word0      : std_logic_vector(63 downto 0);   --   "0  0  0" & DESTINATION_ADDRESS (13)              &"0  0  0  0"&    SIZE           (12)
        word1      : std_logic_vector(63 downto 0);   --               STATUS_INFORMATION  (16)              &"0  0  0"   DESTINATION_ADDRESS (13)
        word2      : std_logic_vector(63 downto 0);   --                                  TIME_STAMP LOVER    (32)
        word3      : std_logic_vector(63 downto 0);   --                                  TIME_STAMP HIGHER   (32)
        word4      : std_logic_vector(63 downto 0);   --    |LIN_DATA_BYTE   4   |  |LIN_DATA_BYTE   3   |  |LIN_DATA_BYTE   2   |  |LIN_DATA_BYTE   1   |
        word5      : std_logic_vector(63 downto 0);   --    |LIN_DATA_BYTE   8   |  |LIN_DATA_BYTE   7   |  |LIN_DATA_BYTE   6   |  |LIN_DATA_BYTE   5   |
        word6      : std_logic_vector(63 downto 0);   --    |    ZEROS           |  |    ZEROS           |  |    CHECKSUM        |  |LIN_DATA_BYTE   N   |
        word7      : std_logic_vector(63 downto 0);
        word8      : std_logic_vector(63 downto 0);
        word9      : std_logic_vector(63 downto 0);
        word10     : std_logic_vector(63 downto 0);
        word11     : std_logic_vector(63 downto 0);
    end record;

    constant TYPE_LIN_DATA_RST : TYPE_LIN_DATA := (
        word0        => (others => '0'),
        word1        => (others => '0'),
        word2        => (others => '0'),
        word3        => (others => '0'),
        word4        => (others => '0'),
        word5        => (others => '0'),
        word6        => (others => '0'),
        word7        => (others => '0'),
        word8        => (others => '0'),
        word9        => (others => '0'),
        word10       => (others => '0'),
        word11       => (others => '0')
        ); 


    --! LIN FSM interface inputs
    type TYPE_LIN_FSM_IN is record
        uart            : TYPE_UART_OUT;  -- Inputs To LIN FSM
        serial_in       : std_logic;
    end record;

    -- Reset Values for TYPE_LIN_FSM_IN type data
    constant TYPE_LIN_FSM_IN_RST : TYPE_LIN_FSM_IN := (
        uart        => TYPE_UART_OUT_RST,
        serial_in   => '1');

    type TYPE_LIN_FSM_IN_ARRAY is array (natural range <>) of TYPE_LIN_FSM_IN;


    --! LIN FSM interface output
    type TYPE_LIN_FSM_OUT is record
        rx_data       : std_logic_vector(G_DATA_WIDTH -1 downto 0); -- Output Recieved Data
        rx_data_valid : std_logic;
        en_uart       : std_logic;
		prescaler     : std_logic_vector(31 downto 0);
    end record;

    -- Reset Values for TYPE_LIN_FSM_OUT type data
    constant TYPE_LIN_FSM_OUT_RST : TYPE_LIN_FSM_OUT := (
        rx_data       => (others => '0'), -- Output Recieved Data
        rx_data_valid => '0',
        en_uart       => '0',
		prescaler     => (others => '0'));

    type TYPE_LIN_FSM_OUT_ARRAY is array (natural range <>) of TYPE_LIN_FSM_OUT;




    component LIN_fsm
        generic
        (
            G_DATA_WIDTH   : positive;
            G_RST_LEVEVEL  : RST_LEVEL;
            G_LIN_STANDARD : LIN_STD
        );
        port
        (
            i_clk           : in  std_logic;        -- Input CLOCK
            i_rst           : in  std_logic;        -- Input Reset for clk
            i_lin_fsm       : in  TYPE_LIN_FSM_IN;  -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
            o_lin_fsm       : out TYPE_LIN_FSM_OUT
        );
   end component LIN_fsm;

   function f_check_parity(data : std_logic_vector(7 downto 0)) return boolean;
   function f_valid_id    (data : std_logic_vector(7 downto 0)) return std_logic;
end package;

package body p_lin is

  function f_check_parity(data : std_logic_vector(7 downto 0)) return boolean is
    variable ret : boolean;
  begin
        ret :=( data(6) =    ( data(0) xor data(1) xor data(2) xor data(4) )) and 
		      ( data(7) = not( data(1) xor data(3) xor data(4) xor data(5) )) ;
    return ret;
  end function;

    function f_valid_id(data : std_logic_vector(7 downto 0)) return std_logic is
        variable ret : std_logic;  
    begin
        ret := '1';
        return ret;
    end function;

end package body;
