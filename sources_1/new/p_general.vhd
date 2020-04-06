----------------------------------------------------------------------------
-- Company     : RT-RK
-- Project     :
----------------------------------------------------------------------------
-- File        : uart_rx.vhd
-- Author(s)   : Nebojsa Markovic
-- Created     : April 6th, 2020
-- Modified    :
-- Changes     :
---------------------------------------------------------------------------
-- Design Unit : uart_rx.vhd
-- Library     :
---------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- Description : Full UART_RX module
--
--
--
----------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package p_general is
    --! Used to select High(HL) ot Low(LL) Reset Level for the module
    type RST_LEVEL is (HL, LL);
    --! Used to choose LSB or MSB data expected on the rxd input
    type LSB_MSB   is (LSB , MSB);
    --! Used PARITY type
    type U_PARITY  is (NONE, EVEN, ODD);

end package;

package body p_general is

end package body;
