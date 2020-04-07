-------------------------------------------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
-------------------------------------------------------------------------------------------------------------
-- File        : BRG.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : March 10th, 2020
-- Modified    :
-- Changes     :
-------------------------------------------------------------------------------------------------------------
-- Design Unit : BRG.vhd
-- Library     :
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- Description : Full BRG module
--     BRG module is used to give G_SAMPLE_PER_BIT of clk_period width pulses.
--     Puls density depends on number of clk pulses pr bit, given as input to the
--     module on the i_prescaler pin
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


entity BRG is
    generic
    (
        --! Module Reset Level,
        --! Data type: RST_LEVEL(type deined in p_general package), Default value: HL
        G_RST_LEVEVEL    : RST_LEVEL := HL;
        --! Use Sample Input,
        --! Data Type: boolean, Default value: false
        --!      true -> samples from the i_sample input are used to sample data
        --!              i_prescaler is not used, G_SAMPLE_PER_BIT is fixed and should
        --!              corespond to real samples value per bit
        --!      false ->samples are generated in the module based on the i_prescaler
        --!              and G_SAMPLE_PER_BIT values
        G_SAMPLE_USED    : boolean   := false;
        --! Number of samples per one bit,
        --! Data Type: positive, Default value 13
        --! Sampling starts after START bit is detected on the module's input
        G_SAMPLE_PER_BIT : positive  := 13;           --
        --! Data Width,
        --! Data Type: positive, Default value: 8
        G_DATA_WIDTH     : positive  := 8
    );
    port
    (
        --! Input CLOCK
        i_clk              : in  std_logic;
        --! Reset for input clk domain
        i_rst              : in  std_logic;
        -- Input Sample signal
        i_sample           : in  std_logic;
        --! BRG Enable Signal
        --! Starts to give sample bits after enabled
        i_ena              : in  std_logic;
        --! Duration of one bit (expresed in number of clk cycles per bit)
        i_prescaler        : in  std_logic_vector(31 downto 0);
        --! Sample trigger signal
        o_sample           : out std_logic
    );
end BRG;

architecture Behavioral of BRG is
    -- Inputs registered
    type TYPE_BRG_IN is record
        sample     : std_logic;                    -- Sample from the Module's input
        ena        : std_logic;                    -- Enable Module signal
        prescaler  : unsigned(31 downto 0);        -- Duration of one bit (expresed in number of clk cycles per bit)
    end record;

    constant TYPE_BRG_IN_RST : TYPE_BRG_IN := (
        sample     => '0',
        ena        => '0',
        prescaler  => (others => '0'));

    type TYPE_CTRL_REG is record
        sample_num   : integer range 0 to G_SAMPLE_PER_BIT +1; -- number of samples per bit
        clk_per_smpl : unsigned(31 downto 0);                  -- number of clock cycles between the samples
        clk_per_bit  : unsigned(35 downto 0);                  -- number of clock cycles per bit
    end record;

    constant TYPE_CTRL_REG_RST : TYPE_CTRL_REG := (
        sample_num   =>  0,
        clk_per_smpl => (others => '0'),
        clk_per_bit  => (others => '0'));


    type TYPE_BRG_OUT is record
        brs          : std_logic;        -- baud rate sample
    end record;

    constant TYPE_BRG_OUT_RST : TYPE_BRG_OUT := (
        brs          => '0');

    -- constant - zeros used for comparation
    constant zeros    : unsigned(G_DATA_WIDTH-1 downto 0) := (others => '0');

    -- signal - takes High Level if there is active RESET on the module input
    signal s_reset    : std_logic;

    -- signal - Registered inputs to the module
    signal r_in       : TYPE_BRG_IN;
    -- signal - Contains input values to be registered
    signal c_in       : TYPE_BRG_IN;

    -- signal - Registered inputs to the module
    signal r_ctrl     : TYPE_CTRL_REG;
    -- signal - Contains input values to be registered
    signal c_ctrl     : TYPE_CTRL_REG;

    -- signal - Registered inputs to the module
    signal r_out      : TYPE_BRG_OUT;
    -- signal - Contains input values to be registered
    signal c_out      : TYPE_BRG_OUT;

begin

    -- equals '1' if there is active reset on the rst input, otherwise equals '0'
    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';

------------------------------------------------------------------------------------------------
--             Registring Inputs
------------------------------------------------------------------------------------------------

sync_IN_process:
    process(i_clk)
    begin
        if (rising_edge(i_clk)) then
            if(s_reset = '1') then
                r_in <= TYPE_BRG_IN_RST;
            else
                r_in <= c_in;
            end if;
        end if;
    end process sync_IN_process;


comb_IN_process:
    process(r_in, i_sample, i_ena, i_prescaler)
        variable V : TYPE_BRG_IN;
    begin
        V           := r_in;

        V.ena       := i_ena;

        if(G_SAMPLE_USED = true) then
            V.prescaler  := (others => '0');
            if r_in.ena   = '1' then
                V.sample := i_sample;
            end if;
        else
            V.sample    := '0';
            V.prescaler := unsigned(i_prescaler);
        end if;

        c_in <= V;
    end process comb_IN_process;


---------------------------------------------------------
--         Sync process
---------------------------------------------------------
smpl_gen_not_used_ctrl:
if G_SAMPLE_USED = false generate
    sync_CTRL_process:
        process(i_clk)
        begin
            if (rising_edge(i_clk)) then
                if(s_reset = '1') then
                    r_ctrl <= TYPE_CTRL_REG_RST;
                else
                    r_ctrl <= c_ctrl;
                end if;
            end if;
        end process sync_CTRL_process;
end generate smpl_gen_not_used_ctrl;

sync_OUT_process:
    process(i_clk)
    begin
        if (rising_edge(i_clk)) then
            if(s_reset = '1') then
                r_out <= TYPE_BRG_OUT_RST;
            else
                r_out <= c_out;
            end if;
        end if;
    end process sync_OUT_process;

---------------------------------------------------------
--  Comb process when input sample signal is used
---------------------------------------------------------
smpl_gen_not_used:
if G_SAMPLE_USED = true generate
    comb_OUT_process:
    process(r_ctrl, r_in)
--    process(r_ctrl.brs, r_ctrl.sample_num, r_ctrl.clk_per_smpl, i_sample, i_ena)
        variable V : TYPE_BRG_OUT;
    begin
        V     := r_out;

        if r_in.ena = '1' then
            V.brs := r_in.sample;
        end if;

        c_out <= V;
    end process comb_OUT_process;
end generate smpl_gen_not_used;


---------------------------------------------------------
--  Comb process when input sample signal is not used
---------------------------------------------------------
smpl_gen_used:
if G_SAMPLE_USED = false generate
    comb_process:
--        process(r_out, r_ctrl, r_in)
    process(r_out.brs,
            r_ctrl.sample_num ,r_ctrl.clk_per_smpl ,r_ctrl.clk_per_bit,
            r_in.prescaler , r_in.ena )
        variable V_ctrl : TYPE_CTRL_REG;
        variable V_out  : TYPE_BRG_OUT;
    begin
        -- assign registered values to the variable
        V_ctrl   := r_ctrl;
        V_out    := r_out;

        -- i_prescaler / G_SAMPLE_PER_BIT
        V_ctrl.clk_per_smpl := (r_in.prescaler/(G_SAMPLE_PER_BIT +1));
        if  V_ctrl.clk_per_smpl = zeros then
            -- i_prescaler / 2
            V_ctrl.clk_per_smpl := r_in.prescaler srl 1;
        end if;

        V_out.brs := '0';
        if r_in.ena = '1' then

            V_ctrl.clk_per_bit := r_ctrl.clk_per_bit +1;
            if (r_ctrl.clk_per_bit = r_in.prescaler) then
                 V_ctrl.clk_per_bit := (others => '0');
                 V_ctrl.sample_num  :=  0;
				else
                V_ctrl.sample_num  := r_ctrl.sample_num  +1;
                if (r_ctrl.sample_num = to_integer(r_ctrl.clk_per_smpl)) then
                    V_out.brs := '1';
                    V_ctrl.sample_num :=  0;
                end if;
            end if;
        end if;

        c_ctrl <= V_ctrl;
        c_out  <= V_out;
    end process comb_process;
end generate smpl_gen_used;

-------------------------------------------------------------------------------------------------------
--                             OUPUTS
-------------------------------------------------------------------------------------------------------
    o_sample <= r_out.brs;

end Behavioral;
