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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
        G_USE_PARITY       : U_PARITY  := ODD
        );
    port   (
        --! Input CLOCK
        i_clk           : in  std_logic;
        --! Reset for input clk domain
        i_rst           : in  std_logic;
        --! Uart Enable Signal
        i_ena           : in  std_logic;
        --! Duration of one bit (expresed in number of clk cycles per bit)
        i_prescaler     : in  integer range 0 to 256;
        --! Reciveve Data bus Line
        i_rxd           : in  std_logic;
        --! Data Recieved througth UART are stored/used
        --! If o_valid is high level and previous data are not accepted, overrun error  bit will be set
        --! if overrun is used. If not using overrun, output data would just be rewritten
        i_data_accepted : in  std_logic;
        --! Break Detected
        o_brake         : out std_logic;
        --! Overrun Err Detected (high when old data is not read, but new data is redy on the output)
        o_overrun_err   : out std_logic;
        --! Frameing Err Detected (when STOP bit is expected, but input data is  not equal to '1')
        o_framein_err   : out std_logic;
        --! Parity Err Detected
        o_parity_err    : out std_logic;                      -- Output Error and Signaling
        --! Recieved Data (DW = Data Width)
        o_rx_data       : out std_logic_vector(G_DATA_WIDTH-1 downto 0); -- Output Recieved Data
        --! Valid Data on the module output
        o_valid         : out std_logic
        );
end uart_rx;

architecture Behavioral of uart_rx is

    -- UART FSM states
    type TYPE_UART_FSM is (IDLE, START_BIT, UART_MSG, PARITY, STOP_BIT);

    -- Inputs registered
    type TYPE_IN_REG is record
        ena         : std_logic;                      -- Input Uart Enable Signal
        rxd         : std_logic;                      -- Input Reciveve Data bus Line
        valid       : std_logic;
        data_acc    : std_logic;                      -- Input Data Recieved througth UART are stored/used
    end record;

    -- Reset Values for TYPE_IN_REG type data
    constant TYPE_IN_REG_RST : TYPE_IN_REG := (
        ena          => '0',
        rxd          => '1',
        valid        => '0',
        data_acc     => '0');

    -- Siginficant values that would be forvarded to output or used for checks in code
    type TYPE_OUT_REG is record
        break       : std_logic;                                -- Break signali
        overrun_err : std_logic;                                -- Output Error and Signaling
        framein_err : std_logic;                                -- Output Error and Signaling
        parity_err  : std_logic;                                -- Output Error and Signaling
        rx_data     : std_logic_vector(G_DATA_WIDTH-1 downto 0);-- Recieved Data
        valid       : std_logic;                                -- Recieved Data Valid
        fsm         : TYPE_UART_FSM;                            -- Current FSM state
        cnt         : integer range 0 to G_DATA_WIDTH;          -- Counter for Data Recieve (UART_MSG state)
        break_cnt   : integer range 0 to 15;                    -- Counter for Break timeout(BREAK    state)
        valid_sample: std_logic;
    end record;

    -- Reset Values for TYPE_OUT_REG type data
    constant TYPE_OUT_REG_RST : TYPE_OUT_REG := (
        break        => '0',
        overrun_err  => '0',
        framein_err  => '0',
        parity_err   => '0',
        rx_data      => (others => '0'),
        valid        => '0',
        fsm          => IDLE,
        cnt          =>  0,
        break_cnt    =>  0,
        valid_sample => '0');

    -- All Zeros constant - Used for comparation when checking in data for BRAKE
    constant zeros         : std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
    -- Constant value     - Used to check if BREAK lasts too long (if break_cnt goes out of range Frameing error is signaled)
    constant const_timeout : integer := 5;

    -- signal - takes High Level if there is active RESET on the module input
    signal s_reset    : std_logic;
    signal s_sampler_en    : std_logic;
    -- signal
    signal s_rxd      : std_logic;
    -- signal
    signal s_valid    : std_logic;
    -- signal - Registered inputs to the module
    signal r_in       : TYPE_IN_REG;
    -- signal - Contains input values to be registered
    signal c_in       : TYPE_IN_REG;

    -- signal - Registered siginficant values that would be forvarded to output or used for checks in code
    signal o_reg      : TYPE_OUT_REG;
    -- signal - Values Updated in combinational process that will be registered on the risinf edge of clk
    signal c_to_o_reg : TYPE_OUT_REG;

begin

    -- equals '1' if there is active reset on the rst input, otherwise equals '0'
    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';

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
          i_prescaler   => i_prescaler,
          i_rxd         => i_rxd,
          o_valid       => s_valid,
          o_rxd         => s_rxd );


    process(i_clk)
     begin
         if rising_edge(i_clk) then
             if(s_reset = '1') then
                  s_sampler_en <= '0';
              else
                  if(r_in.ena = '1' and i_rxd = '0') then
                         s_sampler_en <= '1';
                     elsif(o_reg.valid = '1') then
                         s_sampler_en <= '0';
                     end if;
              end if;
         end if;
    end process;
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
                r_in      <= TYPE_IN_REG_RST;
            else
                r_in      <= c_in;
            end if;
        end if;
    end process reg_in_proc;

comb_in_proc:
    process(r_in, i_ena, s_rxd, i_data_accepted, s_valid)
--    process(r_in.valid, r_in.ena, r_in.rxd, r_in.data_acc,
--            s_valid, s_rxd)
        variable V         : TYPE_IN_REG;
    begin
        V          := r_in;

        V.ena      := i_ena;
        V.valid    := s_valid;
        V.data_acc := i_data_accepted;

        if V.valid = '1' and r_in.valid = '0' then
            V.rxd      := s_rxd;
        end if;

        -- Assign valuses that should be registered
        c_in <= V;
    end process comb_in_proc;

-------------------------------------------------------------------------------------------------------
--        Registring Outputs
-------------------------------------------------------------------------------------------------------

-- If RST is active assign reset value to o_reg,
-- else, if i_sample rises to '1' register c_to_o_reg value in o_reg
reg_out_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                o_reg      <= TYPE_OUT_REG_RST;
            else
                o_reg      <= c_to_o_reg;
            end if;
        end if;
    end process reg_out_proc;

-------------------------------------------------------------------------------------------------------
--        Combinatonal Process
-------------------------------------------------------------------------------------------------------

comb_out_proc:
    process(r_in, o_reg, i_rxd)
--    process(r_in.ena, r_in.rxd, r_in.data_acc, r_in.valid, i_rxd,
--            o_reg.break , o_reg.overrun_err , o_reg.framein_err , o_reg.parity_err , o_reg.rx_data , o_reg.valid , o_reg.fsm , o_reg.cnt , o_reg.break_cnt ,
--            i_sample)
        variable V         : TYPE_OUT_REG;
        variable v_parity  : std_logic;
    begin
        V              := o_reg;
        V.valid_sample := r_in.valid;

        if r_in.ena = '1' then
            case (o_reg.fsm) is
                -- Default FSM state (signals are in reset value)- waits for start bit
                -- Sets Counter cnt depending on LSB or MSB data notation expected
                when IDLE =>
                    v_parity := '0';
                    if (i_rxd = '0') then
                        V := TYPE_OUT_REG_RST;
                    end if;
                    -- Sets Counter cnt depending on LSB or MSB data notation expected
                    if (G_LSB_MSB = LSB) then
                        V.cnt := 0;
                    else
                        V.cnt := G_DATA_WIDTH -1;
                    end if;
                    -- waits for start bit
                    if r_in.valid = '1' and r_in.rxd = '0' then
                        V.fsm        := UART_MSG;
                    end if;

                -- Takes G_DATA_WIDTH bits after START_BIT to be registered
                -- Next state is - PARITY(if used), or STOP_BIT if PARITY is not used
                when UART_MSG =>
                    if r_in.valid = '1' and o_reg.valid_sample = '0' then
                        V.rx_data(o_reg.cnt) := r_in.rxd;

                        if (G_LSB_MSB = LSB) then
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
                                    V.fsm  := PARITY;
                                else
                                    V.fsm  := STOP_BIT;
                                end if;
                                V.cnt  := 0;
                            else
                                V.fsm  := UART_MSG;
                                V.cnt  := o_reg.cnt -1;
                            end if;
                        end if;
                    end if;

                -- If Used Parity checks recieved data for parity
                -- If parity is not satisfied, parity error signal is rised
                -- Next State is STOP_BIT
                when PARITY =>
--                        V.fsm        := STOP_BIT;
--                        if (G_USE_PARITY = ODD) then
--                                  v_parity     := '0';
--                            if (r_in.rxd = f_parity(o_reg.rx_data(G_DATA_WIDTH-1 downto 0))) then
--                                v_parity := '1';
--                            end if;
--                        end if;
--
--                        if (G_USE_PARITY = EVEN) then
--                            v_parity     := '0';
--                            if ( r_in.rxd = not(f_parity(o_reg.rx_data(G_DATA_WIDTH-1 downto 0)))) then
--                                v_parity := '1';
--                            end if;
--                        end if;
--
--                    -- Last bit that signals end of the message - expected to be '1'
--                    -- Next State
--                    --      IDLE - when '1' is detected on the output
--                    --             rises frameing or overrun error if detected (when used)
--                    --             if tehere is no errors rises VALID data signal
--                    --      BREAK- if all data recieved are Zeros(and STOP bit is Zero) break is detected(if used)
                when STOP_BIT =>
                    if r_in.valid = '1' and o_reg.valid_sample = '0' then
                        if (r_in.rxd = '1') then
                            V.valid := '1';

                            V.parity_err := v_parity;
                            v_parity     := '0';

                            if (o_reg.overrun_err  = '1' or o_reg.framein_err = '1' or V.parity_err  = '1') then
                                V.valid := '0';
                            end if;

                            if (G_USE_OVERRUN = true) then
                                if r_in.data_acc = '0' and V.valid = '1' then
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
                            -- Rises brake signal on the output if break detected
                            -- If lasts too long rises FRAMEING Err (if used) - timeout detection
                            -- Next state STOP_BIT
                                 if o_reg.rx_data(G_DATA_WIDTH-1 downto 0) = zeros then
                                     V.framein_err := '0';
                                              v_parity      := '0';
                                              V.break       := '1';
                                     V.valid       := '0';
                                     if (G_USE_FRAMEIN = true) then
                                         V.break_cnt  := o_reg.break_cnt +1;
                                         if o_reg.break_cnt >= const_timeout then --timeout
                                             V.framein_err := '1';
                                             V.break       := '0';
                                         end if;
                                    end if;
                                 else
                                     V.framein_err := '1';
                                 end if;
                                 V.fsm         := STOP_BIT;
                            end if;
                        end if;
                    end if;

                when others =>
               --     V := TYPE_OUT_REG_RST;
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
