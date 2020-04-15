---------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
---------------------------------------------------------------------------
-- File        : uart_rx.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : March 10th, 2020
-- Modified    :
-- Changes     :
---------------------------------------------------------------------------
-- Design Unit : uart_rx.vhd
-- Library     :
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Description : Full UART_RX module
--
--
--
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--                    UART_RX INSTANTIATION template
---------------------------------------------------------------------------
--
-- UART_RX_inst_num:
--   uart_rx_top
--       generic map
--       (
--           G_DATA_WIDTH     => G_DATA_WIDTH,
--           G_RST_LEVEVEL    => G_RST_LEVEVEL,
--           G_SAMPLE_PER_BIT => G_SAMPLE_PER_BIT,
--           G_LSB_MSB        => G_LSB_MSB,
--           G_USE_BREAK      => G_USE_BREAK,
--           G_USE_OVERRUN    => G_USE_OVERRUN,
--           G_USE_FRAMEIN    => G_USE_FRAMEIN,
--           G_USE_PARITY     => G_USE_PARITY
--       )
--       port map
--       (
--           i_clk          => i_clk,
--           i_rst          => i_rst,
--           i_ena          => i_ena,
--           i_rxd          => i_rxd,
--           i_prescaler    => i_prescaler,
--           i_data_accepted=> i_data_accepted,
--           o_break        => o_break,
--           o_overrun_err  => o_overrun_err,
--           o_framein_err  => o_framein_err,
--           o_parity_err   => o_parity_err,
--           o_rx_data      => o_rx_data,
--           o_valid        => o_valid
--       );
---------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.p_general.all;


package p_uart is

-------------------------------------------------------------------------------------
--             Constants
-------------------------------------------------------------------------------------

    constant G_DATA_WIDTH     : positive  := 8;      -- Default 8

-------------------------------------------------------------------------------------
--             Data Types
-------------------------------------------------------------------------------------
 --------------
 -- ** UART **
 --------------
    --! UART interface inputs
    type TYPE_UART_IN is record
        ena         : std_logic;             -- Input Uart Enable Signal
        prescaler   : std_logic_vector(31 downto 0); --
        rxd         : std_logic;             -- Input Reciveve Data bus Line
        data_acc    : std_logic;             -- Input Data Recieved througth UART are stored/used
    end record;

    -- Reset Values for TYPE_UART_IN type data
    constant TYPE_UART_IN_RST : TYPE_UART_IN := (
        ena          => '0',
        prescaler    => (others => '0'),
        rxd          => '0',
        data_acc     => '0');

    type TYPE_UART_IN_ARRAY is array (natural range <>) of TYPE_UART_IN;


    --! UART interface outputs
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

    type TYPE_UART_OUT_ARRAY is array (natural range <>) of TYPE_UART_OUT;

 ---------------------
 -- ** DATA_SAMPLE **
 ---------------------

    --! DATA SAMPLE interface inputs
    type TYPE_IN_DS is record
        sample      : std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        ena         : std_logic;                      -- Input Uart Enable Signal
        rxd         : std_logic;                      -- Input Reciveve Data bus Line
        prescaler   : std_logic_vector(31 downto 0);
    end record;

    -- Reset Values for TYPE_IN_DS type data
    constant TYPE_IN_DS_RST : TYPE_IN_DS := (
        sample       => '0',
        ena          => '0',
        rxd          => '0',
        prescaler    => (others => '0'));

    type TYPE_IN_DS_ARRAY is array (natural range <>) of TYPE_IN_DS;

    --! DATA SAMPLE interface outputs
    type TYPE_OUT_DS is record
        valid        : std_logic; -- valid registered signal value (after sampling of the input)
        rxd          : std_logic; -- sampled input bus value
    end record;

    -- Reset Values for TYPE_IN_DS type data
    constant TYPE_OUT_DS_RST : TYPE_OUT_DS := (
        valid        => '0',
        rxd          => '0');

    type TYPE_OUT_DS_ARRAY is array (natural range <>) of TYPE_OUT_DS;


 ----------------------
 -- ** BAUD RATE GEN **
 ----------------------

    --! BRG interface inputs
    type TYPE_BRG_IN is record
        sample     : std_logic;                    -- Sample from the Module's input
        ena        : std_logic;                    -- Enable Module signal
        prescaler  : std_logic_vector(31 downto 0);-- Duration of one bit (expresed in number of clk cycles per bit)
    end record;

    constant TYPE_BRG_IN_RST : TYPE_BRG_IN := (
        sample     => '0',
        ena        => '0',
        prescaler  => (others => '0'));

    type TYPE_BRG_IN_ARRAY is array (natural range <>) of TYPE_BRG_IN;


    --! BRG interface outputs
    type TYPE_BRG_OUT is record
        brs          : std_logic;  -- baud rate sample
    end record;

    constant TYPE_BRG_OUT_RST : TYPE_BRG_OUT := (
        brs          => '0');

    type TYPE_BRG_OUT_ARRAY is array (natural range <>) of TYPE_BRG_OUT;

-------------------------------------------------------------------------------------
--             Component declaration
-------------------------------------------------------------------------------------

 --------------
 -- ** UART **
 --------------
    -- UART_RX component
    -- Captures UART message on the input
    -- Signalig Data Valid and provides recived message as a vector
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


 ---------------------
 -- ** DATA_SAMPLE **
 ---------------------
    -- Data Sampler
    -- Uses BRG samples to sample i_ds.rxd input
    -- On the outputs gives rxd value after decideing and data valid signaling
    component data_sample
        generic(
            G_RST_LEVEVEL      : RST_LEVEL;       -- HL (High Level), LL(Low Level)
            G_SAMPLE_USED      : boolean;         --
            G_SAMPLE_PER_BIT   : positive
            );
        port   (
            i_clk              : in  std_logic;   -- Input CLOCK
            i_rst              : in  std_logic;   -- Input Reset for clk
            i_ds               : in  TYPE_IN_DS;  -- Input to Sample module
            o_ds               : out TYPE_OUT_DS  -- Output Recieved Data
            );
    end component;


 ----------------------
 -- ** BAUD RATE GEN **
 ----------------------
    -- Baud Rate GENERATOR
    -- The component gives G_SAMPLE_PER_BIT samples in i_brg.prescaler clk cycles
    component BRG
        generic(
            G_RST_LEVEVEL    : RST_LEVEL;
            G_SAMPLE_USED    : boolean;
            G_SAMPLE_PER_BIT : positive;
            G_DATA_WIDTH     : positive
        );
        port
        (
            i_clk            : in  std_logic;
            i_rst            : in  std_logic;
            i_brg            : in  TYPE_BRG_IN;
            o_brg            : out TYPE_BRG_OUT
        );
    end component;

-------------------------------------------------------------------------------------
--             Function declaration
-------------------------------------------------------------------------------------

    -- If s_in has even number of 1's, the function returns '0'
    -- If s_in has odd  number of 1's, the function returns '1'
    function f_parity(s_in   : std_logic_vector) return std_logic;

end package;

package body p_uart is

    --! Calculates parity
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
