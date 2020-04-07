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

entity uart_rx is
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
        G_USE_BREAK        : boolean   := true;
        --! Use Overrun Error detection,
        --! Data Type: boolean, Default value: false
        G_USE_OVERRUN      : boolean   := true;
        --! Use Frameing Error detection,
        --! Data Type: boolean, Default value: false
        G_USE_FRAMEIN      : boolean   := true;
        --! Use Frameing Error detection,
        --! Data Type: U_PARITY(type deined in p_general package), Default value: NONE
        --! NONE(Parity not used), ODD(odd parity), EVEN(Even parity)
        G_USE_PARITY       : U_PARITY  := NONE
        );
    port
    (
        --! Input CLOCK
        i_clk           : in  std_logic;
        --! Reset for input clk domain
        i_rst           : in  std_logic;
        --! Input Uart Signals
        i_uart          : in  TYPE_UART_IN;
        --! Break Detected
        o_uart          : out TYPE_UART_OUT
    );
end uart_rx;

architecture Behavioral of uart_rx is

    -- UART FSM states
    type TYPE_UART_FSM is (IDLE, START_BIT, UART_MSG, PARITY, STOP_BIT);

    -- Registered valid signal from data_sample module
    type TYPE_CTRL_IN_REG is record
        valid       : std_logic;
    end record;

    -- Reset Values for TYPE_CTRL_REG type data
    constant TYPE_CTRL_IN_REG_RST : TYPE_CTRL_IN_REG := (
        valid      => '0');

    -- Siginficant values that would be forvarded to output or used for checks in code
    type TYPE_CTRL_REG is record
        fsm         : TYPE_UART_FSM;                            -- Current FSM state
        cnt         : integer range 0 to G_DATA_WIDTH;          -- Counter for Data Recieve (UART_MSG state)
        break_cnt   : integer range 0 to 15;                    -- Counter for Break timeout(BREAK    state)
        valid_sample: std_logic;
    end record;

    -- Reset Values for TYPE_CTRL_REG type data
    constant TYPE_CTRL_REG_RST : TYPE_CTRL_REG := (
        fsm          => IDLE,
        cnt          =>  0,
        break_cnt    =>  0,
        valid_sample => '0');

    -- All Zeros constant - Used for comparation when checking in data for BRAKE
    constant zeros         : std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
    -- Constant value     - Used to check if BREAK lasts too long (if break_cnt goes out of range Frameing error is signaled)
    constant const_timeout : integer := 5;

    -- signal - takes High Level if there is active RESET on the module input
    signal s_reset      : std_logic;
    signal s_sampler_en : std_logic;
    -- signal
    signal s_rxd        : std_logic;
    -- signal
    signal s_valid      : std_logic;

    -- signal - Registered siginficant values that would be forvarded to output or used for checks in code
    signal r_in_ctrl    : TYPE_CTRL_IN_REG;
    -- signal - Values Updated in combinational process that will be registered on the risinf edge of clk
    signal c_in_ctrl    : TYPE_CTRL_IN_REG;

    -- signal - Registered inputs to the module
    signal r_in         : TYPE_UART_IN;
    -- signal - Contains input values to be registered
    signal c_in         : TYPE_UART_IN;

    -- signal - Registered siginficant values that would be forvarded to output or used for checks in code
    signal r_ctrl       : TYPE_CTRL_REG;
    -- signal - Values Updated in combinational process that will be registered on the risinf edge of clk
    signal c_ctrl       : TYPE_CTRL_REG;

    -- signal - Registered siginficant values that would be forvarded to output or used for checks in code
    signal r_out        : TYPE_UART_OUT;
    -- signal - Values Updated in combinational process that will be registered on the risinf edge of clk
    signal c_out        : TYPE_UART_OUT;

begin

    -- equals '1' if there is active reset on the rst input, otherwise equals '0'
    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';
--------------------------------------------------------------------------------------------------------
--              Data Sample Module Instance
--------------------------------------------------------------------------------------------------------
  DS_inst_0:
  data_sample
      generic map (
          G_RST_LEVEVEL    => G_RST_LEVEVEL,
          G_SAMPLE_USED    => false,
          G_SAMPLE_PER_BIT => G_SAMPLE_PER_BIT)
      port map (
          i_clk         => i_clk,
          i_rst         => i_rst,
          i_sample      => '0',
          i_ena         => s_sampler_en,
          i_prescaler   => i_uart.prescaler,
          i_rxd         => i_uart.rxd,
          o_valid       => s_valid,
          o_rxd         => s_rxd );


data_sample_en:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                s_sampler_en <= '0';
            else
                if(r_in.ena = '1' and i_uart.rxd = '0') then
                    s_sampler_en <= '1';
                elsif(r_out.valid = '1') then
                    s_sampler_en <= '0';
                end if;
            end if;
        end if;
    end process data_sample_en;
-------------------------------------------------------------------------------------------------------
--        Registring Inputs
-------------------------------------------------------------------------------------------------------

-- If RST is active assign reset value to r_in,
-- else, register c_in value as r_in
reg_in_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_in      <= TYPE_UART_IN_RST;
                r_in_ctrl <= TYPE_CTRL_IN_REG_RST;
            else
                r_in      <= c_in;
                r_in_ctrl <= c_in_ctrl;
            end if;
        end if;
    end process reg_in_proc;

comb_in_proc:
    process(r_in, r_in_ctrl, i_uart, s_rxd, s_valid)
--    process(r_in.valid, r_in.ena, r_in.rxd, r_in.data_acc,
--            s_valid, s_rxd)
        variable V         : TYPE_UART_IN;
        variable V_ctrl    : TYPE_CTRL_IN_REG;
    begin
        V            := r_in;
        V_ctrl       := r_in_ctrl;

        V.ena        := i_uart.ena;
        V_ctrl.valid := s_valid;
        V.data_acc   := i_uart.data_acc;

        V.rxd        := '1';
        if V_ctrl.valid = '1' and r_in_ctrl.valid = '0' then
            V.rxd      := s_rxd;
        end if;

        -- Assign valuses that should be registered
        c_in      <= V;
        c_in_ctrl <= V_ctrl;

    end process comb_in_proc;

-------------------------------------------------------------------------------------------------------
--        Registring Outputs
-------------------------------------------------------------------------------------------------------
-- If RST is active assign reset value to r_out,
-- else, if i_sample rises to '1' register c_out value in r_out
reg_ctrl_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_ctrl     <= TYPE_CTRL_REG_RST;
            else
                r_ctrl     <= c_ctrl;
            end if;
        end if;
    end process reg_ctrl_proc;


-- If RST is active assign reset value to r_out,
-- else, if i_sample rises to '1' register c_out value in r_out
reg_out_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_out      <= TYPE_UART_OUT_RST;
            else
                r_out      <= c_out;
            end if;
        end if;
    end process reg_out_proc;

-------------------------------------------------------------------------------------------------------
--        Combinatonal Process
-------------------------------------------------------------------------------------------------------

comb_out_proc:
    process(r_in, r_in_ctrl, i_uart, r_out, r_ctrl)
--    process(r_in.ena, r_in.rxd, r_in.data_acc, r_in.valid, i_rxd,
--            r_out.break , r_out.overrun_err , r_out.framein_err , r_out.parity_err , r_out.rx_data , r_out.valid , r_ctrl.fsm , r_ctrl.cnt , r_ctrl.break_cnt ,
--            i_sample)
        variable V_ctrl    : TYPE_CTRL_REG;
        variable V_out     : TYPE_UART_OUT;

    begin
        V_out              := r_out;
        V_ctrl             := r_ctrl;

        V_ctrl.valid_sample:= r_in_ctrl.valid;

        if r_in.ena = '1' then
            case (r_ctrl.fsm) is
                -- Default FSM state (signals are in reset value)- waits for start bit
                -- Sets Counter cnt depending on LSB or MSB data notation expected
                when IDLE =>
                    V_out.parity_err := '0';
                    if (i_uart.rxd = '0') then
                        V_ctrl := TYPE_CTRL_REG_RST;
                        V_out  := TYPE_UART_OUT_RST;
                    end if;
                    -- Sets Counter cnt depending on LSB or MSB data notation expected
                    if (G_LSB_MSB = LSB) then
                        V_ctrl.cnt := 0;
                    else
                        V_ctrl.cnt := G_DATA_WIDTH -1;
                    end if;
                    -- waits for start bit
                    if r_in_ctrl.valid = '1' and r_in.rxd = '0' then
                        V_ctrl.fsm        := UART_MSG;
                    end if;

                -- Takes G_DATA_WIDTH bits after START_BIT to be registered
                -- Next state is - PARITY(if used), or STOP_BIT if PARITY is not used
                when UART_MSG =>
                    if r_in_ctrl.valid = '1' and r_ctrl.valid_sample = '0' then
                        V_out.rx_data(r_ctrl.cnt) := r_in.rxd;

                        if (G_LSB_MSB = LSB) then
                            if(r_ctrl.cnt = G_DATA_WIDTH -1) then
                                if (G_USE_PARITY = ODD or G_USE_PARITY = EVEN) then
                                    V_ctrl.fsm  := PARITY;
                                else
                                    V_ctrl.fsm  := STOP_BIT;
                                end if;
                                V_ctrl.cnt := 0;
                            else
                                V_ctrl.fsm  := UART_MSG;
                                V_ctrl.cnt  := r_ctrl.cnt +1;
                            end if;
                        else
                            if(r_ctrl.cnt = 0) then
                                if (G_USE_PARITY = ODD or G_USE_PARITY = EVEN) then
                                    V_ctrl.fsm  := PARITY;
                                else
                                    V_ctrl.fsm  := STOP_BIT;
                                end if;
                                V_ctrl.cnt  := 0;
                            else
                                V_ctrl.fsm  := UART_MSG;
                                V_ctrl.cnt  := r_ctrl.cnt -1;
                            end if;
                        end if;
                    end if;

                -- If Used Parity checks recieved data for parity
                -- If parity is not satisfied, parity error signal is rised
                -- Next State is STOP_BIT
                when PARITY =>
                    V_ctrl.fsm        := STOP_BIT;
                    if (G_USE_PARITY = ODD) then
                        V_out.parity_err     := '0';
                        if (r_in.rxd = f_parity(r_out.rx_data(G_DATA_WIDTH-1 downto 0))) then
                            V_out.parity_err := '1';
                        end if;
                    end if;

                    if (G_USE_PARITY = EVEN) then
                        V_out.parity_err     := '0';
                        if ( r_in.rxd = not(f_parity(r_out.rx_data(G_DATA_WIDTH-1 downto 0)))) then
                            V_out.parity_err := '1';
                        end if;
                    end if;

                -- Last bit that signals end of the message - expected to be '1'
                -- Next State
                --      IDLE - when '1' is detected on the output
                --             rises frameing or overrun error if detected (when used)
                --             if tehere is no errors rises VALID data signal
                --      BREAK- if all data recieved are Zeros(and STOP bit is Zero) break is detected(if used)
                when STOP_BIT =>
                    if r_in_ctrl.valid = '1' and r_ctrl.valid_sample = '0' then
                        if (r_in.rxd = '1') then
                            V_out.valid := '1';

                            if (r_out.overrun_err  = '1' or r_out.framein_err = '1' or V_out.parity_err  = '1') then
                                V_out.valid := '0';
                            end if;

                            if (G_USE_OVERRUN = true) then
                                if r_in.data_acc = '0' and V_out.valid = '1' then
                                    V_out.overrun_err := '1';
                                else
                                    V_out.overrun_err := '0';
                                end if;
                            end if;
                            V_ctrl.fsm := IDLE;
                        else
                            if (G_USE_FRAMEIN = true and G_USE_BREAK = false) then
                                 V_out.framein_err := '1';
                                 V_ctrl.fsm        := STOP_BIT;
                            elsif(G_USE_BREAK = true) then
                            -- Rises brake signal on the output if break detected
                            -- If lasts too long rises FRAMEING Err (if used) - timeout detection
                            -- Next state STOP_BIT
                                 if r_out.rx_data(G_DATA_WIDTH-1 downto 0) = zeros then
                                     V_out.framein_err := '0';
                                     V_out.parity_err  := '0';
                                     V_out.break       := '1';
                                     V_out.valid       := '0';
                                     if (G_USE_FRAMEIN = true) then
                                         V_ctrl.break_cnt  := r_ctrl.break_cnt +1;
                                         if r_ctrl.break_cnt >= const_timeout then --timeout
                                             V_out.framein_err := '1';
                                             V_out.break       := '0';
                                         end if;
                                    end if;
                                 else
                                     V_out.framein_err := '1';
                                 end if;
                                 V_ctrl.fsm         := STOP_BIT;
                            end if;
                        end if;
                    end if;

                when others =>
               --     V := TYPE_UART_OUT_RST;
            end case;
        end if;

        -- Assign valuses that should be registered
        c_ctrl <= V_ctrl;
        c_out  <= V_out;
    end process comb_out_proc;

-------------------------------------------------------------------------------------------------------
--        Outputs Assigment
-------------------------------------------------------------------------------------------------------
    o_uart  <= r_out;      -- Break Detected

end Behavioral;
