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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.p_uart_interface.all;

entity uart_rx is
    generic(
        G_DATA_WIDTH       : integer   := 8;
        G_RST_LEVEVEL      : RST_LEVEL := HL;
	    G_LSB_MSB          : LSB_MSB   := LSB;
        G_USE_BREAK        : boolean   := true;
        G_USE_OVERRUN      : boolean   := true;
        G_USE_FRAMEIN      : boolean   := true;
        G_USE_PARITY_ODD   : boolean   := true;
        G_USE_PARITY_EVEN  : boolean   := false
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

type TYPE_UART_FSM is (IDLE, START_BIT, UART_MSG, PARITY, STOP_BIT, BREAK);

type TYPE_OUT_REG is record
    break       : std_logic;
    overrun_err : std_logic;                      -- Output Error and Signaling
    framein_err : std_logic;                      -- Output Error and Signaling
    parity_err  : std_logic;                      -- Output Error and Signaling
    rx_data     : std_logic_vector(0 to G_DATA_WIDTH-1);
    valid       : std_logic;
    sample      : std_logic;
    fsm         : TYPE_UART_FSM;
    cnt         : integer range 0 to G_DATA_WIDTH;
    break_cnt   : integer range 0 to 15;
end record;

constant TYPE_OUT_REG_RST : TYPE_OUT_REG := (
    break        => '0',
    overrun_err  => '0',
    framein_err  => '0',
    parity_err   => '0',
    rx_data      => (others => '0'),
    valid        => '0',
    sample       => '0',
    fsm          => IDLE,
    cnt          => 0,
    break_cnt    => 0);

constant const_timeout : integer := 5;

    signal s_reset            : std_logic;

    signal o_reg, c_to_o_reg : TYPE_OUT_REG;
begin

    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';

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
--        Ouput UART
-------------------------------------------------------------------------------------------------------

comb_out_proc:
    process(i_ena, i_sample, i_rxd, i_data_accepted,
            o_reg.fsm, o_reg.cnt, o_reg.valid, o_reg.rx_data, o_reg.overrun_err,  o_reg.framein_err,  o_reg.parity_err, o_reg.break)
        variable V         : TYPE_OUT_REG;
        variable v_started : std_logic;
    begin
        V         := o_reg;
        V.sample  := i_sample;

        if i_ena = '1' then
            if i_sample = '1' and o_reg.sample = '0' then
                case (o_reg.fsm) is

                    when IDLE =>
                        V := TYPE_OUT_REG_RST;
                        if i_rxd = '0' then
                            V.fsm := START_BIT;
                        end if;

                    when START_BIT =>
                        V.fsm := UART_MSG;

                    when UART_MSG =>
                        if i_ena = '1' then
                            if i_sample = '1' and o_reg.sample = '0' then
                                if (o_reg.fsm = UART_MSG) then
                                    if (G_LSB_MSB = LSB) then
                                        V.cnt := o_reg.cnt +1;
                                        if(V.cnt = G_DATA_WIDTH -1) then
                                            if (G_USE_PARITY_ODD = true or G_USE_PARITY_EVEN = true) then
                                                V.fsm  := PARITY;
                                            else
                                                V.fsm  := STOP_BIT;
                                            end if;
                                        else
                                            V.fsm  := UART_MSG;
                                        end if;
                                    else
                                        V.cnt := o_reg.cnt -1;
                                        if(V.cnt = 0) then
                                            if (G_USE_PARITY_ODD = true or G_USE_PARITY_EVEN = true) then
                                                V.fsm := PARITY;
                                            else
                                                V.fsm   := STOP_BIT;
                                            end if;
                                        else
                                            V.fsm  := UART_MSG;
                                        end if;
                                   end if;                    
                               else
                                   if (G_LSB_MSB = LSB) then
                                       V.cnt := 0;
                                   else
                                       V.cnt := G_DATA_WIDTH -1;
                                   end if;
                               end if;
                           end if;
                       end if;
                       V.rx_data(V.cnt) := i_rxd;

                    when PARITY =>
                        if (G_USE_PARITY_ODD = true or G_USE_PARITY_EVEN = true) then
                            if i_ena = '1' then
                                if i_sample = '1' and o_reg.sample = '0' then
                                    if (o_reg.fsm = PARITY) then
                                        if ( ((G_USE_PARITY_ODD  = true) and (i_rxd =     f_parity(o_reg.rx_data(0 to G_DATA_WIDTH-1)))) or
                                             ((G_USE_PARITY_EVEN = true) and (i_rxd = not(f_parity(o_reg.rx_data(0 to G_DATA_WIDTH-1)))))) then
                                            V.fsm        := STOP_BIT;
                                            V.parity_err := '0';
                                        else
                                            V.fsm        := IDLE;
                                            V.parity_err := '1';
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;              

                    when STOP_BIT =>
                        if i_ena = '1' then
                            if i_sample = '1' and o_reg.sample = '0' then
                                if (o_reg.fsm = STOP_BIT) then
                                    if (i_rxd = '1') then
                                        V.valid := '1';
                                        if (G_USE_FRAMEIN = true) then
                                            V.framein_err := '0';
                                        end if;
                                        if (G_USE_OVERRUN = true) then
                                            if i_data_accepted = '0' then
                                                V.overrun_err := '1';
                                            else
                                                V.overrun_err := '0';
                                            end if;
                                        end if;
                                        V.fsm := IDLE;
                                    else
                                        V.valid := '0';
                                        if (G_USE_FRAMEIN = true and G_USE_BREAK = false) then
                                             V.framein_err := '1';
                                             V.fsm         := IDLE;
                                        elsif(G_USE_BREAK = true) then
                                             V.framein_err := '0';
                                             V.fsm         := BREAK;
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;


                    when BREAK =>
                        if (G_USE_BREAK = true) then
                            if i_ena = '1' then
                                if i_sample = '1' and o_reg.sample = '0' then
                                    if (o_reg.fsm = BREAK) then
                                        if (i_rxd = '1') then
                                            V.valid := '1';
                                            V.fsm   := STOP_BIT;
                                            V.break := '1';
                                        else
                                            V.valid := '0';
                                            if (G_USE_FRAMEIN = true) then
                                                if o_reg.break_cnt >= const_timeout then --timeout
                                                    V.framein_err := '1';
                                                    V.fsm         := STOP_BIT;
                                                end if;
                                                V.break_cnt  := o_reg.break_cnt +1;
                                            else
                                                V.framein_err := '0';
                                                V.fsm         := BREAK;
                                            end if;
                                            V.break := '0';
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;

                    when others => 
                        V := TYPE_OUT_REG_RST;
                end case;
            end if;
        end if;

        c_to_o_reg <= V;
    end process comb_out_proc;
 
    o_brake         <= o_reg.break;                      -- Break Detected
    o_overrun_err   <= o_reg.overrun_err;                -- Output Error and Signaling
    o_framein_err   <= o_reg.framein_err;                -- Output Error and Signaling
    o_parity_err    <= o_reg.parity_err;                 -- Output Error and Signaling
    o_rx_data       <= o_reg.rx_data;                    -- Output Recieved Data
    o_valid         <= o_reg.valid;

end Behavioral;
