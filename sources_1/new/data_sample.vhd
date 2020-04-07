-------------------------------------------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
-------------------------------------------------------------------------------------------------------------
-- File        : data_sample.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : March 10th, 2020
-- Modified    :
-- Changes     :
-------------------------------------------------------------------------------------------------------------
-- Design Unit : data_sample.vhd
-- Library     :
-------------------------------------------------------------------------------------------------------------
-- Description : Full data_sample module
--     data_sample module is used to sample input data G_SAMPLE_PER_BIT times,
--     after which output value is decided.
--     Output signal has one bit duration latency
----------------------------------------------------------------------------------------------------------------
-- Dependencies:
--     BRG.vhd
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

entity data_sample is
    generic
     (
        --! Module Reset Level,
        --! Data type: RST_LEVEL(type deined in p_general package), Default value: HL
        G_RST_LEVEVEL      : RST_LEVEL     := HL;
        --! Use Sample Input,
        --! Data Type: boolean, Default value: false
        --!      true -> samples from the i_sample input are used to sample data
        --!              i_prescaler is not used, G_SAMPLE_PER_BIT is fixed and should
        --!              corespond to real samples value per bit
        --!      false ->samples are generated in the module based on the i_prescaler
        --!              and G_SAMPLE_PER_BIT values
        G_SAMPLE_USED      : boolean       := false;
        --! Number of samples per one bit,
        --! Data Type: positive, Default value 13
        --! Sampling starts after START bit is detected on the module's input
        G_SAMPLE_PER_BIT   : positive      := 13;
        --! Data Width,
        --! Data Type: positive, Default value: 8
        G_DATA_WIDTH       : positive      := 8
    );
    port
     (
        --! Input CLOCK
        i_clk              : in  std_logic;
        --! Reset for input clk domain
        i_rst              : in  std_logic;
        --! Input Sample signal
        i_sample           : in  std_logic;
        --! Module Enable Signal
        --! Starts to sample i_rxd after enabled
        i_ena              : in  std_logic;
        --! Duration of one bit (expresed in number of clk cycles per bit)
        i_prescaler        : in  std_logic_vector(31 downto 0);
        --! Input Reciveve Data Bus Line
        i_rxd              : in  std_logic;
        --! Valid Data on the output
        o_valid            : out std_logic;
        --! Outpu Data value
        o_rxd              : out std_logic
    );
end data_sample;

architecture Behavioral of data_sample is

    -- Inputs registered
    type TYPE_IN_REG is record
        sample      : std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        ena         : std_logic;                      -- Input Uart Enable Signal
        rxd         : std_logic;                      -- Input Reciveve Data bus Line
        prescaler   : std_logic_vector(31 downto 0);
    end record;

    -- Reset Values for TYPE_IN_REG type data
    constant TYPE_IN_REG_RST : TYPE_IN_REG := (
        sample       => '0',
        ena          => '0',
        rxd          => '0',
        prescaler    => (others => '0'));

    -- Control registered
    type TYPE_CTRL_REG is record
        sample      : std_logic;                                -- registere sample signal
        sample_1s   : integer range 0 to (G_SAMPLE_PER_BIT +1); -- number of samples equal to '1' in one bit duration
        sample_0s   : integer range 0 to (G_SAMPLE_PER_BIT +1); -- number of samples equal to '0' in one bit duration
    end record;

    -- Reset Values for TYPE_CTRL_REG type data
    constant TYPE_CTRL_REG_RST : TYPE_CTRL_REG := (
        sample       => '0',
        sample_1s    =>  0,
        sample_0s    =>  0);

    -- Outputs registered
    type TYPE_OUT_REG is record
        valid        : std_logic; -- valid registered signal value (after sampling of the input)
        rxd          : std_logic; -- sampled input bus value
    end record;

    -- Reset Values for TYPE_IN_REG type data
    constant TYPE_OUT_REG_RST : TYPE_OUT_REG := (
        valid        => '0',
        rxd          => '0');

    -- signal
    signal s_sample   : std_logic;
    -- signal - takes High Level if there is active RESET on the module input
    signal s_reset    : std_logic;
    -- signal - Registered inputs to the module
    signal r_in      : TYPE_IN_REG;
    -- signal - Contains input values to be registered
    signal c_in      : TYPE_IN_REG;

    -- signal - Registered inputs to the module
    signal r_ctrl    : TYPE_CTRL_REG;
    -- signal - Contains input values to be registered
    signal c_ctrl    : TYPE_CTRL_REG;

    -- signal - Registered inputs to the module
    signal r_out     : TYPE_OUT_REG;
    -- signal - Contains input values to be registered
    signal c_out     : TYPE_OUT_REG;

begin

    -- equals '1' if there is active reset on the rst input, otherwise equals '0'
    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';


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
    process(r_in, i_ena, i_rxd, i_prescaler, i_sample)
        variable V         : TYPE_IN_REG;
    begin
        V           := r_in;

        V.sample    := '0';
        if (G_SAMPLE_USED = true) then
            V.sample    := i_sample;
        end if;

        V.ena       := i_ena;
        V.prescaler := i_prescaler;

        V.rxd       := '1';
        if(r_in.ena = '1') then
            V.rxd       := i_rxd;
        end if;

        c_in <= V;
    end process comb_in_proc;

-------------------------------------------------------------------------------------------------------
--        Registring Control and Outputs
-------------------------------------------------------------------------------------------------------
-- If RST is active assign reset value to r_in,
-- else, register c_in value as r_in
reg_out_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_out       <= TYPE_OUT_REG_RST;
            else
                r_out       <= c_out;
            end if;
        end if;
    end process reg_out_proc;

reg_ctrl_proc:
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if(s_reset = '1') then
                r_ctrl      <= TYPE_CTRL_REG_RST;
            else
                r_ctrl      <= c_ctrl;
            end if;
        end if;
    end process reg_ctrl_proc;



comb_out_proc:
    process(r_in, r_out, r_ctrl, s_sample)
        variable V_ctrl      : TYPE_CTRL_REG;
        variable V_out       : TYPE_OUT_REG;
    begin
        V_ctrl     := r_ctrl;
        V_out      := r_out;

        V_ctrl.sample   := s_sample;
        V_out.valid     := '0';

        if s_sample = '1' and r_ctrl.sample = '0' then
            if (r_in.rxd = '1') then
                V_ctrl.sample_1s:= r_ctrl.sample_1s +1;
            else
                V_ctrl.sample_0s:= r_ctrl.sample_0s +1;
            end if;
        end if;

        if (r_ctrl.sample_1s + r_ctrl.sample_0s = G_SAMPLE_PER_BIT) then
            if (r_ctrl.sample_1s >= r_ctrl.sample_0s) then
                V_out.rxd      := '1';
            else
                V_out.rxd      := '0';
            end if;
            V_out.valid      := '1';
            V_ctrl.sample_1s :=  0;
            V_ctrl.sample_0s :=  0;
        end if;
        -- Assign valuses that should be registered
        c_ctrl <= V_ctrl;
        c_out  <= V_out;
    end process comb_out_proc;



-------------------------------------------------------------------------------------------------------
--        BRG Instance
-------------------------------------------------------------------------------------------------------
BRG_inst_0:
    BRG
    generic map
    (
        G_RST_LEVEVEL    => G_RST_LEVEVEL,
        G_SAMPLE_USED    => G_SAMPLE_USED,
        G_SAMPLE_PER_BIT => G_SAMPLE_PER_BIT,
        G_DATA_WIDTH     => G_DATA_WIDTH
    )
    port map
    (
        i_clk            => i_clk,            -- Input CLOCK
        i_rst            => i_rst,            -- Input Reset for clk
        i_sample         => r_in.sample,      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_ena            => r_in.ena,         -- Input Uart Enable Signal
        i_prescaler      => r_in.prescaler,   -- Number of clock cycles in one bit
        o_sample         => s_sample          -- Sample signal
    );


-------------------------------------------------------------------------------------------------------
--        Outputs Assigment
-------------------------------------------------------------------------------------------------------
    o_valid       <= r_out.valid;
    o_rxd         <= r_out.rxd;

end Behavioral;