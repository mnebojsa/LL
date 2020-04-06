library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.p_general.all;


entity BRG_tb is
    generic
    (
        G_RST_LEVEVEL      : RST_LEVEL := HL;
        G_SAMPLE_USED      : boolean   := true;
        G_SAMPLE_PER_BIT   : positive  := 13;
        G_DATA_WIDTH       : positive  := 8
    );
end;

architecture bench of BRG_tb is

  component BRG
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
  end component;

  signal i_clk       : std_logic;
  signal i_rst       : std_logic;
  signal i_sample    : std_logic;
  signal i_ena       : std_logic;
  signal i_prescaler : unsigned(31 downto 0) := "00000000000000000000000001111101"; --125
  signal o_sample    : std_logic;

  constant clock_period: time := 10 ns;

begin

  -- Insert values for generic parameters !!
  uut:
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
      i_clk         => i_clk,
      i_rst         => i_rst,
      i_sample      => i_sample,
      i_ena         => i_ena,
      i_prescaler   => i_prescaler,
      o_sample      => o_sample
  );


  st: process
  begin

 -- Put initialisation code here
    i_rst  <= '1';
    i_ena  <= '0';
 -- Put test bench stimulus code here
        wait for clock_period * 10;
    i_rst <= '0';
        wait for clock_period * 10;
    i_ena <= '1';
        wait for clock_period * 10000;
  end process;


  process
  begin
      i_clk <= '0';
          wait for clock_period/2;
      i_clk <= '1';
          wait for clock_period/2;
  end process;

  stimulus: process
  begin

    -- Put initialisation code here
    for i in 0 to 20 loop
        i_sample <= '1';
            wait for 10 ns;
        i_sample <= '0';
            wait for 30 ns;
    end loop;

    -- Put test bench stimulus code here

    wait;
  end process;


end;