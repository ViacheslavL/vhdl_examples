library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

PACKAGE array_package IS
	TYPE my_type is ARRAY ( 11 downto 0) OF std_logic_vector (7 downto 0);
END array_package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.array_package.all;
use ieee.numeric_std.all;

entity tx_control is
port(
	clk_25 : in std_logic;
	d_fifo : in std_logic_vector (7 downto 0);
	empty  : in std_logic;
	usedw  : in std_logic_vector (5 downto 0);
	data   : out std_logic_vector (7 downto 0);
	clk_out: out std_logic;
	read_v : out std_logic
	);
end tx_control;

architecture rtl of tx_control is
type state is (waiting, count, send_header, send_length, send_data, data_send_skip, send_tail,read_data);
	signal fsm_states: state := waiting;
signal clk_2   : std_logic;

begin
	
	process(clk_25)
		
	begin
		if clk_25'event and clk_25 = '1' then

			if clk_2 = '1' then clk_2 <= '0';
			else 
				clk_2 <= '1';
			end if;
			
		end if;
	end process;
	
	
	process(clk_25)
		variable max_data : std_logic_vector (3 downto 0);
		variable cur_data : integer range 15 downto 0 := 0;
		variable reg_fifo: my_type;
		variable timer: integer range 250000 downto 0 := 0 ;
		variable waiter : integer range 1 downto 0:=0;
		variable sub: integer range 12 downto 0:= 0;
	begin
		if clk_25'event and clk_25 = '1' then
			
			case fsm_states is 
				when count =>
					timer := 0;
					cur_data:= 0;
					if usedw >= 11 then 
						max_data := "1011";
						fsm_states <= read_data;
					else 
						max_data(3 downto 0) := usedw(3 downto 0);
						fsm_states <= read_data;
	  				end if;
	  				if max_data = 1 then 
						read_v <= '0';
					end if;
	  		
				when read_data =>
					reg_fifo(cur_data) := d_fifo;
					cur_data := cur_data + 1;
					if cur_data = max_data - 1 then
						read_v <= '0';
					end if;
 					if cur_data >= max_data then
						fsm_states <= send_header;
					end if;
				
				when send_header =>
					read_v <= '0';
					data <= "11111111";
					if waiter = 1 then 
						waiter := 0;
						fsm_states <= send_length;
					else waiter := waiter + 1;
					end if;
				when send_length =>
					data <= "0000" & max_data ;
						
					cur_data := 0;
					if waiter = 1 then 
						waiter := 0;
						if max_data > 0 then fsm_states <= send_data;
						else fsm_states <= send_tail;
						end if;
					else waiter := waiter + 1;
					end if;
				when send_data =>
						waiter := 0;
						data <= reg_fifo(cur_data);
						cur_data := cur_data + 1;
						fsm_states <= data_send_skip;
						
				when data_send_skip =>
					if cur_data >= max_data then
						fsm_states <= send_tail;
					else fsm_states <= send_data;
					end if;
					
				when send_tail =>
					timer := timer + cur_data + 4;
					data <= "10001111";
					if waiter = 1 then 
						waiter := 0;
						fsm_states <= waiting;
					else 
						waiter := waiter + 1;
					end if;
					
				when others =>
					data <= "00000000";
					timer := timer + 1;
					if usedw > 11 then sub:= 11;
						else sub := to_integer(unsigned(usedw));
					end if;
					if timer >= 50 - sub then
						timer := 0;
						read_v <= '1';
						fsm_states <= count;
					end if;
			end case;
		end if;
	end process;
	clk_out <= clk_2;
end rtl;

			