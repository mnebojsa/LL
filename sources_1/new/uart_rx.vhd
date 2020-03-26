----------------------------------------------------------------------------
-- Company     :
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
--   INPUTs:
--     |      name       |  type                          |    description
--     |--------------------------------------------------|--------------------------------------------------
--     | i_clk           | std_logic                      | Input CLOCK
--     | i_rst           | std_logic                      | Reset for input clk domain
--     | i_sample        | std_logic                      | Sample signal - take input when the signal become high
--     | i_ena           | std_logic                      | Uart Enable Signal
--     | i_rxd           | std_logic                      | Reciveve Data bus Line
--     | i_data_accepted | std_logic                      | Data Recieved througth UART are stored/used
--     ------------------------------------------------------------------------------------------------------
--
--   OUTPUTs:
--     |      name       |  type                          |    description
--     |--------------------------------------------------|--------------------------------------------------
--     | o_brake         | std_logic                      | Break Detected
--     | o_overrun_err   | std_logic                      | Overrun  Err Detected (old data not read, but new data redy for the output)
--     | o_framein_err   | std_logic                      | Frameing Err Detected (when STOP bit is expected input data not equal to '1')
--     | o_parity_err    | std_logic                      | Parity   Err Detected
--     | o_rx_data       | std_logic_vector(DW-1 downto 0)| Recieved Data (DW = Data Width)
--     | o_valid         | std_logic                      | Input Data Recieved througth UART are stored/used
--     ------------------------------------------------------------------------------------------------------
--
--
--   GENERICs:
--     |      name       |  type                          |    description
--     |--------------------------------------------------|--------------------------------------------------
--     | G_DATA_WIDTH    | integer                        | Data Width, Default value = 8
--     |                 |                                |
--     | G_RST_LEVEVEL   | RST_LEVEL                      | Module Reset Level (type deined in p_uart package):
--     |                 |                                |     HH(High Level), LL(Low Level)
--     |                 |                                |
--     | G_LSB_MSB       | LSB_MSB                        | Data format Expected (type deined in p_uart package):
--     |                 |                                |     LSB frame = START|LSB|  ...  |MSB|STOP - first recived data is LSB bit
--     |                 |                                |     MSB frame=  START|MSB|  ...  |LSB|STOP - first recived data is MSB bit
--     |                 |                                |
--     | G_USE_BREAK     | boolean                        | Use Brake signal detection, Default: false
--     |                 |                                |
--     | G_USE_OVERRUN   | boolean                        | Use Overrun Error detection, default false
--     |                 |                                |
--     | G_USE_FRAMEIN   | boolean                        | Use Frameing Error detection, default false
--     |                 |                                |
--     | G_USE_PARITY    | U_PARITY                       | Use Parity Error detection (type deined in p_uart package):
--     |                 |                                |     NONE - Parity bit not used
--     |                 |                                |     ODD  - Odd Parity Used
--     |                 |                                |     EVEN - Even Parity Used
--     ------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.p_uart.all;

entity uart_rx is
    generic(
        G_DATA_WIDTH       : integer   := 8;                  -- Default 8
        G_RST_LEVEVEL      : RST_LEVEL := HL;                 -- HL (High Level), LL(Low Level)
        G_LSB_MSB          : LSB_MSB   := LSB;                -- LSB(Least Significant Bit), MSB(Most Significant Bit)
        G_USE_BREAK        : boolean   := false;              -- true, false
        G_USE_OVERRUN      : boolean   := false;              -- true, false
        G_USE_FRAMEIN      : boolean   := false;              -- true, false
        G_USE_PARITY       : U_PARITY  := ODD                -- NONE(Parity not used), ODD(odd parity), EVEN(Even parity)
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
end uart_rx;

architecture Behavioral of uart_rx is
    -- UART FSM states
    type TYPE_UART_FSM is (IDLE, START_BIT, UART_MSG, PARITY, STOP_BIT, BREAK);

    -- Inputs registered
    type TYPE_IN_REG is record
        sample      : std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        ena         : std_logic;                      -- Input Uart Enable Signal
        rxd         : std_logic;                      -- Input Reciveve Data bus Line
        data_acc    : std_logic;                      -- Input Data Recieved througth UART are stored/used
    end record;

    -- Reset Values for TYPE_IN_REG type data
    constant TYPE_IN_REG_RST : TYPE_IN_REG := (
        sample       => '0',
        ena          => '0',
        rxd          => '0',
        data_acc     => '0');

    -- Siginficant values that would be forvarded to output or used for checks in code
    type TYPE_OUT_REG is record
        data_in     : std_logic;                                -- Input data registered
        break       : std_logic;                                -- Break signali
        overrun_err : std_logic;                                -- Output Error and Signaling
        framein_err : std_logic;                                -- Output Error and Signaling
        parity_err  : std_logic;                                -- Output Error and Signaling
        rx_data     : std_logic_vector(G_DATA_WIDTH-1 downto 0);-- Recieved Data
        valid       : std_logic;                                -- Recieved Data Valid
        fsm         : TYPE_UART_FSM;                            -- Current FSM state
        cnt         : integer range 0 to G_DATA_WIDTH;          -- Counter for Data Recieve (UART_MSG state)
        break_cnt   : integer range 0 to 15;                    -- Counter for Break timeout(BREAK    state)
    end record;

    -- Reset Values for TYPE_OUT_REG type data
    constant TYPE_OUT_REG_RST : TYPE_OUT_REG := (
        data_in      => '0',
        break        => '0',
        overrun_err  => '0',
        framein_err  => '0',
        parity_err   => '0',
        rx_data      => (others => '0'),
        valid        => '0',
        fsm          => IDLE,
        cnt          => 0,
        break_cnt    => 0);

    -- All Zeros constant - Used for comparation when checking in data for BRAKE
    constant zeros         : std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
    -- Constant value     - Used to check if BREAK lasts too long (if break_cnt goes out of range Frameing error is signaled)
    constant const_timeout : integer := 5;

    -- signal - takes High Level if there is active RESET on the module input
    signal s_reset    : std_logic;
    -- signal - Registered inputs to the module
    signal i_reg      : TYPE_IN_REG;
    -- signal - Contains input values to be registered
    signal c_to_i_reg : TYPE_IN_REG;

    -- signal - Registered siginficant values that would be forvarded to output or used for checks in code
    signal o_reg      : TYPE_OUT_REG;
    -- signal - Values Updated in combinational process that will be registered on the risinf edge of clk
    signal c_to_o_reg : TYPE_OUT_REG;
    -- signal - registered sample signal(trigers FSM)
    signal r_sample   : std_logic;
    -- signal - input i_sample value that will be registered on the rising edge of the clk
    signal c_sample   : std_logic;
    signal ssssssss   : std_logic;
    signal xxxxxxxx   : std_logic;

begin

    -- equals '1' if there is active reset on the rst input, otherwise equals '0'
    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';

    c_sample <= i_sample;

-------------------------------------------------------------------------------------------------------
--        Sequential Process
-------------------------------------------------------------------------------------------------------
reg_sample_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_sample   <= '0';
            else
                r_sample   <= c_sample;
            end if;
        end if;
    end process reg_sample_proc;

-- If RST is active assign reset value to i_reg,
-- else, if i_sample rises to '1' register c_to_o_reg value in o_reg
reg_out_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                i_reg      <= TYPE_IN_REG_RST;
            else
                if i_sample = '1' and r_sample = '0' then
                    o_reg      <= c_to_o_reg;
                end if;
            end if;
        end if;
    end process reg_out_proc;


-- If RST is active assign reset value to o_reg,
-- else, if i_sample rises to '1' register c_to_o_reg value in o_reg
reg_out_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                o_reg      <= TYPE_OUT_REG_RST;
            else
                if i_sample = '1' and r_sample = '0' then
                    o_reg      <= c_to_o_reg;
                end if;
            end if;
        end if;
    end process reg_out_proc;

-------------------------------------------------------------------------------------------------------
--        Combinatonal Process
-------------------------------------------------------------------------------------------------------

comb_out_proc:
    process(i_ena, i_rxd, i_data_accepted,i_sample , r_sample,
            o_reg.fsm, o_reg.cnt, o_reg.valid, o_reg.rx_data, o_reg.overrun_err,  o_reg.framein_err,  o_reg.parity_err, o_reg.break)
        variable V         : TYPE_OUT_REG;
        variable v_parity  : std_logic;
    begin
        V         := o_reg;
        V.data_in := i_rxd;

        if i_ena = '1' then
                case (o_reg.fsm) is
                    -- Default FSM state (signals are in reset value)- waits for start bit
                    -- When Start bit is detected changes to START_BIT state
                    when IDLE =>
                        V := TYPE_OUT_REG_RST;
                        if i_rxd = '0' then
                            V.fsm := START_BIT;
                        end if;

                    -- START_BIT state lasts just one data bit
                    -- Sets Counter cnt depending on LSB or MSB data notation expected
                    when START_BIT =>
                        V.fsm := UART_MSG;
                        if (G_LSB_MSB = MSB) then
                            V.cnt := 0;
                        else
                            V.cnt := G_DATA_WIDTH -1;
                        end if;

                    -- Takes G_DATA_WIDTH bits after START_BIT to be registered
                    -- Next state is - PARITY(if used), or STOP_BIT if PARITY is not used
                    when UART_MSG =>

                        V.rx_data(o_reg.cnt) := o_reg.data_in;
                        
                        if (G_LSB_MSB = MSB) then
                            if(o_reg.cnt = G_DATA_WIDTH -1) then
                                if (G_USE_PARITY = ODD or G_USE_PARITY = EVEN) then
                                    V.fsm  := PARITY;
                                else
                                    V.fsm  := STOP_BIT;
                                end if;
                                V.cnt := 0;
                            else
                                V.fsm  := UART_MSG;
                                V.cnt  := o_reg.cnt +1;
                            end if;
                        else
                            if(o_reg.cnt = 0) then
                                if (G_USE_PARITY = ODD or G_USE_PARITY = EVEN) then
                                    V.fsm := PARITY;
                                else
                                    V.fsm  := STOP_BIT;
                                end if;
                                V.cnt  := 0;
                            else
                                V.fsm  := UART_MSG;
                                V.cnt  := o_reg.cnt -1;
                            end if;
                        end if;

                    -- If Used Parity checks recieved data for parity
                    -- If parity is not satisfied, parity error signal is rised
                    -- Next State is STOP_BIT
                    when PARITY =>
                        V.fsm        := STOP_BIT;
                        v_parity     := '0';
                        if (G_USE_PARITY = ODD) then
                            ssssssss <= f_parity(o_reg.rx_data(G_DATA_WIDTH-1 downto 0));
                            xxxxxxxx <= i_rxd;
                            if (o_reg.data_in = f_parity(o_reg.rx_data(G_DATA_WIDTH-1 downto 0))) then
                                v_parity := '1';
                                ssssssss <= '0'; --i_rxd;
                            end if;
                        end if;

                        if (G_USE_PARITY = EVEN) then
                            if (o_reg.data_in = not(f_parity(o_reg.rx_data(G_DATA_WIDTH-1 downto 0)))) then
                                v_parity := '1';
                                ssssssss <= '0'; --i_rxd;
                            end if;
                        end if;

                    -- Last bit that signals end of the message - expected to be '1'
                    -- Next State
                    --      IDLE - when '1' is detected on the output
                    --             rises frameing or overrun error if detected (when used)
                    --             if tehere is no errors rises VALID data signal
                    --      BREAK- if all data recieved are Zeros(and STOP bit is Zero) break is detected(if used)
                    when STOP_BIT =>
                        if (i_rxd = '1') then
                            V.valid := '1';
                            if (o_reg.overrun_err  = '1' or o_reg.framein_err = '1' or o_reg.parity_err  = '1') then
                                V.valid := '0';
                            end if;

                            if (G_USE_OVERRUN = true) then
                                if i_data_accepted = '0' and V.valid = '1' then
                                    V.overrun_err := '1';
                                else
                                    V.overrun_err := '0';
                                end if;
                            end if;
                            V.fsm := IDLE;
                        else
                            if (G_USE_FRAMEIN = true and G_USE_BREAK = false) then
                                 V.framein_err := '1';
                                 V.fsm         := STOP_BIT;
                            elsif(G_USE_BREAK = true) then
                                 if o_reg.rx_data(G_DATA_WIDTH-1 downto 0) = zeros then
                                     V.framein_err := '0';
                                     V.fsm         := BREAK;
                                 else
                                     V.framein_err := '1';
                                     V.fsm         := STOP_BIT;
                                 end if;
                            end if;

                            if (G_USE_PARITY = ODD or G_USE_PARITY = EVEN) then
                                V.parity_err := v_parity;
                            end if;
                        end if;

                    -- Rises brake signal on the output if break detected
                    -- If lasts too long rises FRAMEING Err (if used) - timeout detection
                    -- Next state STOP_BIT - when '1' detected on the input
                    when BREAK =>
                        if (G_USE_BREAK = true) then
                            if (i_rxd = '1') then
                                V.valid := '1';
                                V.fsm   := STOP_BIT;
                                V.break := '1';
                            else
                                V.valid := '0';
                                if (G_USE_FRAMEIN = true) then
                                    V.break_cnt  := o_reg.break_cnt +1;
                                    if o_reg.break_cnt >= const_timeout then --timeout
                                        V.framein_err := '1';
                                        V.fsm         := BREAK;
                                            if i_rxd = '1' then
                                                 V.break_cnt  := 0;
                                                 V.fsm        := IDLE;
                                            end if;
                                    end if;
                                else
                                    V.framein_err := '0';
                                    V.fsm         := BREAK;
                                end if;
                                V.break := '0';
                            end if;
                        end if;

                    when others =>
                        V := TYPE_OUT_REG_RST;
                end case;
        end if;

        -- Assign valuses that should be registered
        c_to_o_reg <= V;
    end process comb_out_proc;

-------------------------------------------------------------------------------------------------------
--        Outputs Assigment
-------------------------------------------------------------------------------------------------------
    o_brake         <= o_reg.break;                      -- Break Detected
    o_overrun_err   <= o_reg.overrun_err;                -- Output Error and Signaling
    o_framein_err   <= o_reg.framein_err;                -- Output Error and Signaling
    o_parity_err    <= o_reg.parity_err;                 -- Output Error and Signaling
    o_rx_data       <= o_reg.rx_data;                    -- Output Recieved Data
    o_valid         <= o_reg.valid;                      -- Output Data Valid

end Behavioral;
