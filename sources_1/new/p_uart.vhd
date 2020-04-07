----------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
----------------------------------------------------------------------------
-- File        : uart_rx.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : March 10th, 2020
-- Modified    :
-- Changes     :
---------------------------------------------------------------------------
-- Design Unit : uart_rx.vhd
-- Library     :
---------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- Description : Full UART_RX module
--
--
--
----------------------------------------------------------------------------------------------------------------

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

package p_uart is
    constant G_DATA_WIDTH     : positive  := 8;      -- Default 8

    -- Inputs registered
    type TYPE_UART_IN is record
        ena         : std_logic;             -- Input Uart Enable Signal
        prescaler   : unsigned(31 downto 0); -- 
        rxd         : std_logic;             -- Input Reciveve Data bus Line
        data_acc    : std_logic;             -- Input Data Recieved througth UART are stored/used
    end record;

    -- Reset Values for TYPE_UART_IN type data
    constant TYPE_UART_IN_RST : TYPE_UART_IN := (
        ena          => '0',
		prescaler    => (others => '0'),
        rxd          => '0',
        data_acc     => '0');


    -- Inputs registered
    type TYPE_UART_OUT is record
        break         : std_logic;           -- Break Detected
        overrun_err   : std_logic;           -- Output Error and Signaling
        framein_err   : std_logic;           -- Output Error and Signaling
        parity_err    : std_logic;           -- Output Error and Signaling
        rx_data       : std_logic_vector(G_DATA_WIDTH -1 downto 0);    -- Output Recieved Data
        valid         : std_logic;
    end record;

    -- Reset Values for TYPE_UART_OUT type data
    constant TYPE_UART_OUT_RST : TYPE_UART_OUT := (
        break          => '0',
		overrun_err    => '0',
        framein_err    => '0',
        parity_err     => '0',
        rx_data        => (others => '0'),
        valid          => '0');

    --! Calculates parity
    function f_parity(s_in   : std_logic_vector) return std_logic;

    --!UART_RX component
    component uart_rx is
        generic
		 (
            G_DATA_WIDTH     : positive  := 8;      -- Default 8
            G_RST_LEVEVEL    : RST_LEVEL := HL;     -- HL (High Level), LL(Low Level)
            G_SAMPLE_PER_BIT : positive  := 13;
            G_LSB_MSB        : LSB_MSB   := LSB;    -- LSB(Least Significant Bit), MSB(Most Significant Bit)
            G_USE_BREAK      : boolean   := true;   -- true, false
            G_USE_OVERRUN    : boolean   := true;   -- true, false
            G_USE_FRAMEIN    : boolean   := true;   -- true, false
            G_USE_PARITY     : U_PARITY  := ODD     -- NONE(Parity not used), ODD(odd parity), EVEN(Even parity)
        );
        port
		  (
            i_clk            : in  std_logic;       -- Input CLOCK
            i_rst            : in  std_logic;       -- Input Reset for clk
            i_uart           : in  TYPE_UART_IN;    -- Input Uart Signals
            o_uart           : out TYPE_UART_OUT    -- Output Recieved Data 
        );
    end component;

    component data_sample
        generic(
            G_RST_LEVEVEL      : RST_LEVEL;                          -- HL (High Level), LL(Low Level)
            G_SAMPLE_USED      : boolean;                            --
            G_SAMPLE_PER_BIT   : positive
            );
        port   (
            i_clk              : in  std_logic;                      -- Input CLOCK
            i_rst              : in  std_logic;                      -- Input Reset for clk
            i_sample           : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
            i_ena              : in  std_logic;                      -- Input Uart Enable Signal
            i_prescaler        : in  std_logic_vector(31 downto 0);
            i_rxd              : in  std_logic;                      -- Input Reciveve Data bus Line
            o_valid            : out std_logic;                      -- Input Reciveve Data bus Line
            o_rxd              : out std_logic                       -- Output Recieved Data
            );
    end component;


    component BRG
        generic(
            G_RST_LEVEVEL    : RST_LEVEL := HL;
            G_SAMPLE_USED    : boolean   := false;
            G_SAMPLE_PER_BIT : positive  := 13;           --
            G_DATA_WIDTH     : positive  := 8
        );
        port
        (
            i_clk            : in  std_logic;
            i_rst            : in  std_logic;
            i_sample         : in  std_logic;
            i_ena            : in  std_logic;
            i_prescaler      : in  std_logic_vector(31 downto 0);
            o_sample         : out std_logic
        );
    end component;

end package;

package body p_uart is

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
