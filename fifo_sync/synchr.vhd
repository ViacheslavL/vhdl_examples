library ieee;
use ieee.std_logic_1164.all;

entity synchr is
port(
	clk_25 : in std_logic;
	data_in: in std_logic_vector (7 downto 0);
	clk    : in std_logic;
	data   : out std_logic_vector (7 downto 0);
	wrreq  : out std_logic 
	);
end synchr;

architecture rtl of synchr is
type state is (writing, waiting);
	signal fsm_states: state := waiting;
begin
	process(clk_25)
	variable count: integer range 4 downto 0 := 0;
	begin
		if clk_25'event and clk_25 = '1' then
				count := count + 1;
				if count = 3 and clk = '1' then fsm_states <= writing;
					else fsm_states <= waiting;
				end if;
				if count = 4 then count := 0;
				end if;
		end if;
	end process;
	data <= data_in;
--	wrreq <= '1';
	with fsm_states select
		wrreq <= '1' when writing,
			     '0' when waiting;
end rtl;