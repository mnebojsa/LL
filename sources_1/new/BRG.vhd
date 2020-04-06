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
        i_prescaler        : in  unsigned(31 downto 0);
        --! Sample trigger signal
        o_sample           : out std_logic
    );
end BRG;

architecture Behavioral of BRG is

    type TYPE_BRG_REG is record
        brs        : std_logic;                              -- baud rate sample
        cnt        : integer range 0 to G_SAMPLE_PER_BIT +1; --
        sample_cnt : unsigned(31 downto 0);                  --
    end record;

    constant TYPE_BRG_REG_RST : TYPE_BRG_REG :=
    (
        brs        => '0',
        cnt        =>  0,
        sample_cnt => (others => '0')
    );

    -- constant - zeros used for comparation
    constant zeros    : unsigned(G_DATA_WIDTH-1 downto 0) := (others => '0');

    -- signal - takes High Level if there is active RESET on the module input
    signal s_reset    : std_logic;
    -- signal - Registered inputs to the module
    signal r_brd      : TYPE_BRG_REG;
    -- signal - Contains input values to be registered
    signal c_brd      : TYPE_BRG_REG;

begin

    -- equals '1' if there is active reset on the rst input, otherwise equals '0'
    s_reset <= '1' when ((G_RST_LEVEVEL = HL and i_rst = '1') or (G_RST_LEVEVEL = LL and i_rst = '0'))
                   else '0';

---------------------------------------------------------
--         Sync process
---------------------------------------------------------
synchronus_BRG_process:
    process(i_clk)
    begin
        if (rising_edge(i_clk)) then
            if(s_reset = '1') then
                r_brd <= TYPE_BRG_REG_RST;
            else
                r_brd <= c_brd;
            end if;
        end if;
    end process synchronus_BRG_process;


---------------------------------------------------------
--  Comb process when input sample signal is used
---------------------------------------------------------
smpl_gen_not_used:
if G_SAMPLE_USED = true generate
    comb_process:
    process(r_brd, i_sample, i_ena)
--    process(r_brd.brs, r_brd.cnt, r_brd.sample_cnt, i_sample, i_ena)
        variable V : TYPE_BRG_REG;
    begin
        V     := r_brd;

        if i_ena = '1' then
            V.brs := i_sample;
        end if;

        c_brd <= V;
    end process comb_process;
end generate smpl_gen_not_used;


---------------------------------------------------------
--  Comb process when input sample signal is not used
---------------------------------------------------------
smpl_gen_used:
if G_SAMPLE_USED = false generate
    comb_process:
--        process(r_brd.brs, r_brd.cnt, r_brd.sample_cnt, i_prescaler, i_ena)
        process(r_brd, i_prescaler, i_ena)
            variable V : TYPE_BRG_REG;
        begin
            -- assign registered values to the variable
            V   := r_brd;

            if  V.sample_cnt = zeros then
                -- i_prescaler / 2
                V.sample_cnt := i_prescaler srl 2;
            else
                -- i_prescaler / G_SAMPLE_PER_BIT
                V.sample_cnt := i_prescaler / G_SAMPLE_PER_BIT;  --i_prescaler srl G_SAMPLE_PER_BIT;-- 
            end if;

            if i_ena = '1' then
                if r_brd.sample_cnt /= 0 then
                    if (r_brd.cnt = to_integer(r_brd.sample_cnt)) then
                        V.brs := '1';
                        V.cnt :=  0;
                    else
                        V.brs := '0';
                        V.cnt := r_brd.cnt +1;
                    end if;
                end if;
            end if;

            c_brd <= V;
        end process comb_process;
end generate smpl_gen_used;

-------------------------------------------------------------------------------------------------------
--                             OUPUTS
-------------------------------------------------------------------------------------------------------
    o_sample <= r_brd.brs;

end Behavioral;
