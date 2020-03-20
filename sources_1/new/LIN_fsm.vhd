----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2020 17:24:40
-- Design Name: 
-- Module Name: LIN_fsm - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
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

entity LIN_fsm is
    generic(
        G_DATA_LEN    : integer := 8;
        G_RST_ACT_LEV : boolean := true
    );
    port   (
        i_clk           : in  std_logic;                      -- Input CLOCK
        i_rst           : in  std_logic;                      -- Input Reset for clk
        i_valid_data    : in  std_logic;                      -- Input Sample signal - comes from BAUD RATE GENERATOR- signal to sample input
        i_brake         : in  std_logic;                      -- Break Detected
        i_rxd           : in  std_logic_vector(0 to G_DATA_LEN -1); -- Input Reciveve Data bus Line
        i_err           : in  std_logic;                      -- Output Error and Signaling
        o_rx_data       : out std_logic_vector(0 to G_DATA_LEN -1); -- Output Recieved Data
        o_valid         : out std_logic;
        o_to_mit        : out std_logic
    );
end LIN_fsm;

architecture Behavioral of LIN_fsm is

    type TYPE_LIN_FSM is (IDLE, BREAK, SYNC, PID, DATA, CHECKSUM, LIN_ERR);

    type TYPE_FSM_REG is record
        break    : std_logic;
        err      : std_logic_vector(3 downto 0);
        data     : std_logic_vector(0 to G_DATA_LEN -1);
        valid    : std_logic;
        fsm      : TYPE_LIN_FSM;
        cnt      : integer range 0 to 15;
    end record;

    constant TYPE_FSM_REG_RST : TYPE_FSM_REG := (
        break        => '0',
        err          => (others => '0'),
        data         => (others => '0'),
        valid        => '0',
        fsm          => IDLE,
        cnt          => 0);

    signal s_reset              : std_logic;

    signal r_lin_fsm, c_lin_fsm : TYPE_FSM_REG;



  function f_check_parity(data : std_logic_vector(7 downto 0)) return boolean is
    variable ret : boolean;
  begin
        ret :=( data(6) = ( data(0) xor data(1) xor data(2) xor data(4))) and (data(7) = not(data(1) xor data(3) xor data(4) xor data(5) )) ;
    return ret;
  end function;

    function f_valid_id(data : std_logic_vector(G_DATA_LEN -1 downto 0)) return std_logic is
        variable ret : std_logic;  
    begin
        ret := '1';
        return ret;
    end function;

begin

    s_reset <= '1' when ((G_RST_ACT_LEV = true and i_rst = '1'))
                   else '0';

LIN_fsm_syn_proc:
    process(i_clk)
    begin
        if(s_reset = '1') then
            r_lin_fsm <= TYPE_FSM_REG_RST;
        else
            r_lin_fsm <= c_lin_fsm;
        end if;    
    end process;


LIN_fsm_comb_proc:
    process(r_lin_fsm.break , r_lin_fsm.err , r_lin_fsm.data , r_lin_fsm.valid , r_lin_fsm.fsm , r_lin_fsm.cnt,
            i_brake, i_valid_data)
        variable V : TYPE_FSM_REG;
    begin
        V := r_lin_fsm;

        case (r_lin_fsm.fsm) is
            when IDLE      =>
                if i_brake = '1' then
                    V.fsm := BREAK;
                end if;
            when BREAK     =>
                if i_brake = '0' then
                    V.fsm := SYNC;
                end if;
            when SYNC      =>
                if i_valid_data = '1' then
                    if i_rxd = x"55" then
                        V.fsm := PID;
                    else
                        V.fsm := LIN_ERR;
                    end if;
                end if;
            when PID       =>
                if i_valid_data = '1' then
                    if f_valid_id(i_rxd) = '1' then
                        if f_check_parity(i_rxd) = true then
                            V.fsm := DATA;
                        else
                            V.fsm := LIN_ERR;
                        end if;
                    else
                        V.fsm := IDLE;
                    end if;
                end if;
            when DATA      =>
                if i_valid_data = '1' then
                    -- if f_valid_id(i_rxd) = '1' then
                        -- c_lin_fsm.fsm <= DATA;
                    -- else
                      --   c_lin_fsm.fsm <= IDLE;
                    -- end if;
                end if;
            when CHECKSUM  =>
                if i_valid_data = '1' then
                   -- if f_valid_id(i_rxd) = '1' then
                       -- c_lin_fsm.fsm <= DATA;
                   -- else
                     --   c_lin_fsm.fsm <= IDLE;
                   -- end if;
                end if; 
            when LIN_ERR   =>                       
        end case; 
        
        c_lin_fsm <= V;  
    end process;

    o_rx_data <= r_lin_fsm.data;

end Behavioral;

