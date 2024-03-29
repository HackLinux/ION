--------------------------------------------------------------------------------
-- ION_INTERNAL_PKG.vhdl -- Configuration constants, utility types & functions.
--------------------------------------------------------------------------------
-- For use within the core component modules only.
-- Modules instantiating an ion_core entity do not need this package.
--------------------------------------------------------------------------------
-- FIXME Plenty of remnants from the old ION version, refactor!
--------------------------------------------------------------------------------
-- This source file may be used and distributed without         
-- restriction provided that this copyright statement is not    
-- removed from the file and that any derivative work contains  
-- the original copyright notice and the associated disclaimer. 
--                                                              
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--                                                              
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--                                                              
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.opencores.org/lgpl.shtml
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.ION_INTERFACES_PKG.all;

package ION_INTERNAL_PKG is

---- Basic types ---------------------------------------------------------------

subtype t_halfword is std_logic_vector(15 downto 0);
subtype t_byte is std_logic_vector(7 downto 0);
subtype t_pc is std_logic_vector(31 downto 2);

subtype t_regindex is std_logic_vector(4 downto 0);

---- Interface types -----------------------------------------------------------

type t_cpumem_mosi is record
    addr :              t_word;
    rd_en :             std_logic;
    wr_be :             std_logic_vector(3 downto 0);
    wr_data :           t_word;
end record t_cpumem_mosi;

type t_cpumem_miso is record
    rd_data :           t_word;
    mwait :             std_logic;
end record t_cpumem_miso;

type t_cache_mosi is record
    function_code :     std_logic_vector(2 downto 0);
    function_en :       std_logic;  -- 1 to perform function_code operation.
    data_cache :        std_logic;  -- 1 to operate on D-cache, 0 for I-Cache.
end record t_cache_mosi;

type t_cache_miso is record
    present :           std_logic;  -- Hardwired to 1 when cache is present.
end record t_cache_miso;

type t_cop0_mosi is record
    index :             t_regindex;
    we :                std_logic;
    data :              t_word;
    pc_restart :        t_pc;
    in_delay_slot :     std_logic;
    pipeline_stalled :  std_logic;
    exception :         std_logic;
    hw_irq :            std_logic;
    hw_irq_reg :        std_logic_vector(7 downto 2);
    eret :              std_logic;
    rfe :               std_logic;
    unknown_opcode :    std_logic;
    missing_cop :       std_logic;
    syscall :           std_logic;
    stall :             std_logic;
end record t_cop0_mosi;

type t_cop0_miso is record
    data :              t_word;
    pc_load_en :        std_logic;
    pc_load_value :     t_pc;
    hw_irq_enable_mask: std_logic_vector(5 downto 0);
    global_irq_enable : std_logic;
    kernel :            std_logic;
end record t_cop0_miso;

---- System configuration constants --------------------------------------------

-- True to use standard-ish MIPS-1 memory map, false to use Plasma's
-- (see implementation of function decode_addr_old below).
constant USE_MIPS1_ADDR_MAP : boolean := true;

-- Reset vector address.
constant RESET_VECTOR : t_word                  := X"bfc00000";

-- General exception vector address.
constant GENERAL_EXCEPTION_VECTOR : t_word      := X"bfc00180";

-- Object code in bytes, i.e. as read from a binary or HEX file.
-- This type is used to define BRAM init constants from external scripts.
type t_obj_code is array(integer range <>) of std_logic_vector(7 downto 0);

-- Types used to define memories for synthesis or simulation.
type t_word_table is array(integer range <>) of t_word;
type t_hword_table is array(integer range <>) of t_halfword;
type t_byte_table is array(integer range <>) of t_byte;

---- Object code management -- initialization helper functions -----------------

-- Dummy t_obj_code constant, to be used essentially as a syntactic placeholder.
constant default_object_code : t_obj_code(0 to 3) := (
    X"00", X"00", X"00", X"00"
    );

-- Build t_obj_code if given size (in bytes) filled with zeros.
function zero_objcode(size : integer) return t_obj_code;
    
-- Builds BRAM initialization constant from a constant CONSTRAINED byte array
-- containing the application object code.
-- The constant is a 32-bit, big endian word table.
-- The object code is placed at the beginning of the BRAM and the rest is
-- filled with zeros.
-- The object code is truncated if it doesn't fit the given table size.
-- CAN BE USED IN SYNTHESIZABLE CODE to compute a BRAM initialization constant 
-- from a constant argument.
function objcode_to_wtable(oC : t_obj_code; size : integer) return t_word_table;

-- Builds BRAM initialization constant from a constant CONSTRAINED byte array
-- containing the application object code.
-- The constant is a 16-bit, big endian word table.
-- The object code is placed at the beginning of the BRAM and the rest is
-- filled with zeros.
-- The object code is truncated if it doesn't fit the given table size.
-- CAN BE USED IN SYNTHESIZABLE CODE to compute a BRAM initialization constant 
-- from a constant argument.
function objcode_to_htable(oC : t_obj_code; size : integer) return t_hword_table;

-- Builds BRAM initialization constant from a constant CONSTRAINED byte array
-- containing the application object code.
-- It will put the whole object code into a byte table if slice=-1, otherwise
-- it will extract the selected slice (0 to 3) and put only that in the table.
-- If slice = -1, the size is that fo the whole data block.
-- If slice >= 0, the size is that of the slice, i.e. 1/4 of the block size. 
-- The constant is an 8-bit byte table in BIG ENDIAN format.
-- Slice 0 is the lowest byte, slice 3 is the highest byte.
-- The object code is placed at the beginning of the BRAM and the rest is
-- filled with zeros.
-- The object code is truncated if it doesn't fit the given table size.
-- CAN BE USED IN SYNTHESIZABLE CODE to compute a BRAM initialization constant 
-- from a constant argument.
function objcode_to_btable(oC : t_obj_code; size : integer; 
                           slice : integer := -1) return t_byte_table;


---- More basic types and constants --------------------------------------------

subtype t_addr is std_logic_vector(31 downto 0);
subtype t_dword is std_logic_vector(63 downto 0);
subtype t_regnum is std_logic_vector(4 downto 0);
type t_rbank is array(0 to 31) of t_word;
-- This is used as a textual shortcut only
constant ZERO : t_word := (others => '0');
-- control word for ALU
type t_alu_control is record
    logic_sel :         std_logic_vector(1 downto 0);
    shift_sel :         std_logic_vector(1 downto 0);
    shift_amount :      std_logic_vector(4 downto 0);
    neg_sel :           std_logic_vector(1 downto 0);
    use_arith :         std_logic;
    use_logic :         std_logic_vector(1 downto 0);
    cy_in :             std_logic;
    use_slt :           std_logic;
    arith_unsigned :    std_logic;
end record t_alu_control;
-- Flags coming from the ALU
type t_alu_flags is record
    inp1_lt_zero :      std_logic;
    inp1_eq_zero :      std_logic;
    inp1_lt_inp2 :      std_logic;
    inp1_eq_inp2 :      std_logic;
end record t_alu_flags;

-- Debug info output by sinthesizable MPU core; meant to debug the core itself, 
-- not to debug software!
type t_debug_info is record
    cache_enabled :     std_logic;
    unmapped_access :   std_logic;
end record t_debug_info;


-- 32-cycle mul/div module control. Bits 4-3 & 1-0 of IR.
subtype t_mult_function is std_logic_vector(3 downto 0);
constant MULT_NOTHING       : t_mult_function := "0000";
constant MULT_MADDU         : t_mult_function := "0101"; -- 5
constant MULT_MADD          : t_mult_function := "0100"; -- 4
constant MULT_READ_LO       : t_mult_function := "1010"; -- 18
constant MULT_READ_HI       : t_mult_function := "1000"; -- 16
constant MULT_WRITE_LO      : t_mult_function := "1011"; -- 19
constant MULT_WRITE_HI      : t_mult_function := "1001"; -- 17
constant MULT_MULT          : t_mult_function := "1101"; -- 25
constant MULT_SIGNED_MULT   : t_mult_function := "1100"; -- 24
constant MULT_DIVIDE        : t_mult_function := "1111"; -- 26
constant MULT_SIGNED_DIVIDE : t_mult_function := "1110"; -- 27

-- Computes ceil(log2(A)), e.g. address width of memory block
-- CAN BE USED IN SYNTHESIZABLE CODE as long as called with constant arguments
function log2(A : natural) return natural;

end package;

package body ION_INTERNAL_PKG is

function log2(A : natural) return natural is
begin
    for I in 1 to 30 loop -- Works for up to 32 bit integers
        if(2**I >= A) then 
            return(I);
        end if;
    end loop;
    return(30);
end function log2;


function zero_objcode(size : integer) return t_obj_code is
variable oc : t_obj_code(0 to size-1) := (others => X"00");
begin
    return oc;
end function zero_objcode;

function objcode_to_wtable(oC : t_obj_code; 
                           size : integer) 
                           return t_word_table is
variable br : t_word_table(integer range 0 to size/4-1):=(others => X"00000000");
variable i, address, index : integer;
begin
    
    -- Copy object code to start of BRAM...
    i := 0;
    for i in 0 to oC'length-1 loop
        case i mod 4 is
        when 0 =>       index := 24;
        when 1 =>       index := 16;
        when 2 =>       index := 8;
        when others =>  index := 0;
        end case;
        
        address := i / 4;
        if address >= size or address >= br'high then
            exit;
        end if;
        br(address)(index+7 downto index) := oC(i);
    end loop;
    
    return br;
end function objcode_to_wtable;


function objcode_to_htable(oC : t_obj_code; 
                           size : integer) 
                           return t_hword_table is
variable br : t_hword_table(integer range 0 to size-1):=(others => X"0000");
variable i, address, index : integer;
begin
    
    -- Copy object code to start of BRAM...
    i := 0;
    for i in 0 to oC'length-1 loop
        case i mod 2 is
        when 1 =>       index := 8;
        when others =>  index := 0;
        end case;
        
        address := i / 2;
        if address >= size then
            exit;
        end if;
        br(address)(index+7 downto index) := oC(i);
    end loop;

    
    return br;
end function objcode_to_htable;

function objcode_to_btable(oC : t_obj_code; 
                           size : integer; 
                           slice : integer := -1) 
                           return t_byte_table is
variable br : t_byte_table(integer range 0 to size-1):=(others => X"00");
variable i, address, index : integer;
begin
    
    if slice < 0 then 
        -- Copy object code to start of table, leave the rest filled with zeros.
        for i in 0 to oC'length-1 loop
            if i >= size then
                exit;
            end if;
            br(i) := oC(i);
        end loop;
    else
        -- Remember, oC is big endian and slice 0 is the low byte.
        i := 0; -- TODO check bounds!
        while ((i*4)+(3-slice)) < (oC'length) loop
            if i >= size then
                exit;
            end if;
            br(i) := oC((3-slice) + (i*4));
            i := i + 1;
        end loop;
    end if;
    
    return br;
end function objcode_to_btable;

end package body;
