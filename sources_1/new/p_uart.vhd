library ieee;
use ieee.std_logic_1164.all;

package p_uart_interface is

type RST_LEVEL is (HL, LL);
type LSB_MSB   is (LSB , MSB);


  type TYPE_UART_RX_EVENT is record
    overrun_err_o     : std_logic;
    undderrun_err_o   : std_logic;
    frameing_err_o    : std_logic;
    parity_err_o      : std_logic;
    break_condition_o : std_logic;
  end record;

  constant CONST_TYPE_UART_RX_EVENT_RESET : TYPE_UART_RX_EVENT := (
    overrun_err_o     => '0',
    undderrun_err_o   => '0',
    frameing_err_o    => '0',
    parity_err_o      => '0',
    break_condition_o => '0'
    );

  type TYPE_UART_RX_EVENT_ARRAY is array (natural range <>) of TYPE_UART_RX_EVENT;

--  subtype std_logic_vector2 is std_logic_vector(1 downto 0);
--  function to_std_logic_vector(mii_speed : TYPE_MII_SPEED) return std_logic_vector2;
--  function to_TYPE_MII_SPEED(s_in           : std_logic_vector2) return TYPE_MII_SPEED;

component uart_rx is
    generic(
        G_DATA_WIDTH  : integer   := 8;
        G_RST_LEVEVEL : RST_LEVEL := HL;
		G_LSB_MSB     : LSB_MSB   := LSB;
        G_USE_BREAK   : boolean   := true;
        G_USE_OVERRUN : boolean   := false;
        G_USE_FRAMEIN : boolean   := false;
        G_USE_PARITY  : boolean   := false
    );
    port   (
        i_clk           : in  std_logic;                      -- Input CLOCK
        i_rst           : in  std_logic;                      -- Input Reset for clk
        i_sample        : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_ena           : in  std_logic;                      -- Input Uart Enable Signal
        i_rxd           : in  std_logic;                      -- Input Reciveve Data bus Line
        o_brake         : out std_logic;                      -- Break Detected
        o_overrun_err   : out std_logic;                      -- Output Error and Signaling
        o_framein_err   : out std_logic;                      -- Output Error and Signaling
        o_parity_err    : out std_logic;                      -- Output Error and Signaling
        o_rx_data       : out std_logic_vector(G_DATA_WIDTH-1 downto 0); -- Output Recieved Data
        o_valid         : out std_logic
    );
end component;




end package;

package body p_uart_interface is

--  -- TYPE_MII_SPEED -> std_logic_vector
--  function to_std_logic_vector(mii_speed : TYPE_MII_SPEED) return std_logic_vector2 is
--    variable ret : std_logic_vector2;
--  begin
--    case mii_speed is
--      when SP_10   => ret := "00";
--      when SP_100  => ret := "01";
--      when SP_1000 => ret := "10";
--    end case;
--    return ret;
--  end function;
--  -- std_logic_vector -> TYPE_MII_SPEED
--  function to_TYPE_MII_SPEED(s_in : std_logic_vector2) return TYPE_MII_SPEED is
--    variable mii_speed : TYPE_MII_SPEED;
--  begin
--    case s_in is
--      when "00"   => mii_speed := SP_10;
--      when "01"   => mii_speed := SP_100;
--      when others => mii_speed := SP_1000;
--    end case;
--    return mii_speed;
--  end function;

end package body;
